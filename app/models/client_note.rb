class ClientNote
  belongs_to :client

  before_create :_defaults

  def _defaults
    self.recorded_at = Time.now if self.recorded_at.nil?
  end

end
