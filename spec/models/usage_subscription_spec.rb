require 'spec_helper'

describe UsageSubscription do
  context "validations" do
    it "should require business" do
      @us = FactoryGirl.create(:usage_subscription)
      @us.business = nil
      @us.save.should be_false
    end
  end

  context "feature_selections" do
    before do
      Feature.ensure_master_list_created!
    end

    it "should be indicatable through nested attributes" do
      fs = Feature.all
      @us = FactoryGirl.create(:usage_subscription)

      f = fs.first
      @us.features.count.should == 0
      @us.update_attributes!({ :feature_selections_attributes => [{:feature_id => f.id}] })
      @us.features.count.should == 1

      Feature.count.should == fs.count
    end
  end

  it "should accurately calculate plan id" do

    Feature.destroy_all # unique to this test, since mfe has already been created.

    @f1 = FactoryGirl.create(:feature, :bit_index => 0)
    @f2 = FactoryGirl.create(:feature, :bit_index => 1)
    @f3 = FactoryGirl.create(:feature, :bit_index => 2)
    Feature.ensure_minimal_pricings!

    @profile = FactoryGirl.create(:stripe_payment_gateway_profile_for_us)
    @us = @profile.payment_gateway_profilable
    @us.generation = 1
    @us.save
    @us.reload # plan id is already calculated...wipe it out
    FactoryGirl.create(:feature_selection, :usage_subscription => @us, :feature => @f1)
    FactoryGirl.create(:feature_selection, :usage_subscription => @us, :feature => @f2)

    bs = "0000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011"
    encoded = "AAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM="
    encoded.unpack("m0").first.unpack("B*").first.should == bs

    @us.calculated_plan_id.should == encoded
    bitstring = @us.calculated_plan_id.unpack("m0").first.unpack("B*").join('')

    plan_bits = bitstring[0,4]
    bitstring = bitstring[4,bitstring.length]

    generation_bits = bitstring[0,UsageSubscription::GENERATION_BITS]
    bitstring = bitstring[UsageSubscription::GENERATION_BITS,bitstring.length]

    feature_bits = bitstring

    # Check generation
    generation_from_code = [generation_bits].pack("B*").unpack("H*").first.to_i
    @us.generation.should == generation_from_code

    # Check bits
    features_indicated = (0...UsageSubscription::FEATURE_BITS).select { |i|
      feature_bits[feature_bits.length - i - 1] == "1"
    }.map { |i| Feature.find_by_bit_index i }

    @us.features.should =~ features_indicated

    true
  end

  context "price" do
    before do
      @f1 = FactoryGirl.create(:feature_no_pricing)
      @f2 = FactoryGirl.create(:feature_no_pricing)
      @f3 = FactoryGirl.create(:feature_no_pricing)

      FactoryGirl.create(:feature_pricing, :feature => @f1, :generation => 0, :price => "6.00")
      FactoryGirl.create(:feature_pricing, :feature => @f2, :generation => 0, :price => "6.00")
      FactoryGirl.create(:feature_pricing, :feature => @f3, :generation => 0, :price => "6.00")

      @profile = FactoryGirl.create(:stripe_payment_gateway_profile_for_us)
      @us = @profile.payment_gateway_profilable
      @us.reload
    end

    it "should generate current generation's pricing if necessary" do
      @f4 = FactoryGirl.create(:feature_no_pricing)
      FactoryGirl.create(:feature_pricing, :feature => @f4, :generation => 0, :price => "5.00")

      FactoryGirl.create(:feature_selection, :usage_subscription => @us, :feature => @f1)
      FactoryGirl.create(:feature_selection, :usage_subscription => @us, :feature => @f2)
      FactoryGirl.create(:feature_selection, :usage_subscription => @us, :feature => @f3)
      FactoryGirl.create(:feature_selection, :usage_subscription => @us, :feature => @f4)

      @us.generation = 1
      @us.save
      @us.calculated_price.should == BigDecimal.new("23.00") # 6 + 6 + 6 + 5
    end

    it "should reflect generation" do

      FactoryGirl.create(:feature_selection, :usage_subscription => @us, :feature => @f1)
      FactoryGirl.create(:feature_selection, :usage_subscription => @us, :feature => @f2)

      @us.calculated_price.should == BigDecimal.new("12.00") # 6 + 6

      FactoryGirl.create(:feature_pricing, :feature => @f1, :generation => 1, :price => "10.00")
      FactoryGirl.create(:feature_pricing, :feature => @f2, :generation => 1, :price => "10.00")
      FactoryGirl.create(:feature_pricing, :feature => @f3, :generation => 1, :price => "10.00")

      FactoryGirl.create(:feature_pricing, :feature => @f1, :generation => 2, :price => "2.00")
      FactoryGirl.create(:feature_pricing, :feature => @f2, :generation => 2, :price => "2.00")
      FactoryGirl.create(:feature_pricing, :feature => @f3, :generation => 2, :price => "15.00")

      @us.reload.calculated_price.should == BigDecimal.new("12.00") # 6 + 6 still. dont use future gen.

      @us.update_attributes(:generation => 1)
      @us.reload.calculated_price.should == BigDecimal.new("20.00") # 10 + 10
      FactoryGirl.create(:feature_selection, :usage_subscription => @us, :feature => @f3)
      @us.reload.calculated_price.should == BigDecimal("30.00") # 10 + 10 + 10

      FactoryGirl.create(:feature_pricing, :feature => @f1, :generation => 3, :price => "20.00")
      FactoryGirl.create(:feature_pricing, :feature => @f2, :generation => 3, :price => "20.00")
      FactoryGirl.create(:feature_pricing, :feature => @f3, :generation => 3, :price => "20.00")


      @us.reload.calculated_price.should == BigDecimal("30.00") # 10 + 10 + 10

      # 4th generation picks up latest pricings.
      @usgen4 = FactoryGirl.create(:usage_subscription, :generation => 3)
      FactoryGirl.create(:feature_selection, :usage_subscription => @usgen4, :feature => @f1)
      FactoryGirl.create(:feature_selection, :usage_subscription => @usgen4, :feature => @f2)
      @usgen4.reload.calculated_price.should == BigDecimal.new("40.00")

    end
  end

  context "bit string demos" do
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
