
require 'spec_helper'

describe Client::InvoicesController do

  before :each do
    @user = FactoryGirl.create(:client_user)
    @invoice = FactoryGirl.create(:pending_invoice, :client => @user.client)
    sign_in @user
    request.host = @user.client.business.host
  end

  it "should render an invoice" do
    get :index
    response.should be_success
  end

  it "should show a given invoice" do
    get :show, :format => :json, :id => @invoice.id
    result = JSON.parse(response.body)
    result['id'].should == @invoice.id
  end

  context "results" do
    render_views
    it "should show the last transaction error if one occured" do
      response.should contain(@invoice.title)
    end
  end
end
