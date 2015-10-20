
require 'socket'

class FineGrainedClient
  @@immediate_execution = false

  class << self
    def cli
      @@cli ||= new
    end

    def flag_immediate_execution!
      @@immediate_execution = true
    end

    def enqueue_to(q, klass, *args)
      return klass.send(:perform, *args) if @@immediate_execution

      package = MultiJson.encode({
        :klass => klass.to_s,
        :args => args
      })

      self.cli.push(q, package)
    end
  end

  def initialize(options = {})
    options.reverse_merge!(
      :hostname => 'localhost',
      :port => FineGrained::PORT
      )

    @client = TCPSocket.new(options[:hostname], options[:port])
    @incoming_buffer = ""
  end

  def open
    if @client.nil?
      @client = TCPSocket.new(options[:hostname], options[:port])
    end
  end

  def close
    @client.close
    @client = nil
  end

  def encode(s)
    s.gsub("\\", "\\\\").gsub("\n", "\\n")
  end

  def decode(s)
    s.gsub("\\n", "\n").gsub("\\\\", "\\")
  end

  def del(k)
    @client.sendmsg "DEL #{k}\n"
    read_response
  end

  def set(k, v)
    @client.sendmsg "SET #{k} #{encode(v)}\n"
    read_response
  end

  BUFFER_SIZE = 1024
  def read(k)
    @client.sendmsg("READ #{k}\n")
    decode(read_response)
  end

  def push(a, v)
    @client.sendmsg("PUSH #{a} #{encode(v)}\n")
    read_response
  end

  #
  # Needs to block for a period of seconds.
  #
  def pop(a)
    @client.sendmsg("POP #{a}\n")
    decode(read_response)
  end

  #
  # Needs to block for a period of seconds.
  #
  def shift(a)
    @client.sendmsg("SHIFT #{a.to_s}\n")
    r = decode(read_response)

    # Should probably improve error-handline.
    if r.starts_with?("Error:")
      nil
    else
      r
    end
  end

  #
  # Read n elements from a list.
  #
  def lread(key, n = -1)
    i = 0
    l = []
    @client.sendmsg("LREAD #{key} #{n}")
    v = decode(read_response)
    while v != "OK"
      if v.starts_with?("Error:")
        return nil
      elsif v.starts_with?("Warning:")
        return l
      end

      l.push(v)
      v = decode(read_response)
    end

    l
  end

  def buffered_read
    if @incoming_buffer.length > 0
      r = @incoming_buffer
      @incoming_buffer = ""
    else
      result = @client.recvmsg(BUFFER_SIZE)
      r = result[0]
    end
    r
  end

  def read_response
    s = ""

    res = buffered_read
    res_split = res.split("\n", 2)
    s += res_split[0]
    while res_split.length == 1
      res = buffered_read
      res_split = res[0].split("\n", 2)
      s += res_split[0]
    end

    @incoming_buffer = res_split[1]
    s
  end


end
