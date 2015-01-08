
require 'spec_helper'

describe Business do

  context "validations" do
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
      d = FactoryGirl.build(:business, :host => mfe.host)
      d.save.should be_false
      d.errors[:host].should =~ [I18n.t('business.mfe_host_conflict')]
      d.host = FactoryGirl.build(:business).host
      d.save.should be_true
    end

  end

  it "scopes" do
    b = FactoryGirl.create(:business)
    b = Business.with_features.find_by_id b.id
    b.should_not be_nil
  end
end
