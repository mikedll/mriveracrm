
require 'spec_helper'

describe Invitation do
  context "validations" do
    it "should require client, employee, or handle" do
      @invitation = FactoryGirl.create(:new_business_invitation)
      @invitation.handle = ""
      @invitation.save.should be_false
    end

    it "should require unique email" do
      @invitation = FactoryGirl.build(:new_business_invitation)
      @invitation2 = FactoryGirl.build(:new_business_invitation, :email => @invitation.email, :handle => @invitation.handle)
      @invitation.save.should be_true
      @invitation2.save.should be_false
    end

    it "should allow the same email for different handles" do
      @invitation = FactoryGirl.build(:new_business_invitation)
      @invitation2 = FactoryGirl.build(:new_business_invitation, :email => @invitation.email)
      @invitation.save.should be_true
      @invitation2.save.should be_true
    end

    it "should strip email and handle" do
      @invitation = FactoryGirl.create(:new_business_invitation)
      e = @invitation.email
      @invitation.email = "  #{@invitation.email}  "
      h = @invitation.handle
      @invitation.handle = "  #{@invitation.handle}  "
      @invitation.save.should be_true
      @invitation.email.should == e
      @invitation.handle.should == h
    end
  end

  context "accept" do
    it "should move invitation from available to accepted" do
      invitation = FactoryGirl.create(:client_invitation)
      user = FactoryGirl.create(:client_user)
      invitation.accept_user!(user)
      invitation.accepted?.should be_true
    end

    it "should be able to create a business" do
      Business.first.should be_nil
      invitation = FactoryGirl.create(:new_business_invitation)
      u = FactoryGirl.build(:user_base, :email => invitation.email)
      u.business.should be_nil

      invitation.accept_user!(u).should be_true
      u.business.should_not be_nil
      b = Business.first
      u.reload
      b.should_not be_nil
      b.should == u.business
      u.employee.role.should == Employee::Roles::OWNER

      invitation.reload
      invitation.business.should == b
    end
  end

end
