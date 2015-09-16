
require 'eventmachine'

class FineGrainedFile

  WRITE_TYPE_INDEXES = {
    :array => 1,
    :string => 2,
    :hash => 2
  }
  MAGIC_FILE_NUMBER = "\x1F8pZ".force_encoding("UTF-8")

  def initialize(path)
    @path = path
  end

  def record_descriptor(t, k, *a)
    pack_directives = "Q2#{k.length}"+ "Q" * a.length
    ([t, k] + a)pack(pack_directives)
  end

  def value_s(v)
    record = [v.length, v]
    record_s = record.pack("QA#{record.first}")
  end


  def open_db
    @file = File.open(DB2, "w+") if @file.nil?
  end

  def flush
    open_db
    @file.rewind

    @file.write MAGIC_FILE_NUMBER
    @@store.each do |k, v|
      if v.is_a?(Array)
        @file.write record_descriptor(WRITE_TYPE_INDEXES[:array], k.length, k, v.length)
        v.each do |el|
          record = [el.length, el]
          record_s = record.pack("QA#{record.first}")
          @file.write record_s
        end
      elsif v.is_a?(Hash)
        @file.write record_descriptor(WRITE_TYPE_INDEXES[:hash], k.length, k)
        record_serialized = MultiJson.encode(v)
        @file.write value_s(record_serialized)
      else
        @file.write record_descriptor(WRITE_TYPE_INDEXES[:string], k.length, k)
        @file.write value_s(v)
      end
    end

    # @file.close
  end

  def load_store2
    open_db2

    size = packed.unpack("Q")
    MultiJson.decode(s)
  end
end

class FineGrained < EventMachine::Connection

  PORT = 7803
  AUTO_FLUSH_FREQUENCY = 10
  DB = "db/fineGrained.db"
  DB2 = "db/fineGrained.db2"
  @@store = nil
  @@flushing_timer = nil
  @@db2 = FineGrainedFile.new(DB2)

  def self.flush
    ensure_store_defined
    File.open(DB, "w") do |f|
      f.write @@store.to_yaml
    end
  end

  def self.ensure_store_defined
    if @@store.nil?
      if File.exists?(DB)
        f = File.open(DB, "r")
        if f.size > 0
          @@store = YAML.load(f.read)
        else
          @@store = {}
        end
        f.close
      else
        @@store = {}
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
    self.class.flush
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

    dirty = false
    case cmd
    when /quit/i
      close_connection
      return false
    when "SET"
      @@store[key] = params
      dirty = true
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
        dirty = true
        send_data "OK\n"
      when 'POP'
        if @@store[key].empty?
          send_data "Error: Nothing in array."
          return false
        end
        r = @@store[key].pop
        dirty = true
        send_data "#{r}\n"
      when 'SHIFT'
        if @@store[key].empty?
          send_data "Error: Nothing in array."
          return false
        end
        r = @@store[key].shift
        dirty = true
        send_data "#{r}\n"
      end
    end

    self.class.flush if dirty

    true
  end

  def receive_data(data)
    data.split(/\r?\n/).each { |l| break if !process_request(l) }
  end

end

