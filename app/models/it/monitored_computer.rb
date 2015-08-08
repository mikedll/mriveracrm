class IT::MonitoredComputer < ActiveRecord::Base

  HEARTBEAT_PERIOD = 10.minutes
  module Alerts
    COMPUTER_DOWN = 'computer_down'
  end

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
  scope :missing, lambda { live.where('down = ? AND last_heartbeat_received_at < ?', false, Time.now - HEARTBEAT_PERIOD) }
  scope :down, lambda { live.where('down = ?', true) }
  scope :with_business, lambda { joins(:business).includes(:business) }
  # last_heartbeat_received_at is null OR

  introspect do
    can :destroy, :enabler => nil

    attr :name
    attr :hostname
    attr :active
    group do
      attr :last_result, :read_only
      attr :last_heartbeat_received_at, [:read_only, :datetime]
    end
    attr :last_error, [:read_only]

    action :refresh, :type => :basic
  end

  def self.detect_missing!
    with_business.missing.each do |mc|
      mc.down = true
      mc.save!
      mail = AlertMailer.computer_down(mc.business, mc)
      mc.business.notification_deliver!(Alerts::COMPUTER_DOWN, mail)
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
    self.down = false if down.nil?
  end

end
