class Note < ActiveRecord::Base
  belongs_to :client

  attr_accessible :recorded_at, :body

  before_create :_defaults

  def _defaults
    self.recorded_at = Time.now if self.recorded_at.nil?
  end

end
