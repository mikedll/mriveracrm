class IT::ComputerMonitor < ActiveRecord::Base

  DEFAULT_PORT = 8150

  include Introspectable
  include BackgroundedPolling
  include ValidationTier
  include ActionView::Helpers::TranslationHelper

  belongs_to :business, :inverse_of => :it_computer_monitors

  before_validation :_defaults, :if => :new_record?

  validates :business_id, :presence => true
  validates :name, :presence => true
  validates :hostname, :presence => true
  validates :port, :presence => true
  validates :port, :numericality => { :only_integer => true }

  attr_accessible :name, :hostname, :port, :active

  scope :by_business, lambda { |id| where('business_id = ?', id) }

  introspect do
    can :destroy, :enabler => nil

    attr :name
    attr :hostname
    attr :port
    attr :active
    group do
      attr :last_result, :read_only
      attr :last_polled_at, [:read_only, :datetime]
    end
    attr :last_error, [:read_only]

    action :refresh, :type => :basic
    action :rank, :label => "Run", :enabled_on => :runnable?, :confirm => I18n.t('backgrounded_polling.run_confirm')
  end

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
