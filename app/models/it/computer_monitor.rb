class IT::ComputerMonitor < ActiveRecord::Base

  DEFAULT_PORT = 8150

  include BackgroundedPolling
  include ValidationTier
  include ActionView::Helpers::TranslationHelper

  belongs_to :business, :inverse_of => :it_computer_monitors

  before_validation :_defaults, :if => :new_record?

  validates :business_id, :presence => true
  validates :name, :presence => true

  scope :by_business, lambda { |id| where('business_id = ?', id) }

  class Worker < WorkerBase
  end

  def target_endpoint
    "http://#{hostname}:#{port}"
  end

  def before_poll
    self.last_result = nil
  end

  def handle_poll_result(response, request, result)
    self.last_result = response.net_http_res.code.to_i
  end

  protected

  def _defaults
    self.port = DEFAULT_PORT if port.nil?
  end

end
