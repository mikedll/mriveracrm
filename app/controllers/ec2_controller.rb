
class Ec2Controller < ApplicationController

  DefaultImage = 'ami-c0f615a9'

  def index
    @image_id = DefaultImage
    render :layout => 'home'
  end

  def status
    @latest_time = Time.now.strftime("The time is %H:%m:%S")
    render :layout => false
  end

  def startup
  end

  def terminate
  end

end
