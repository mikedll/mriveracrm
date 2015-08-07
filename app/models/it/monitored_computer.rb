class IT::MonitoredComputer < ActiveRecord::Base

  HEARTBEAT_PERIOD = 10.minutes

  include Introspectable
  include BackgroundedPolling
  include ValidationTier
  include ActionView::Helpers::TranslationHelper

  belongs_to :business, :inverse_of => :it_monitored_computers

  before_validation :_defaults, :if => :new_record?

  validates :business_id, :presence => true
  validates :name, :presence => true
  validates :hostname, :presence => true

  attr_accessible :name, :hostname, :active

  scope :by_business, lambda { |id| where('business_id = ?', id) }
  scope :live, lambda { where('active = ?', true) }
  scope :missing, lambda { live.where('missing = ? AND last_heartbeat_received_at < ?', false, Time.now - HEARTBEAT_PERIOD) }
  # last_heartbeat_received_at is null OR

  introspect do
    can :destroy, :enabler => nil

    attr :name
    attr :hostname
    attr :active
    group do
      attr :last_result, :read_only
      attr :last_polled_at, [:read_only, :datetime]
    end
    attr :last_error, [:read_only]

    action :refresh, :type => :basic
  end

  def self.detect_missing!
    missing.find_each do |mc|
      mc.missing = true
      mc.save!
      # notify business, or something. s.poll!
    end
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
    self.missing = false if missing.nil?
  end

end
