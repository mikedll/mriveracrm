class Manage::InvoicesController < ApplicationController

  make_resourceful

  # def index
  #   @invoices = Invoice.all
  #   respond_to do |fmt|
  #     fmt.js { render :json => @invoices }
  #     fmt.html
  #   end
  # end

  # def create
  #   @client = Client.new client_params
  #   if @client.save
  #     render :status => :created, :json => @client
  #   else
  #     render :status => :unprocessable_entity, :json => @client.errors
  #   end
  # end

end

