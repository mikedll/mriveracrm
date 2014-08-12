require 'spec_helper'

describe UsageSubscription do
  context "validations" do
    it "should require business" do
      @us = FactoryGirl.create(:usage_subscription)
      @us.business = nil
      @us.save.should be_true
    end
  end

  context "feature_selections" do
    it "should be indicatable through nested attributes", :current => true do
      fs = Feature.all
      @us = FactoryGirl.create(:usage_subscription)

      f = fs.first
      @us.features.count.should == 0
      @us.attributes = { :feature_selections_attributes => [{:feature_id => f.id}] }
      @us.save!
      @us.features.count.should == 1
      Feature.count.should == fs.count
    end
  end

  context "bit string demos", :current => true do
    it "should show ruby bit string demos. (not a real spec)" do
      scheme = 1
      generation = 2
      feature_indices = [0, 1, 2, 3, 7, 11, 12]

      # 4 bits scheme, 4 bits generation, 16 bits features. 24 bits.
      s = "0001" + "0010" + "0001100010001111"
      binary_s = [s].pack("B*") # "\x12\x18\x8F"
      base64s = [binary_s].pack("m0") # "EhiP"

      base64s.should == "EhiP"
      Base64.strict_encode64(binary_s).should == base64s

      decoded_binary_s = Base64.strict_decode64(base64s)
      decoded_s = decoded_binary_s.unpack("B*").first
      decoded_s
      decoded_s[4,4]

      decoded_scheme = decoded_s[0,4]
      decoded_generation = decoded_s[4,4]
      decoded_version_bits = decoded_s[8,decoded_s.length - 8]

      [[decoded_scheme, scheme],
        [decoded_generation, generation]].each do |pairing|
        ["0000" + pairing.first].pack("B*").unpack("H*").first.to_i.should == pairing.last
      end

      decoded_feature_indices = []
      (0...decoded_version_bits.length).each do |i|
        if decoded_version_bits[decoded_version_bits.length - 1 - i] == "1"
          decoded_feature_indices.push(i)
        end
      end

      decoded_feature_indices.should =~ feature_indices
    end
  end
end
