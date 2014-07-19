require 'spec_helper'

describe UsageSubscription do
  context "validations" do
    it "should require business" do
      @us = FactoryGirl.create(:usage_subscription)
      @us.business = nil
      @us.save.should be_true
    end
  end

  context "bit string demos" do
    it "should show ruby bit string demos. (not a real spec)" do

      scheme = 1
      generation = 2
      feature_indicies = [0, 1, 2, 3, 7, 11, 12]

      # 4 bits scheme, 4 bits generation, 16 bits features. 24 bits.
      s = "0001" + "0010" + "0001100010001111"
      bit_array = s.split('') # ["0", "0", "0", "1",   "0", "0", "1", "0",   "0", "0", "0", "1", "0", "0", "0", "1", "0", "0", "0", "1", "1", "1", "1"]
s.length
bitstring.length
      binary_s = bit_array.pack("b" * 24)

      binary_s = bit_array.pack("m0m0m0m0")


      base64_encoded = Base64.strict_encode64(binary_s)
s = 
("\x00\x00\x00\x00\x00\x00").length
Base64.strict_encode64("\x00\x00\x00\x00\x00\x00")
Base64.strict_encode64("\x01\x04")
"\x00\x00\x00\x01\\x00x04\x00\x00".length
["\x00\x00\x00\x01\x00x04\x00\x00"].pack("m0")

sb = "\x00\x00\x00\x01\x00x04\x00\x00".force_encoding("ASCII-8BIT")
[sb].pack("m")

Base64.strict_decode64('AAAAAQB4MDQAAA==')
      base64_encoded.length
s = ['1', '0', '0', '0'].pack("b4b64")

    Base64.encode("1010")

    end
  end
end
