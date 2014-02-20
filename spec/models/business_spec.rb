
require 'spec_helper'

describe Business do

  context "validations", :current => true do
    before do
      @business = FactoryGirl.create(:business)
    end

    it "should require unique handle" do
      b2 = FactoryGirl.build(:business, :handle => @business.handle)
      b2.save.should be_false
      b2.errors[:handle].should == ['has already been taken']
    end

    it "should downcase and trim the handle" do
      b2 = FactoryGirl.create(:business, :handle => " CHAOS9 ")
      b2.reload.handle.should == "chaos9"
    end

    it "should validate format of handle" do
      ["chaos 9", "chao*s9"].map { |h| FactoryGirl.build(:business, :handle => h) }.each do |b|
        b.save.should be_false
        b.errors[:handle].should =~ [I18n.t('business.errors.handle_format')]
      end        
    end

    it "should not allow conflict with mfe" do
      mfe = FactoryGirl.create(:marketing_front_end)
      d = FactoryGirl.build(:business, :domain => mfe.domain)
      d.save.should be_false
      d.errors[:domain].should =~ [I18n.t('business.mfe_domain_conflict')]
      d.domain = FactoryGirl.build(:business).domain
      d.save.should be_true
    end

  end
end