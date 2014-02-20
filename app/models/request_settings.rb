class RequestSettings
  cattr_accessor :host, :port

  def self.reset
    self.host = nil
    self.port = nil
  end

  def self.full_host
    host + (port ? ":#{port}" : "")    
  end


end
