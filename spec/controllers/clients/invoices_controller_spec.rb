
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
    it "should show a given invoice", :current => true do
      get :show, :format => :json, :id => @invoice.id
      result = JSON.parse(response.body)
      puts "*************** #{__FILE__} #{__LINE__} *************"
      puts result.to_yaml

      result['id'].should == @invoice.id
    end
  end

  context "index" do

    it "should present json results of invoices", :current => true do
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
        response.should contain(@invoice.title)
      end

    end
  end
end
