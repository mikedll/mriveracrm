
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
  ZERO_BYTE_ASCII_8BIT = "\x00".force_encoding("ASCII-8BIT")

  INT_SIZE = 8
  PACK_INT = "Q".force_encoding("UTF-8")
  MAX_VALUE_SIZE = (2**64 - 1)
  PAGE_SIZE = 2**8
  MAXIMUM_PAGES = 1024
  MAXIMUM_SIZE = (2**30) / (2**8)
  PAGE_START_OFFSET_SIZE = INT_SIZE
  PAGE_COUNT_SIZE = INT_SIZE

  def initialize(path)
    @path = path

    @page_count = 0        # how many pages of data are written to disk, which may be less than or greater than used_pages' bytesize.

    @used_pages = "".force_encoding("ASCII-8BIT") # bit-index of markings of used and free pages.
    @page_start_offset = MAGIC_FILE_NUMBER.bytesize + PAGE_START_OFFSET_SIZE + PAGE_COUNT_SIZE + 0 # file offset in bytes where data starts, after bit_index ends

    @store = {}
    @store_pages = {}

    load_store_from_disk if File.exists?(path)

    # For use in journaling, for later. M. Rivera 9/17/15
    @journal_bounds = []
    @dead_region_bounds = []
    @next_journal_conflict_i = nil
  end

  def close
    @file.close
  end

  def filesize
    @file.size
  end

  #
  # deletes contents of entire file.
  #
  def hard_clean!
    open_db
    @file.seek 0
    @file.rewind
    @file.write MAGIC_FILE_NUMBER
    @used_pages = "".force_encoding("ASCII-8BIT")
    @page_start_offset = MAGIC_FILE_NUMBER.bytesize + PAGE_START_OFFSET_SIZE + PAGE_COUNT_SIZE + 0 # file offset in bytes where data starts, after bit_index ends
    @page_count = 0

    flush_page_start_offset
    flush_page_count
    flush_used_pages

    @file.truncate(@file.tell)
  end

  def flush_page_start_offset
    @file.seek(MAGIC_FILE_NUMBER.bytesize)
    @file.write([@page_start_offset].pack("#{PACK_INT}1"))
  end

  def flush_page_count
    @file.seek(MAGIC_FILE_NUMBER.bytesize + PAGE_START_OFFSET_SIZE)
    @file.write([@page_count].pack("#{PACK_INT}1"))
  end

  def flush_used_pages
    @file.seek(MAGIC_FILE_NUMBER.bytesize + PAGE_START_OFFSET_SIZE + PAGE_COUNT_SIZE)
    @file.write(@used_pages)
  end

  #
  # @pre @file not nil, and is open for writing.
  #
  def to_page(p)
    @file.seek(@page_start_offset + p * PAGE_SIZE)
  end

  def to_next_writable_page
    @file.seek(MAGIC_FILE_NUMBER.bytesize + PAGE_START_OFFSET_SIZE + PAGE_COUNT_SIZE + @page_start_offset + (@page_count * PAGE_SIZE))
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
    pack_directives = "#{PACK_INT}2A#{k.length}" + PACK_INT * a.length
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
    return nil if @file.eof?
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
  # Marks used_pages bit index to indicate
  # page p to size_p pages are used.
  #
  def mark_used(p, size_p)
    for i in p...(p + size_p)
      @used_pages[i / 8] = [@used_pages[i / 8].ord | (1 << (7 - (i % 8)))].pack("c")
    end
  end

  #
  # @todo do we need to do anything here?
  #
  def deallocate_page(p, size_p)
  end

  #
  # @pre new_pages >= 0
  #
  def allocate_page(new_pages)

    # is there existing page space?
    new_page_offset = nil
    contiguously_available = 0
    i = 0
    while i < @used_pages.bytesize && contiguously_available < new_pages
      if @used_pages[i / 8].ord & (1 << (7 - (i % 8))) == 0
        new_page_offset = i if new_page_offset == nil
        contiguously_available += 1
      else
        new_page_offset = nil
      end
      i += 1
    end

    if new_page_offset.nil?

      # We need to allocate more space on disk.

      first_free_page = @used_pages.bytesize
      first_free_page -= 1 while first_free_page > 0 && (1 << (7 - ((first_free_page - 1) % 8))) & @used_pages[(first_free_page - 1) / 8].ord == 0

      # # do we need to do this?
      # while (@used_pages.bytesize * 8) < @page_count
      #   to_next_writable_page
      #   @file.write("\x00" * PAGE_SIZE)
      #   @page_count += 1
      #   flush_page_count
      # end

      # pages needed beyond blank pages at the tail of used_pages
      # needed_pages = new_pages - ((@used_pages.bytesize * 8) - first_free_page)
      # raise "Programming Error: Expected needed pages to be non-zero. " if needed_pages == 0

      # grow the bit_index
      allocated_page_space = 0
      while allocated_page_space < new_pages

        #
        # there appear to be three states from which to allocate
        # more space in which bit_index can grow:
        #
        # (first_free_page() == 0)
        # (first_free_page() > 0 && first_free_page() < used_pages.bytesize)
        # (first_free_page() == used_pages.bytesize)
        #
        # these are handled below. note that size_p <= first_free_page.
        #

        size_p = 0 # size of space moved due to key-collision

        # if there is a collision, allocate more space
        # and write the key there.
        if @used_pages.bytesize > 0 && @used_pages[0].ord & (1 << 7) != 0
          size = 0
          to_page(0)
          desc, v = read_record
          to_page(first_free_page)
          if desc[0] == WRITE_TYPE_INDEXES[:array]
            size = ((24 + k.bytesize) + v.inject(0) { |acc, el| acc += 8 + el.bytesize }) # record_descriptor + value_s sizes
            @file.write record_descriptor(desc[0], desc[1], desc[2])
            desc[2].each { |el| @file.write value_s(el) }
          else
            v_serialized = desc[0] == WRITE_TYPE_INDEXES[:hash] ? MultiJson.encode(v) : v
            size = (((16 + k.bytesize) + 8 + v_serialized.bytesize) / PAGE_SIZE) # record_descriptor + serialized value_s size
            @file.write record_descriptor(desc[0], desc[1])
            @file.write value_s(v_serialized)
          end
          size_p = (size / PAGE_SIZE) + (size % PAGE_SIZE == 0 ? 0 : 1)

          # update page size on disk
          @page_count += size_p
          flush_page_count

          # update the key's location in store_pages
          @store_pages[desc[1]] = [first_free_page, size_p]

          to_page(0)
          @file.write (ZERO_BYTE_ASCII_8BIT * size_p * PAGE_SIZE)
        end

        # adjust used_pages to indicate the migration of the key,
        # and the incoming used_pages appendage.

        if size_p >= PAGE_SIZE
          raise "Error: Programming error. FineGrained cannot handle writes that would displace keys greater than or equal to #{PAGE_SIZE * size_p} bytes in size."
          # @todo handle size_p > PAGE_SIZE
          # @used_pages += ZERO_BYTE_ASCII_8BIT * (1 + size_p * PAGE_SIZE)
        end

        used_page_appendage = ZERO_BYTE_ASCII_8BIT * (PAGE_SIZE / ZERO_BYTE_ASCII_8BIT.bytesize)
        @used_pages += used_page_appendage

        # the following two variables do not account for bit-shifting. tail_size
        # would be one larger and used_of_next_bit_index_page would be one smaller
        # if they did.
        tail_size = @used_pages.bytesize - first_free_page # free space at end of used_pages
        used_of_next_bit_index_page = size_p - tail_size   # used space from next bit-index page allocation

        #
        # @todo there is a weakness in this algorithm, which is that if the key to be migrated
        # is large, it will keep on taking a long time to move forward, resulting almost
        # as many page allocations for bit-indexes as there are pages in the key. however,
        # in such a situation, a space will be found in the middle of the file, or should be.
        # on every allocation, the bit-index should be searched from the beginning to identify
        # growing gaps in the allocated space.
        #

        #
        # @todo consider rewriting this as four while-loops
        #
        # head is the portion of used_pages that held a key that was migrated out of the way
        # middle is the portion after head but excluding tail
        # tail is the portion of used_pages at its end that was available for holding the migrated key
        # head of next bit-index is the space in the next bit-index page allocation that will be marked as used due to the key migration
        #
        for i in (1...(@used_pages.bytesize + used_of_next_bit_index_page))
          j = i - 1
          j_bit_as_used = (1 << (7 - (j % 8)))  # | this
          j_bit_as_free = ~(1 << (7 - (j % 8))) # & this
          if i < size_p
            # mark head as free due to migrated key
            @used_pages[j / 8] = [@used_pages[j / 8].ord & j_bit_as_free].pack("c")
          elsif i < first_free_page
            # bit shift middle of used_pages
            cur_i = @used_pages[i / 8].ord
            cur_j = @used_pages[j / 8].ord
            @used_pages[j / 8] = (cur_i & (1 << (7 - (i % 8))) == 0 ? [cur_j & j_bit_as_free].pack("c") : [cur_j | j_bit_as_used].pack("c"))
          else
            # mark taken tail of used_pages, and head of next bit-index page allocation
            @used_pages[j / 8] = [@used_pages[j / 8].ord | j_bit_as_used].pack("c")
          end
        end

        #
        # @todo should we check to see if we're at eof when writing used_pages extension?
        #
        flush_used_pages

        @page_start_offset += used_page_appendage.bytesize
        flush_page_start_offset

        new_page_offset = @page_count if new_page_offset.nil?

        #
        # @todo we are losing a page to the allocated used_pages appendage.
        # take this into consideration when computing the below.
        #
        allocated_page_space += (used_page_appendage.bytesize - used_of_next_bit_index_page)
      end
    end

    return new_page_offset
  end

  def write_key(k, v = nil)
    v = @@store[k] if v.nil?
    p_original, size_p = (@store_pages[k] || [nil, 0])
    p = p_original
    new_size = nil

    ti = if v.is_a?(Array)
           :array
         elsif v.is_a?(Hash)
           :hash
         else
           :string
         end
    t = WRITE_TYPE_INDEXES[ti]

    #
    # todo: recognize when size mismatch is okay due to this key being
    # the last key in the database on disk.
    #

    if ti == :array
      size = ((24 + k.bytesize) + v.inject(0) { |acc, el| acc += 8 + el.bytesize })
      new_size_p = (size / PAGE_SIZE) + (size % PAGE_SIZE == 0 ? 0 : 1) # record_descriptor + value_s sizes
      p = allocate_page(new_size_p) if new_size_p > size_p
      to_page(p)
      @file.write record_descriptor(t, k, v.length)
      v.each do |el|
        @file.write value_s(el)
      end
      mark_used(p, new_size_p)
    elsif ti == :hash
      record_serialized = MultiJson.encode(v)
      size = ((16 + k.bytesize) + 8 + record_serialized.bytesize)
      new_size_p = (size / PAGE_SIZE) + (size % PAGE_SIZE == 0 ? 0 : 1) # record_descriptor + serialized value_s size
      p = allocate_page(new_size_p) if new_size_p > size_p
      to_page(p)
      @file.write record_descriptor(t, k)
      @file.write value_s(record_serialized)
      mark_used(p, new_size_p)
    else
      size = ((16 + k.bytesize) + 8 + v.bytesize)
      new_size_p = (size / PAGE_SIZE) + (size % PAGE_SIZE == 0 ? 0 : 1) # record_descriptor + value_s sizes
      p = allocate_page(new_size_p) if new_size_p > size_p
      to_page(p)
      @file.write record_descriptor(t, k)
      @file.write value_s(v)
      mark_used(p, new_size_p)
    end

    if p != p_original
      @store_pages[k] = [p, new_size_p]
      deallocate_page(p_original, size_p)
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
      if File.exists? @path
        @file = File.open(@path, "r+b")
      else
        @file = File.new(@path, "w+b")
      end
    elsif @file.closed?
      @file.reopen(@path, "r+b")
    end
  end

  #
  # Writes with paging and a page index at the start
  # of the file.
  #
  # Does not compress the right right now.
  #
  def flush(store)
    open_db

    store.each do |k, v|
      write_key(store, k)
    end

    @file.close
  end

  #
  #
  # @todo Postponed until later. M. Rivera 9/17/2015
  #
  # a journal region is a write command that is different from the one-time
  # storage of the key on disk.
  #
  # a dead region is a region in between journal regions that may be used
  # for key storage.
  #
  # go over a journal region
  # update store
  # mark journal region as in ram
  # write store, skipping journal regions, and claiming dead regions if you can
  # mark journal region as on disk, pull the lower bound of the region toward the upper bound as you go
  # the journal region is now free. on the next write attempt, you can use it.
  #
  def flush_with_journaling(store)
    open_db
    @file.rewind

    @file.write MAGIC_FILE_NUMBER

    # write journal bounds, at most ten of them

    # write dead bounds, at most journal bounds * 3 of them

    # write all keys

    @journal_bounds.push([@file.tell, @file.tell + 1])

    @file.truncate(@file.size)
    @file.close
  end

  def flush_old(store)
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

    to_page(0)
    while !@file.eof? && record = read_record
      @store[record.first[1]] = record.last if record.last
    end

    # update page_count if there are zeroes at end of file, and
    # (@used_pages.bytesize * 8) < @page_count. should be an increment.

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

