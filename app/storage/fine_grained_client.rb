
require 'socket'

class FineGrainedClient
  def initialize(options = {})
    options.reverse_merge!(
      :hostname => 'localhost',
      :port => FineGrained::PORT
      )

    @client = TCPSocket.new(options[:hostname], options[:port])
    @incoming_buffer = ""
  end

  def encode(s)
    s.gsub("\n", "\\n")
  end

  def decode(s)
    s.gsub("\\n", "\n")
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
