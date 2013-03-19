class ClientsController < ApplicationController
  def index
    @clients = Client.limit(10)

    respond_to do |fmt|
      fmt.js { render :json => @clients }
      fmt.html
    end
  end

  def create
    c = Client.new params.slice(:first_name, :last_name, :email)
    if c.save
      render :status => :created, :json => c
    else
      render :status => :unprocessable_entity, :json => c.errors
    end
  end

  def new
    render :layout => nil
  end

end
