
require 'eventmachine'

#
#
# Trouble-shooting:
#   Attempt to unlock a mutex which is locked by another thread, Connection reset by peer - sendmsg(2) (Errno::ECONNRESET)
#
# This crash occured when a MultiJson constant was failing to be found during lookup.
#
#
class FineGrainedFile

  WRITE_TYPE_INDEXES = {
    :array => 1,
    :string => 2,
    :hash => 3
  }
  MAGIC_FILE_NUMBER = "\x1F8pZ".force_encoding("UTF-8")

  INT_SIZE = 8
  PACK_INT = "Q"

  def initialize(path)
    @path = path
  end

  #
  # type descriptor, key, *additional 64-bit unsigned integers
  #
  #
  def record_descriptor(t, k, *a)
    pack_directives = "#{PACK_INT}2A#{k.length}" + PACK_INT * a.length
    ([t, k.length, k] + a).pack(pack_directives)
  end

  def read_descriptor
    return nil if @file.eof?

    tu = @file.read INT_SIZE
    t = tu.unpack(PACK_INT).first
    lu = @file.read INT_SIZE
    l = lu.unpack(PACK_INT).first
    k = @file.read l
    if t != WRITE_TYPE_INDEXES[:array]
      [t, k]
    else
      asu = @file.read INT_SIZE
      as = asu.unpack(PACK_INT).first
      [t, k, as]
    end
  end

  def read_value_s
    lu = @file.read INT_SIZE
    l = lu.unpack(PACK_INT).first
    s = @file.read l
  end

  def value_s(v)
    record = [v.length, v]
    record_s = record.pack("#{PACK_INT}A#{record.first}")
  end

  def open_db
    if @file.nil?
      @file = File.open(@path, "a+")
    elsif @file.closed?
      @file.reopen(@path, "a+")
    end
  end

  def flush(store)
    open_db
    @file.rewind

    @file.write MAGIC_FILE_NUMBER
    store.each do |k, v|
      if v.is_a?(Array)
        @file.write record_descriptor(WRITE_TYPE_INDEXES[:array], k, v.length)
        v.each do |el|
          @file.write value_s(el)
        end
      elsif v.is_a?(Hash)
        @file.write record_descriptor(WRITE_TYPE_INDEXES[:hash], k)
        record_serialized = MultiJson.encode(v)
        @file.write value_s(record_serialized)
      else
        @file.write record_descriptor(WRITE_TYPE_INDEXES[:string], k)
        @file.write value_s(v)
      end
    end

    @file.truncate(@file.tell)
    @file.close
  end

  def load_store(store)
    open_db
    @file.rewind

    magic_descriptor = @file.read 4
    if magic_descriptor != MAGIC_FILE_NUMBER
      store.clear
      puts "Error: Not a valid fine grained file: #{@path}"
      return
    end

    while d = read_descriptor
      case d[0]
      when WRITE_TYPE_INDEXES[:array]
        a = []
        d[2].times { |i| a.push(read_value_s) }
        store[d[1]] = a
      when WRITE_TYPE_INDEXES[:hash]
        h = MultiJson.decode(read_value_s)
        store[d[1]] = h
      when WRITE_TYPE_INDEXES[:string]
        store[d[1]] = read_value_s
      end
    end

    @file.close
  end
end

class FineGrained < EventMachine::Connection

  PORT = 7803
  AUTO_FLUSH_FREQUENCY = 3
  DB = "db/fineGrained.db"
  @@store = nil
  @@flushing_timer = nil
  @@db = FineGrainedFile.new(DB)
  @@dirty = false

  def self.flush
    ensure_store_defined
    @@db.flush(@@store)
  end

  def self.ensure_store_defined
    if @@store.nil?
      if File.exists?(DB)
        @@store = {}
        @@db.load_store(@@store)
      end
    end
  end

  #
  # It's not clear why we have this
  # if we're going to flush on every write,
  # as shown in receive_data. This could
  # be used to stagger journaling vs writing
  # of the compressed form of our data.
  #
  def self.start_automatically_flushing
    if @@flushing_timer.nil?
      @@flushing_timer = EventMachine::PeriodicTimer.new(AUTO_FLUSH_FREQUENCY) do
        flush
      end
    end
  end

  def post_init
    self.class.ensure_store_defined
    self.class.start_automatically_flushing
  end

  def unbind
  end

  def process_request(request)
    data = request.chomp

    matches = /\A(\w+)\s+/.match(data)

    if matches.nil? || matches.length < 2
      send_data "ERROR: Command not recognized.\n"
      return
    end

    cmd = matches[1].to_s

    bounds = matches.offset(0)
    key_and_params = data[bounds[1], data.length - bounds[1]]

    key = nil
    key_match = /\A(\w+)\s*/.match(key_and_params)
    if key_match.nil? || key_match.length < 2
      send_data "Error: Key not found.\n"
      return
    end

    key = key_match[1].to_s
    params = nil
    case cmd
    when "SET", "PUSH"
      bounds = key_match.offset(0)
      params = key_and_params[bounds[1], key_and_params.length - bounds[1]]
    end

    case cmd
    when /quit/i
      close_connection
      return false
    when "SET"
      @@store[key] = params
      @@dirty = true
      send_data "OK\n"
    when "READ"
      r = @@store[key]
      if r.nil?
        send_data "Error: Key not found.\n"
        return
      end
      send_data r + "\n"
    when 'PUSH', 'POP', 'SHIFT'
      if @@store[key].nil?
        @@store[key] = []
      elsif !@@store[key].is_a?(Array)
        send_data "Error: Key is not an array.\n"
        return false
      end

      case cmd
      when 'PUSH'
        @@store[key].push(params)
        @@dirty = true
        send_data "OK\n"
      when 'POP'
        if @@store[key].empty?
          send_data "Error: Nothing in array."
          return false
        end
        r = @@store[key].pop
        @@dirty = true
        send_data "#{r}\n"
      when 'SHIFT'
        if @@store[key].empty?
          send_data "Error: Nothing in array."
          return false
        end
        r = @@store[key].shift
        @@dirty = true
        send_data "#{r}\n"
      end
    end

    true
  end

  def receive_data(data)
    data.split(/\r?\n/).each { |l| break if !process_request(l) }
  end

end

