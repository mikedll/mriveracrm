
require 'spec_helper'

describe Client::InvoicesController do

  before :each do
    @user = FactoryGirl.create(:client_user)
    @invoice = FactoryGirl.create(:pending_invoice, :client => @user.client)
    @invoice2 = FactoryGirl.create(:pending_invoice, :client => @user.client)
    sign_in @user
    request.host = @user.client.business.host
  end

  context "show" do
    it "should show a given invoice" do
      get :show, :format => :json, :id => @invoice.id
      result = JSON.parse(response.body)
      result['id'].should == @invoice.id
    end
  end

  context "index" do

    it "should present json results of invoices" do
      get :index, :format => :json
      result = JSON.parse(response.body)
      result.length.should == 2
    end

    context "html" do
      render_views

      it "should render invoices with client view" do
        get :index
        response.should be_success
      end

      it "should show the last transaction error if one occured" do
        expect(@user.client.payment_gateway_profile.update_payment_info(SpecSupport.declined_card_stripe_cc_params)).to be true
        @invoice2.reload
        @invoice2.charge!
        get :index, :format => :json
        result = JSON.parse(response.body)
        result[1]["last_error"].should == "Card was declined."
      end
    end
  end
end
