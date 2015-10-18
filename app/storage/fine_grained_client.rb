
require 'socket'

class FineGrainedClient
  class << self
    def cli
      @@cli ||= new
    end

    def enqueue_to(q, klass, *args)
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

  def read_response
    s = @incoming_buffer

    res = @incoming_buffer.length != 0 ? @incoming_buffer : @client.recvmsg(BUFFER_SIZE)
    res_split = res[0].split("\n", 2)
    s += res_split[0]
    while res_split.length == 1
      res = @client.recvmsg(BUFFER_SIZE)
      res_split = res[0].split("\n", 2)
      s += res_split[0]
    end

    @incoming_buffer = res_split[1]
    s
  end


end
