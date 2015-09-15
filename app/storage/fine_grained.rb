
require 'eventmachine'

class FineGrained < EventMachine::Connection

  PORT = 7803
  AUTO_FLUSH_FREQUENCY = 10
  DB = "db/fineGrained.db"
  @@store = nil
  @@flushing_timer = nil

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
    when "SET"
      bounds = key_match.offset(0)
      params = key_and_params[bounds[1], key_and_params.length - bounds[1]]
    end

    case cmd
    when /quit/i
      close_connection
      return false
    when "SET"
      @@store[key] = params
      self.class.flush
      send_data "OK\n"
    when "READ"
      r = @@store[key]
      if r.nil?
        send_data "Error: Key not found.\n"
        return
      end
      send_data r + "\n"
    end

    true
  end

  def receive_data(data)
    data.split(/\r?\n/).each { |l| break if !process_request(l) }
  end

end

