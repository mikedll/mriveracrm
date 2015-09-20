
require 'eventmachine'

#
# Trouble-shooting:
#   Attempt to unlock a mutex which is locked by another thread, Connection reset by peer - sendmsg(2) (Errno::ECONNRESET)
#
# This crash occured when a MultiJson constant was failing to be found during lookup.
#
#
class FineGrainedFile

  class MaximumValueExceeded < Exception
  end

  WRITE_TYPE_INDEXES = {
    :array => 1,
    :string => 2,
    :hash => 3
  }
  MAGIC_FILE_NUMBER = "\x1F8pZ".force_encoding("UTF-8")

  INT_SIZE = 8
  PACK_INT = "Q"
  MAX_VALUE_SIZE = (2**64 - 1)
  PAGE_SIZE = 2**8
  MAXIMUM_PAGES = 1024
  MAXIMUM_SIZE = (2**30) / (2**8)

  def initialize(path)
    @path = path

    @page_count = 0
    @used_pages = ""
    @store = {}
    @store_pages = {}
    @page_start_offset = MAGIC_FILE_NUMBER.bytesize + @used_pages.bytesize

    load_store_from_disk if File.exists?(path)

    @page_start_offset = MAGIC_FILE_NUMBER.bytesize + @used_pages.bytesize

    # For use in journaling, for later. M. Rivera 9/17/15
    @journal_bounds = []
    @dead_region_bounds = []
    @next_journal_conflict_i = nil
  end

  #
  # @pre @file not nil, and is open for writing.
  #
  def to_page
    @file.seek(@page_start_offset + p * PAGE_SIZE)
  end

  def [](key)
    @@store[key]
  end

  #
  # @todo: funnel all operations on keys through
  # a system whereby values are written to disk
  # first and then inserted into the @@store variable.
  #
  def []=(key, value)
    @@store[key] = value
    write_key(key, value)
  end

  #
  # type descriptor, key, *additional 64-bit unsigned integers
  #
  #
  def record_descriptor(t, k, *a)
    pack_directives = "#{PACK_INT}2A#{k.length}" + PACK_INT * a.bytesize
    ([t, k.bytesize, k] + a).pack(pack_directives)
  end

  #
  # @todo: rescue from parse errors
  # @todo: update bit mask. if you find a duplicate
  # key, regard the prior position as free and update
  # the bitmask.
  # @todo if you reach eof before reading all pages
  # of keys, update the page_count in ram and on disk
  # to be shorter than we expected. used_pages
  # size should equal page_count.
  # @todo if you have a key collision, it means
  #  you should free the old key in used_pages.
  #
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

  #
  # Returns [record_descriptor, record_value]
  # or nil if no record is found.
  #
  def read_record
    d = read_descriptor
    v = nil
    return nil if d.nil?

    case d[0]
    when WRITE_TYPE_INDEXES[:array]
      a = []
      d[2].times { |i| a.push(read_value_s) }
      v = a
    when WRITE_TYPE_INDEXES[:hash]
      h = MultiJson.decode(read_value_s)
      v = h
    when WRITE_TYPE_INDEXES[:string]
      v = read_value_s
    end
    [d, v]
  end

  #
  # @todo: rescue from parse errors
  #
  def read_value_s
    lu = @file.read INT_SIZE
    l = lu.unpack(PACK_INT).first
    s = @file.read l
  end

  def value_s(v)
    raise MaximumValueExceeded if v.bytesize > MAX_VALUE_SIZE
    record = [v.bytesize, v]
    record_s = record.pack("#{PACK_INT}A#{record.first}")
  end

  #
  # @pre new_size >= 0
  #
  def allocate_page(new_size)

    # is there existing page space?
    i = 0
    byte_offset = 0
    new_page_offset = nil
    contiguously_available = 0
    while (contiguously_available * PAGE_SIZE < new_size) && i < (@used_pages.bytesize * 8)
      byte_offset = (i / 8) if bit_in_byte == 0
      if available ((@used_pages[byte_offset].ord & (1 << (7 - (i % 8)))) == 0)
        new_page_offset = i if new_page_offset == nil
        contiguously_available += 1
      else
        new_page_offset = nil
      end
    end

    if new_page_offset.nil?
      new_pages = new_size / PAGE_SIZE + (new_size % PAGE_SIZE != 0 ? 1 : 0)

      first_free_page = (@used_pages.bytesize * 8)
      first_free_page -= 1 while first_free_page > 0 && (1 << (7 - ((first_free_page - 1) % 8))) & @used_pages[(first_free_page - 1) / 8].ord == 0

      # make space for used_pages as needed, moving more keys
      needed_pages = new_pages - (page_start - first_free_page)
      transfered_pages = 0
      i = 0
      while needed_pages > 0

        if @used_pages[i / 8].ord & (1 << (7 - (i % 8)))

          @file.seek @page_start + (i * PAGE_SIZE)
          desc, v = read_record
          @file.seek MAGIC_FILE_NUMBER.bytesize + 64 + 64 + @used_pages.bytesize
          @file.write record_descriptor()
        end

        #
        # - allocate more space and write the key there
        # - update page size on disk
        # - update the key's location in store_pages
        # - mark that that area in used_pages is now free.
        # - increment transfered_pages
        #
        i += 1
      end
      #
      # - calculate pages_needed_for_byte_congruence, the quantity to add to transfered_pages to make
      #   used_pages' represented bits be a multiple of eight.
      #
      # - nullify the pages on disk created for byte-congruence, if any exist
      #
      # - using transfered_pages, copy from used_pages into a new string,
      #   append zeros to it with pages_needed_for_byte_congruence so that it is byte-congruent
      #   and defined. call this used_pages_tail. the complement of used_pages_tail in used_pages
      #   is used_pages_head. used_pages_head is out of sync with the disk, and is more
      #   recent in RAM.
      #
      # - increase page_count by the new page increase quantity quantity. write this value to disk.
      #
      # - append used_pages_tail to used_pages, and write used_pages_tail to disk.
      #   some bits near the beginning of used_pages on disk
      #   are redundant with the end of the file and end of used_pages on disk. let this be
      #   redundant_used_pages.
      #
      # - update page_start to account for increase in used_pages size. write this value to disk.
      #
      # - write head of used_pages to disk.
      #
      #
      #
      #
      # now we begin to allocate space for the request that started this.
      #
      # - allocate pages for new_size. mark them as used in used_pages.
      #   write used_pages to disk.
      #
      # - return these pages for use from this method.
      #

      @used_pages += "\x00" * new_pages
      # move keys written where used_pages bit mask
      # needs to be written with additional space.

      if dead_region > 0
        @file.seek(last_page_start)
        @file.write ("\x00" * last_page_block_size)
      end
    end

    return new_page_offset
  end

  def write_key(k, v = nil)
    v = @@store[k] if v.nil?
    p_original, size = @store_pages[key]
    p = p_original
    new_size = nil

    if v.is_a?(Array)
      new_size = (24 + k.bytesize) + v.inject(0) { |acc, el| acc += 8 + el.bytesize } # record_descriptor + value_s sizes
      p = allocate_page(new_size) if new_size > size
      to_page(p)
      @file.write record_descriptor(WRITE_TYPE_INDEXES[:array], k, v.length)
      v.each do |el|
        @file.write value_s(el)
      end
    elsif v.is_a?(Hash)
      record_serialized = MultiJson.encode(v)
      new_size = (16 + k.bytesize) + 8 + record_serialized.bytesize # record_descriptor + value_s sizes
      p = allocate_page(new_size) if new_size > size
      to_page(p)
      @file.write record_descriptor(WRITE_TYPE_INDEXES[:hash], k)
      @file.write value_s(record_serialized)
    else
      new_size = (16 + k.bytesize) + 8 + v.bytesize # record_descriptor + value_s sizes
      p = allocate_page(new_size) if new_size > size
      to_page(p)
      @file.write record_descriptor(WRITE_TYPE_INDEXES[:string], k)
      @file.write value_s(v)
    end

    if p != p_original
      @store_pages = [p, new_size]
      deallocate_page(p_original, size)
    end
    # get page for this key
    #
    # see if page is still large enough. if not, check out
    # a page at the end of the file, write there,
    # update its page ref here, then release this page.
    #
    #
    #
  end

  #
  # @todo Postponed this until later. M. Rivera 9/17/2015
  #
  # Writes to current region if it will not collide
  # with a journal region.
  #
  # Else, skips the journal region. Writes to the next
  # available region of file.
  #
  def write_with_journaling(s)
    if @next_journal_conflict_i.nil?
      i = @file.tell
      @next_journal_conflict_i = @journal_bounds.find_index { |b| b.last <= i || b.first >= i }
    end

    i = @file.tell
    while (i < @journal_bounds[@next_journal_conflict_i].last) && (i >= @journal_bounds[@next_journal_conflict_i].first || (i + s.bytesize) >= @journal_bounds[@next_journal_conflict_i].first)

      # capture dead region if necessary.

      @file.seek(@journal_bounds[@next_journal_conflict_i].last)
      @next_journal_conflict_i = (@next_journal_conflict_i + 1) % @journal_bounds.length
      i = @file.tell
    end

    @file.write s
  end

  JOURNALING_LOWER_TOLERANCE = 0.05
  JOURNALING_UPPER_TOLERANCE = 0.25
  #
  # If journal region is more than 25% of file,
  # flush journal regions until we get to 5% of file.
  #
  # If journal region count is greater than 10, flush
  # journal regions until we get to 2.
  #
  def write_due
    journal_use = 0
    @file.size != 0 && (journal_use.to_f / @file.size) >= JOURNALING_UPPER_TOLERANCE
  end

  def open_db
    if @file.nil?
      @file = File.open(@path, "r+")
    elsif @file.closed?
      @file.reopen(@path, "r+")
    end
  end

  def open_db2
    if @file.nil?
      @file = File.open(@path + "2", "r+")
    elsif @file.closed?
      @file.reopen(@path + "2", "r+")
    end
  end

  #
  # Writes with paging and a page index at the start
  # of the file.
  #
  # Does not compress the right right now.
  #
  def flush(store)
    open_db2

    store.each do |k, v|
      write_key(store, k)
    end

    @file.close
  end

  #
  #
  # @todo Postponed until later. M. Rivera 9/17/2015
  #
  # go over a journal region
  # update store
  # mark journal region as in ram
  # write store, skipping journal regions, and claiming dead regions if you can
  # mark journal region as on disk, pull the lower bound of the region toward the upper bound as you go
  # the journal region is now free. on the next write attempt, you can use it.
  #
  def flush_with_journaling(store)
    open_db2
    @file.rewind

    @file.write MAGIC_FILE_NUMBER

    # write journal bounds, at most ten of them

    # write dead bounds, at most journal bounds * 3 of them

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

    @journal_bounds.push([@file.tell, @file.tell + 1])

    @file.truncate(@file.size)
    @file.close
  end

  def flush_old(store)
    open_db2
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

    @journal_bounds.push([@file.tell, @file.tell + 1])

    @file.truncate(@file.size)
    @file.close
  end

  #
  # skip journal and dead regions as you read.
  #
  def load_store_from_disk
    open_db
    @file.rewind

    magic_descriptor = @file.read 4
    if magic_descriptor != MAGIC_FILE_NUMBER
      @store.clear
      puts "Error: Not a valid fine grained file: #{@path}"
      return
    end

    @store[record.first[1]] = record.last while record = read_record
    @file.close
  end
