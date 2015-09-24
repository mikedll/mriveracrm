
require "spec_helper"

describe FineGrained do

  before :each do
    @db = FineGrainedFile.new(Rails.root.join("tmp/fgtest.db"))
    @db.hard_clean!
  end

  after :each do
    @db.close
  end

  context "basic" do
    it "should be MAGIC_FILE_NUMBER.bytesize + 2 integers without any data stored on disk" do
      @db.filesize.should == FineGrainedFile::MAGIC_FILE_NUMBER.bytesize + (2 * FineGrainedFile::INT_SIZE)
    end
  end

  context "writes" do
    context "should allocate space" do
      it "when a migrated key is against the next available free space in the bit-index", :current => true do
        # when size_p and first_free_page are contiguous
        # size_p = 155
        # first_free_page = 155
        # tail_size = 101
        # used_of_next_bit_index_page = 54
        #
        # result: bits 0 to 153 (154 bits) are free, and bits 155 to 308 are used (155 bits)

        v = "a" * (155 - 16)
        k = ":a"
        @db.write_key k, v
        @db.write_key "b", "bee"

        up = @db.instance_variable_get('@used_pages')
        for i in 0..153
          (up[i / 8].ord & (1 << (7 - (i % 8)))).should == 0
        end

        for i in 155..308
          (up[i / 8].ord & (1 << (7 - (i % 8)))).should == 1
        end
      end

      it "when tail size is 0 and size_p is non-zero" do
      end

      it "when tail size is 0 and size_p == PAGE_SIZE" do
      end

      it "when tail size is 0 and size_p > PAGE_SIZE" do
      end
    end
  end
end
