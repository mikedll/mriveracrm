
require "spec_helper"

describe FineGrained do

  before :each do
    @db = FineGrainedFile.new(Rails.root.join("tmp/fgtest.db"))
    @db.hard_clean!
  end

  after :each do
    @db.close
  end

  context "basics" do
    it "should be MAGIC_FILE_NUMBER.bytesize + 2 integers without any data stored on disk" do
      @db.filesize.should == FineGrainedFile::MAGIC_FILE_NUMBER.bytesize + (2 * FineGrainedFile::INT_SIZE)
    end
  end

  context "deletes" do
    it "should zero out space on disk where a deleted key used to be written" do
      @db["hash"] = {
        'a' => "hello",
        'fortunately' => "I didn't have to mop the dishes."
      }
      @db["b"] = "bee"

      @db.delete("hash")

      @db.close
      @db = FineGrainedFile.new(Rails.root.join("tmp/fgtest.db"))

      @db["hash"].should be_nil
      @db["b"].should == "bee"
    end
  end

  context "writes" do
    context "should allocate space and remember the write" do
      it "when a hash is written" do
        @db["hash"] = { :a => "hello", 2 => "adamant" }
        @db["hash"].should == { :a => "hello", 2 => "adamant" }
      end

      it "when an array is written"  do
        @db["an_array"] = ['a', 'bbb', 'c', 'dddd', 'e' * 16]
        @db["an_array"].should == ['a', 'bbb', 'c', 'dddd', 'e' * 16]
      end

      it "when a string is written" do
        @db[":a"] = ("a" * 170)
        @db["b"] = "bee"

        up = @db.instance_variable_get('@used_pages')
        i = 0
        (up[i / 8].ord & (1 << (7 - (i % 8)))).should == 128

        i = 1
        (up[i / 8].ord & (1 << (7 - (i % 8)))).should == 64

        i = 2
        (up[i / 8].ord & (1 << (7 - (i % 8)))).should == 0

        @db[":a"].should == "a" * 170
        @db["b"].should == "bee"
      end

      it "when hashes, arrays, and strings are written at the same time and the database is reloaded from disk" do
        @db["an_array"] = ['a', 'bbb', 'c', 'dddd', 'e' * 16]
        @db["hash"] = {
          'a' => "hello",
          'fortunately' => "I didn't have to mop the dishes."
        }
        @db[":a"] = ("a" * 170)
        @db["b"] = "bee"


        @db.close
        @db = FineGrainedFile.new(Rails.root.join("tmp/fgtest.db"))


        @db["an_array"].should == ['a', 'bbb', 'c', 'dddd', 'e' * 16]
        @db["hash"].should == {
          'a' => "hello",
          'fortunately' => "I didn't have to mop the dishes."
        }
        @db[":a"].should == "a" * 170
        @db["b"].should == "bee"
      end

      it "when a migrated key is against the next available free space in the bit-index" do

        # @todo this is a difficult test to write, due to generated
        # 155 pages of data.

        # when size_p and first_free_page are contiguous
        # size_p = 155
        # first_free_page = 155
        # tail_size = 101
        # used_of_next_bit_index_page = 54
        #
        # result: bits 0 to 153 (154 bits) are free, and bits 155 to 308 are used (155 bits)

        # up = @db.instance_variable_get('@used_pages')
        # for i in 0..153
        #   (up[i / 8].ord & (1 << (7 - (i % 8)))).should == 0
        # end

        # for i in 155..308
        #   (up[i / 8].ord & (1 << (7 - (i % 8)))).should == 1
        # end
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