end

class BlockingRead
  include EM::Deferrable

  QUEUE_WAIT_TIMEOUT = 5

  def initialize(connection)
    @connection = connection
  end

  def wait!(key)
    @connection.class.enter_read_queue!(key, @connection.signature, self)

    callback do |k, r|
      @connection.send_data "#{r}\n"
    end

    errback do |k, r|
      @connection.class.leave_read_queue!(k, @connection.signature, self)
      @connection.send_data "Error: Nothing in array.\n"
    end

    timeout(QUEUE_WAIT_TIMEOUT, key, nil)
  end

end

class FineGrained < EventMachine::Connection

  PORT = 7803
  AUTO_FLUSH_FREQUENCY = 3
  DB = "db/fineGrained.db"
  @@store = FineGrainedFile.new(DB)
  @@flushing_timer = nil
  @@dirty = false
  @@read_queues = {}

  def self.enter_read_queue!(key, signature, blocking_read)
    @@read_queues[key] ||= []
    @@read_queues[key].push([signature, blocking_read])
  end

  def self.leave_read_queue!(key, signature, blocking_read)
    @@read_queues[key].delete([signature, blocking_read])
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
        if @@dirty == true
          @@dirty = false
          @@store.flush
        end
      end
    end
  end

  def post_init
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
    else
      begin
        case cmd
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
            if @@read_queues[key] && !@@read_queues[key].empty?
              sig, blocking_read = @@read_queues[key].shift
              blocking_read.set_deferred_status(:succeeded, key, params)
            else
              @@store[key].push(params)
              @@store.write_key(key)
              @@dirty = true
            end
            send_data "OK\n"
          when 'POP'
            if @@store[key].empty?
              send_data "Error: Nothing in array.\n"
              return false
            end
            r = @@store[key].pop
            @@store.write_key(key)
            @@dirty = true
            send_data "#{r}\n"
          when 'SHIFT'
            if @@store[key].empty?
              BlockingRead.new(self).wait!(key)
              return false
            end
            r = @@store[key].shift
            @@store.write_key(key)
            @@dirty = true
            send_data "#{r}\n"
          end
        end
      rescue FineGrainedFile::MaximumValueExceeded => e
        send_data "Error: Maximum size for a given value exceeded. Try setting a smaller value."
      end
    end

    true
  end

  def receive_data(data)
    @msgs ||= []
    @msgs += data.split(/\r?\n/)
    while m = @msgs.shift
      break if !process_request(m)
    end
  end

end

