
require 'spec_helper'

describe Invitation do
  context "accept" do
    it "should move invitation from available to accepted" do
      invitation = FactoryGirl.create(:client_invitation)
      user = FactoryGirl.create(:employee_user)
      invitation.accept_user!(user)
      invitation.accepted?.should be_true      
    end
  end

end
