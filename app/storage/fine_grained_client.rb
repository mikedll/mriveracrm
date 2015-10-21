
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

  def lclear(key)
    @client.sendmsg("LCLEAR #{key}")
    decode(read_response)
  end

  #
  # Retrieves the size of an array.
  #
  def llength(key)
    @client.sendmsg("LLENGTH #{key}")
    read_response.to_i
  end

  def read_sequence
    i = 0
    l = []
    v = decode(read_response)
    while v != "" && v != "OK"
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

  #
  # Read n elements from a list.
  #
  # @todo simplify this command to work without
  # sending OK.
  #
  def lread(key, start = 0, n = -1)
    @client.sendmsg("LREAD #{key} #{start} #{n}")
    read_sequence
  end

  #
  # Increment counter.
  #
  def incr(key)
    @client.sendmsg("INCR #{key}")
    read_response.to_i
  end

  #
  # Decrement counter.
  #
  def decr(key)
    @client.sendmsg("DECR #{key}")
    read_response.to_i
  end

  #
  # Read counter.
  #
  def cread(key)
    @client.sendmsg("CREAD #{key}")
    read_response.to_i
  end

  #
  # Add to set.
  #
  def sadd(key, el)
    @client.sendmsg("SADD #{key} #{el}")
    read_response
  end

  #
  # Remove from set.
  #
  def srem(key, el)
    @client.sendmsg("SREM #{key} #{el}")
    read_response
  end

  #
  # Ask is an element a member of a set.
  #
  def smember(key, el)
    @client.sendmsg("SMEMBER #{key} #{el}")
    read_response == "true"
  end

  #
  # Read elements from a set. Order of retrieval is not significant,
  # so you may want to page through results for this to be
  # meaningful.
  #
  def sread(key, offset = 0, n = -1)
    @client.sendmsg("SREAD #{key} #{offset} #{n}")
    read_sequence
  end

  #
  # Retrieves the number of elements in a set.
  #
  def slength(key)
    @client.sendmsg("SLENGTH #{key}")
    read_response.to_i
  end

  #
  # Reset counter.
  #
  def reset(key)
    @client.sendmsg("RESET #{key}")
    read_response.to_i
  end

  def buffered_read
    if @incoming_buffer.length > 0
      r = @incoming_buffer
      @incoming_buffer = ""
    else
      result = @client.recvmsg(BUFFER_SIZE)
      r = result[0]
    end

    if false
      puts "*************** #{__FILE__} #{__LINE__} *************"
      puts "read #{r.class} '#{r}'"
    end

    r.split("\n", 2)
  end

  #
  # @todo handle broken pipe, of which res_split.length == 0 is a
  # symptom.
  #
  def read_response
    s = ""

    res_split = buffered_read
    while res_split.length == 1
      s += res_split[0]
      res_split = buffered_read
    end

    if res_split.length == 0
      @incoming_buffer = ""
    else
      s += res_split[0]
      @incoming_buffer = res_split[1]
    end

    s
  end


end
