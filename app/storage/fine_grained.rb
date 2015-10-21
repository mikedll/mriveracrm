
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

  class ParseError < Exception
  end

  class KeyNotFoundError < Exception
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
  PAGE_SIZE = 2**8 # bytes
  MAXIMUM_PAGES = 1024
  MAXIMUM_SIZE = (2**30) / (2**8)
  PAGE_START_OFFSET_SIZE = INT_SIZE
  PAGE_COUNT_SIZE = INT_SIZE

  PREAMBLE_SIZE = MAGIC_FILE_NUMBER.bytesize + PAGE_START_OFFSET_SIZE + PAGE_COUNT_SIZE

  def initialize(path)
    @path = path

    if File.exists?(path)
      load_store_from_disk
    else
      open_db
      write_fresh_database
    end

    # For use in journaling, for later. M. Rivera 9/17/15
    @journal_bounds = []
    @dead_region_bounds = []
    @next_journal_conflict_i = nil
  end

  def close
    @file.close if !@file.nil? && !@file.closed?
  end

  def filesize
    @file.nil? ? -1 : @file.size
  end

  def write_fresh_database
    @store = {}
    @store_pages = {}

    @used_pages = "".force_encoding("ASCII-8BIT") # bit-index of markings of used and free pages.
    @page_count = 0        # how many pages are written to disk, including nullified pages. unless there has been a crash, this should be less than or equal to used_pages.bytesize * 8.
    @page_start_offset = 0 # file offset in bytes where data starts, after bit_index ends; unless there has been a crash, it is equal to used_pages.bytesize

    @file.rewind
    @file.write MAGIC_FILE_NUMBER
    flush_page_start_offset
    flush_page_count
    flush_used_pages
  end

  #
  # deletes contents of entire file.
  #
  def hard_clean!
    open_db
    @file.truncate(PREAMBLE_SIZE)
    write_fresh_database
  end

  def [](key)
    @store[key]
  end

  #
  # @todo: funnel all operations on keys through
  # a system whereby values are written to disk
  # first and then inserted into the @@store variable.
  #
  def []=(key, value)
    @store[key] = value
    write_key(key, value)
  end

  def delete(key)
    raise KeyNotFoundError.new("Key not found: #{key}") if @store[key].nil?

    # if @interesting_event
    #   if !@first_early_exit_from_delete
    #     puts "*************** #{__FILE__} #{__LINE__} *************"
    #     puts "returning early from delete due to interesting event. key was #{key} which is at page #{@store_pages[key]}."
    #   end
    #   @first_early_exit_from_delete = true
    #   return
    # end

    erase_key(key)
    @store_pages.delete(key)
    @store.delete(key)
  end

  def key_info(key)
    "#{key} is at page #{@store_pages[key]} which, in used_pages, is at #{page_position_in_used_pages(@store_pages[key][0])}"
  end

  #
  # returns hexadecimal representation of disk within
  # the given min and max position.
  #
  def disk_at(minpos, maxpos)
    @file.seek(minpos)
    s = ""
    for i in 0..(maxpos - minpos)
      b = @file.read 1
      bs = b[0].ord.to_s(16)
      s += (bs.length == 1 ? "0" + bs : bs)
    end
    s
  end

  #
  # method for debugging.
  #
  def page_position_in_used_pages(p)
    pos = PREAMBLE_SIZE + (p / 8)
    "#{pos} (0x#{pos.to_s(16)}) in bit #{p % 8} of byte #{p / 8} which is equal to #{used_pages_page(p / 8)}"
  end

  def used_pages_page(i)
    "0x#{@used_pages[i].ord.to_s(16)}"
  end

  #
  # Public means of clients to request that this key be flushed.
  # Created for flushing arrays, which are not mutated with the []= method.
  #
  def invoke_write_key(key)
    write_key(key)
  end

  protected

  def byte_with_used_bit(i); 1 << (7 - (i % 8)); end
  def byte_with_free_bit(i); ~(1 << (7 - (i % 8))); end

  def flush_page_start_offset
    @file.seek(MAGIC_FILE_NUMBER.bytesize)
    @file.write([@page_start_offset].pack("#{PACK_INT}1"))
  end

  def flush_page_count
    @file.seek(MAGIC_FILE_NUMBER.bytesize + PAGE_START_OFFSET_SIZE)
    @file.write([@page_count].pack("#{PACK_INT}1"))
  end

  def flush_used_pages
    @file.seek(PREAMBLE_SIZE)
    @file.write(@used_pages)
  end

  #
  # @pre @file not nil, and is open for writing.
  #
  def to_page(p)
    @file.seek(PREAMBLE_SIZE + @page_start_offset + p * PAGE_SIZE)
  end

  def to_next_writable_page
    @file.seek(PREAMBLE_SIZE + @page_start_offset + (@page_count * PAGE_SIZE))
  end

  #
  # type descriptor, key, *additional 64-bit unsigned integers
  #
  #
  def record_descriptor(t, k, *a)
    pack_directives = "#{PACK_INT}2A#{k.length}" + PACK_INT * a.length
    ([t, k.bytesize, k] + a).pack(pack_directives)
  end

  def size_of_record(t, k, v)
    if t == WRITE_TYPE_INDEXES[:array]
      # type, key size, array length, array size, array elements
      (3 * INT_SIZE + k.bytesize) + v.inject(0) { |acc, el| acc += 8 + el.bytesize }
    else
      # type, key size, value size, value
      (2 * INT_SIZE + k.bytesize) + INT_SIZE + v.bytesize
    end
  end

  #
  # returns [string, bytes read]
  #
  # returns nil if eof is reached before reading an entire value.
  #
  # @todo: rescue from parse errors
  #
  def read_value_s
    b_read = 0
    lu = @file.read INT_SIZE
    return nil if lu.nil? || lu.bytesize < INT_SIZE
    b_read += lu.bytesize

    l = lu.unpack(PACK_INT).first
    s = @file.read l
    return nil if s.nil? || s.bytesize < l
    b_read += s.bytesize

    [s, b_read]
  end

  #
  # Returns [record_descriptor, record_value, pages_read]
  # or nil if no record is found.
  #
  # record_descriptor is [type descriptor, key] or [type descriptor, key, array size]
  # for non-arrays and arrays, respectively.
  #
  # @todo: check how you are rescuing from parse errors.
  #
  def read_record
    n_read = 0
    tu = @file.read INT_SIZE
    return nil if tu.nil? || tu.bytesize < INT_SIZE
    if (tu == (ZERO_BYTE_ASCII_8BIT * INT_SIZE))
      # empty record. skip this page.
      @file.seek(PAGE_SIZE - INT_SIZE, IO::SEEK_CUR)
      return nil
    end
    n_read += tu.bytesize
    t = tu.unpack(PACK_INT).first

    return nil if @file.eof?
    lu = @file.read INT_SIZE
    return nil if lu.nil? || lu.bytesize < INT_SIZE
    n_read += lu.bytesize
    l = lu.unpack(PACK_INT).first

    if false # l == 7016996765293437281
      puts "*************** #{__FILE__} #{__LINE__} *************"
      puts "at: #{@file.tell}"
    end

    if l > MAX_VALUE_SIZE
      raise ParseError.new "Read size that exceeds the maximum size for a value."
    end

    k = nil
    begin
      k = @file.read l
    rescue NoMemoryError => e
      # puts "*************** #{__FILE__} #{__LINE__} *************"
      # puts "#{e.message} at #{l}"
      raise
    end

    return nil if k.nil? || k.bytesize < l
    n_read += k.bytesize
    d = if t != WRITE_TYPE_INDEXES[:array]
          [t, k]
        else
          asu = @file.read INT_SIZE
          return nil if asu.nil? || asu.bytesize < INT_SIZE
          n_read += asu.bytesize
          as = asu.unpack(PACK_INT).first
          [t, k, as]
        end
    return nil if d.nil?

    v = nil

    raw_v = nil
    case d[0]
    when WRITE_TYPE_INDEXES[:array]
      a = []
      d[2].times do |i|
        raw_v, b_read = read_value_s
        break if raw_v.nil?
        n_read += b_read
        a.push(raw_v)
      end
      v = raw_v = a
    when WRITE_TYPE_INDEXES[:hash]
      raw_v, b_read = read_value_s
      return nil if raw_v.nil?
      n_read += b_read
      v = MultiJson.decode(raw_v)
    when WRITE_TYPE_INDEXES[:string]
      raw_v, b_read = read_value_s
      return nil if raw_v.nil?
      n_read += b_read
      v = raw_v
    end

    pages_read = n_read / PAGE_SIZE
    remainder = (n_read % PAGE_SIZE)
    if remainder > 0
      @file.seek((PAGE_SIZE - remainder), IO::SEEK_CUR)
      pages_read += 1
    end

    [d, v, pages_read]
  end

  def value_s(v)
    raise MaximumValueExceeded if v.bytesize > MAX_VALUE_SIZE
    record = [v.bytesize, v]
    record_s = record.pack("#{PACK_INT}A#{record.first}")
  end

  #
  # @todo make size a required field.
  #
  def write_record(t, k, v, size = nil)
    if t == WRITE_TYPE_INDEXES[:array]
      @file.write record_descriptor(t, k, v.length)
      v.each { |el| @file.write value_s(el) }
    else
      @file.write record_descriptor(t, k)
      @file.write value_s(v)
    end

    @file.write ZERO_BYTE_ASCII_8BIT * (PAGE_SIZE - (size % PAGE_SIZE)) if size

    true
  end

  #
  # Marks used_pages bit index to indicate
  # page p to size_p pages are used.
  #
  def toggle_used(p, size_p, options = {})
    options.reverse_merge!(:used => true)
    for i in p...(p + size_p)
      if options[:used]
        @used_pages[i / 8] = [@used_pages[i / 8].ord | byte_with_used_bit(i)].pack("c")
      else
        @used_pages[i / 8] = [@used_pages[i / 8].ord & byte_with_free_bit(i)].pack("c")
      end
    end
    flush_used_pages
  end

  def deallocate_page(p, size_p)
    to_page(p)
    @file.write (ZERO_BYTE_ASCII_8BIT * PAGE_SIZE) * size_p
    toggle_used(p, size_p, :used => false)
  end

  #
  # @pre new_pages >= 0
  #
  def allocate_page(new_pages)

    # is there existing page space?
    new_page_offset = nil
    contiguously_available = 0
    i = 0
    while i < (@used_pages.bytesize * 8) && contiguously_available < new_pages
      if @used_pages[i / 8].ord & byte_with_used_bit(i) == 0
        new_page_offset = i if new_page_offset == nil
        contiguously_available += 1
      else
        new_page_offset = nil
        contiguously_available = 0
      end
      i += 1
    end

    new_page_offset = nil if contiguously_available < new_pages

    if new_page_offset.nil?

      # We need to allocate more space on disk.

      first_free_page = (@used_pages.bytesize * 8)
      first_free_page -= 1 while first_free_page > 0 && @used_pages[(first_free_page - 1) / 8].ord & byte_with_used_bit(first_free_page - 1) == 0

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
          desc, v, pages_read = read_record
          to_page(first_free_page)
          record_to_write = (desc[0] == WRITE_TYPE_INDEXES[:hash]) ? MultiJson.encode(v) : v
          size = size_of_record(desc[0], desc[1], record_to_write)
          write_record(desc[0], desc[1], record_to_write, size)
          size_p = (size / PAGE_SIZE) + (size % PAGE_SIZE == 0 ? 0 : 1)

          if false # desc[1] == ""
            puts "*************** #{__FILE__} #{__LINE__} *************"
            puts "wrote key #{desc[1]} to page #{first_free_page} with page start offset of #{@page_start_offset} and size_p #{size_p}. page count is #{@page_count}"
          end

          # update page size on disk to account for migrated key
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

        used_page_appendage = ZERO_BYTE_ASCII_8BIT * PAGE_SIZE
        @used_pages += used_page_appendage


        #
        # bit-shift used_pages to the left
        #

        # the following two variables do not account for bit-shifting. tail_size
        # would be one larger and used_of_next_bit_index_page would be one smaller
        # if they did.
        tail_size = (@used_pages.bytesize * 8) - first_free_page # free space at end of used_pages
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
        for i in (1...((@used_pages.bytesize * 8) + used_of_next_bit_index_page))
          j = i - 1
          j_bit_as_used = byte_with_used_bit(j)  # | this
          j_bit_as_free = byte_with_free_bit(j)  # & this
          if i < size_p
            # mark head as free due to migrated key
            @used_pages[j / 8] = [@used_pages[j / 8].ord & j_bit_as_free].pack("c")
          elsif i < first_free_page
            # bit shift middle of used_pages
            cur_i = @used_pages[i / 8].ord
            cur_j = @used_pages[j / 8].ord
            @used_pages[j / 8] = (cur_i & byte_with_used_bit(i) == 0 ? [cur_j & j_bit_as_free].pack("c") : [cur_j | j_bit_as_used].pack("c"))
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

        # acknowledge that we lost a page to the used_pages index
        if @page_count > 0
          @page_count -= 1
          flush_page_count
        end

        # @todo do we have to update new_page offset if it moves even further down?
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

  def write_key(key, v = nil)
    v = @store[key] if v.nil?
    p_original, size_p = (@store_pages[key] || [nil, nil])
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

    record_value_to_write = (ti == :hash) ? MultiJson.encode(v) : v
    size = size_of_record(t, key, record_value_to_write)
    new_size_p = (size / PAGE_SIZE) + (size % PAGE_SIZE == 0 ? 0 : 1)
    p = allocate_page(new_size_p) if size_p.nil? || new_size_p > size_p
    @page_count += new_size_p - (@page_count - p)
    flush_page_count

    if false # key == ""
      puts "*************** #{__FILE__} #{__LINE__} *************"
      puts "writing key #{key} to page #{p} with page start offset of #{@page_start_offset}"
    end
    to_page(p)
    write_record(t, key, record_value_to_write, size)
    toggle_used(p, new_size_p)

    if p != p_original
      @store_pages[key] = [p, new_size_p]
      deallocate_page(p_original, size_p) if p_original
    end
  end

  def erase_key(key)
    p, size_p = @store_pages[key]
    deallocate_page(p, size_p)
    compact_disk_usage
  end

  def compact_disk_usage
    used_pages_size_p = @used_pages.bytesize / PAGE_SIZE

    pc = @page_count
    used_pages_deallocated = 0
    i = 0
    at_least_one_liberation = false
    final_block_is_free = true
    while final_block_is_free && i < used_pages_size_p
      ip = (used_pages_size_p - 1 - i)
      j = (ip * PAGE_SIZE * 8) - 1
      while final_block_is_free && j < ((ip + 1) * PAGE_SIZE * 8)
        final_block_is_free = final_block_is_free && (@used_pages[j / 8].ord & byte_with_used_bit(j) == 0)
        j += 1
      end

      if at_least_one_liberation && !final_block_is_free
        if false
          puts "*************** #{__FILE__} #{__LINE__} *************"
          puts "#compact_disk_usage freed #{used_pages_deallocated} page(s) of used pages, then halted on page #{ip} for bit index j == #{j}."
          puts "the byte for this bit index at file position #{PREAMBLE_SIZE + (j / 8)} (0x#{(PREAMBLE_SIZE + (j / 8)).to_s(16)}), having value #{@used_pages[j / 8].ord}, disabled final_block_is_free. the bit that disabled shrinking was the #{j % 8}th bit."
          puts "page j is at position #{(PREAMBLE_SIZE + @page_start_offset + PAGE_SIZE * j).to_s(16)} of the file."
        end
      end

      if final_block_is_free
        # bit-shift to the right
        for k in (0...(@used_pages.bytesize * 8) - 1)
          kp = (@used_pages.bytesize * 8) - 1 - k
          @used_pages[kp / 8] = [(@used_pages[(kp - 1) / 8].ord & byte_with_used_bit(kp - 1) == 0) ? @used_pages[kp / 8].ord & byte_with_free_bit(kp) : @used_pages[kp / 8].ord | byte_with_used_bit(kp)].pack("c")
        end

        # first bit points to old bit-index block, and it is free
        @used_pages[0] = [@used_pages[0].ord & byte_with_free_bit(0)].pack("c")
        @used_pages = @used_pages[0, @used_pages.length - PAGE_SIZE]
        flush_used_pages

        @page_count = @used_pages.bytesize * 8
        flush_page_count

        @page_start_offset = @used_pages.bytesize
        flush_page_start_offset

        used_pages_deallocated += 1
        z = PREAMBLE_SIZE + @page_start_offset + (@page_count * PAGE_SIZE)
        if false
          redone = @used_pages.bytesize / PAGE_SIZE
          puts "*************** #{__FILE__} #{__LINE__} *************"
          puts "trying to truncate to #{z} for page count of #{@page_count} which used to be #{pc} where used_pages_size_p in this method was #{used_pages_size_p} and is now #{redone}. file size is #{@file.size}"
        end
        @file.truncate(z)

        at_least_one_liberation = true
      end

      i += 1
    end

    @store_pages.each do |k, v|
      v[0] += used_pages_deallocated
    end
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

  #
  # skip journal and dead regions as you read.
  #
  # @todo: if you find a duplication of a key, delete
  # the earlier-occuring one and mark it as free in the bit-index.
  #
  # @todo if you reach eof before reading pages equal to page_count,
  # decrease page_count and flush it.
  #
  def load_store_from_disk
    @store = {}
    @store_pages = {}

    open_db
    @file.rewind

    magic_descriptor = @file.read 4
    if magic_descriptor != MAGIC_FILE_NUMBER
      @store.clear
      puts "Error: Not a valid fine grained file: #{@path}"
      return
    end

    pou = @file.read INT_SIZE
    @page_start_offset = pou.unpack(PACK_INT).first

    pcu = @file.read INT_SIZE
    @page_count = pcu.unpack(PACK_INT).first

    used_pages_size = @page_start_offset

    if (used_pages_size < 0) || (used_pages_size % PAGE_SIZE != 0)
      puts "Error: Not a valid fine grained file: #{@path}"
      @page_count = 0
      @page_start_offset = 0
      return
    end

    @used_pages = @file.read(used_pages_size) if used_pages_size > 0

    i = 0
    to_page(i)
    record = @file.eof? ? nil : read_record
    while (record || (i < @page_count && !@file.eof?))
      if record.nil?
        i += 1
      else
        @store[record[0][1]] = record[1]
        @store_pages[record[0][1]] = [i, record[2]]
        i += record[2]
      end

      record = @file.eof? ? nil : read_record
    end

    # update page_count if there are zeroes at end of file, and
    # (@used_pages.bytesize * 8) < @page_count. should be an increment.
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
  DB = "db/fineGrained.db"
  @@store = nil
  @@read_queues = {}

  def self.enter_read_queue!(key, signature, blocking_read)
    @@read_queues[key] ||= []
    @@read_queues[key].push([signature, blocking_read])
  end

  def self.leave_read_queue!(key, signature, blocking_read)
    @@read_queues[key].delete([signature, blocking_read])
  end

  #
  # This could be in a constructor but the eventmachine constructor
  # documentation is weird. I don't understand it. M. Rivera 10/18/2015
  #
  def self.ensure_opened
    @@store = FineGrainedFile.new(DB) if @@store.nil?
  end

  def post_init
  end

  def unbind
  end

  module Responses
    OK = "OK\n"
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
    params = []
    case cmd
    when "SET", "PUSH", "LREAD"
      bounds = key_match.offset(0)
      params_string = key_and_params[bounds[1], key_and_params.length - bounds[1]]

      case cmd
      when "LREAD"
        params = params_string.split(/\s+/, 2)
      else
        params = [params_string]
      end

    end

    if false
      puts "*************** #{__FILE__} #{__LINE__} *************"
      puts "FineGrained cmd #{cmd} with key #{key} and params #{params}"
    end

    case cmd
    when /quit/i
      close_connection
      return false
    else
      begin
        case cmd
        when "DEL"
          begin
            @@store.delete(key)
            send_data Responses::OK
          rescue FineGrainedFile::KeyNotFoundError => e
            send_data "Error: Key not found.\n"
          end
        when "SET"
          @@store[key] = params.first
          send_data Responses::OK
        when "READ"
          r = @@store[key]
          if r.nil?
            send_data "Error: Key not found.\n"
            return
          end
          send_data r + "\n"
        when 'PUSH', 'POP', 'SHIFT', 'LREAD', 'LCLEAR', 'LLENGTH'
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
              blocking_read.set_deferred_status(:succeeded, key, params.first)
            else
              @@store[key].push(params.first)
              @@store.invoke_write_key(key)
            end
            send_data Responses::OK
          when 'POP'
            if @@store[key].empty?
              send_data "Error: Nothing in array.\n"
              return false
            end
            r = @@store[key].pop
            @@store.invoke_write_key(key)
            send_data "#{r}\n"
          when 'SHIFT'
            if @@store[key].empty?
              BlockingRead.new(self).wait!(key)
              return false
            end
            r = @@store[key].shift
            @@store.invoke_write_key(key)
            send_data "#{r}\n"
          when 'LREAD'
            a = @@store[key]
            i = 0
            offset = params.first.try(:to_i) || 0
            n = (params.length > 1) ? (params[1].try(:to_i) || -1) : -1
            n = a.length if n == -1
            while i < n
              if (offset + i) >= a.length
                send_data "Warning: Nothing left in array.\n"
                return
              end

              r = a[offset + i]
              send_data "#{r}\n"
              i += 1
            end

            send_data Responses::OK
          when "LCLEAR"
            @@store[key] = []
            @@store.invoke_write_key(key)
            send_data Responses::OK
          when "LLENGTH"
            a = @@store[key]
            send_data "#{@@store[key].length}\n"
          end
        else
          send_data "Error: Unrecognized command.\n"
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

