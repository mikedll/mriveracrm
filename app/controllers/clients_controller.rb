class ClientsController < ApplicationController
  def index
    @clients = Client.limit(10)

    respond_to do |fmt|
      fmt.js { render :json => @clients }
      fmt.html
    end
  end

  def create
    @client = Client.new client_params
    if @client.save
      render :status => :created, :json => @client
    else
      render :status => :unprocessable_entity, :json => @client.errors
    end
  end

  def update
    @client = Client.find params[:id]
    @client.update_attributes(client_params)
    if @client.save
      render :status => :ok, :json => @client
    else
      render :status => :unprocessable_entity, :json => @client.errors
    end
  end

  def new
    render :layout => nil
  end

  def destroy
    @client = Client.find params[:id]
    @client.destroy
    render :ok, :json => @client
  end


  def client_params
    params.slice(* Client.accessible_attributes.map { |k| k.underscore.to_sym } )
  end

end
