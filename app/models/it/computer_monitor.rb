class IT::ComputerMonitor < ActiveRecord::Base

  DEFAULT_PORT = 8150

  include BackgroundedPolling
  include ValidationTier
  include ActionView::Helpers::TranslationHelper

  belongs_to :business, :inverse_of => :it_monitors

  before_validation :_defaults, :if => :new_record?

  validates :business_id, :presence => true
  validates :name, :presence => true

  scope :by_business, lambda { |id| where('business_id = ?', id) }

  class Worker < WorkerBase
  end

  def reload
    @from_header = nil
    super
  end

  def from_header
    @from_header ||= business.owner.email
  end

  def target_endpoint
    "http://#{hostname}:#{port}#{path}"
  end

  def handle_poll_result(result)
    puts "Found success."
  end

  protected

  def _defaults
    self.path = "/" if path.blank?
    self.port = DEFAULT_PORT if port.nil?
  end

end
