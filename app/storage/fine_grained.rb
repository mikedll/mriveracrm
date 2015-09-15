
require 'eventmachine'

class FineGrained < EventMachine::Connection

  DB = "db/fineGrained.db"
  @@store = nil

  def post_init
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

  def unbind
    File.open(DB, "w") do |f|
      f.write @@store.to_yaml
    end
  end

  def receive_data(line)
    data = line.chomp

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
    if key_match.length < 2
      send_data "Error: Key not found."
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
    when "SET"
      @@store[key] = params
      send_data "OK\n"
    when "READ"
      r = @@store[key]
      if r.nil?
        send_data "Error: Key not found.\n"
        return
      end
      send_data r + "\n"
    when /quit/i
      close_connection
    end
  end

end

