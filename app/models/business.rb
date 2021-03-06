class Business < ActiveRecord::Base

  include Introspectable
  include ActionView::Helpers::TranslationHelper

  #
  # The current business in use in the global request.
  #
  cattr_accessor :current

  has_many :projects
  has_many :users, :dependent => :destroy
  has_many :credentials # used validations in credential. destroyed by users, not here.

  has_many :clients, :dependent => :destroy
  has_many :products, :dependent => :destroy
  has_many :employees, :dependent => :destroy

  has_many :invitations, :dependent => :destroy
  has_many :images, :dependent => :destroy
  has_many :lifecycle_notifications, :dependent => :destroy
  has_many :notifications, :dependent => :destroy, :inverse_of => :business
  has_many :letters, :dependent => :destroy, :inverse_of => :business
  has_many :pages, :dependent => :destroy, :inverse_of => :business
  has_many :link_orderings, :dependent => :destroy, :inverse_of => :business

  has_one :usage_subscription, :dependent => :destroy
  has_many :it_monitored_computers, :inverse_of => :business, :dependent => :destroy, :class_name => 'IT::MonitoredComputer'

  belongs_to :default_mfe, :class_name => "MarketingFrontEnd"

  before_validation :_defaults_on_create, :if => :new_record?
  before_validation :_find_default_mfe, :if => :new_record?
  before_validation :_format_fields

  validates :default_mfe_id, :presence => true
  validates :handle, :presence => true
  validates :handle, :length => { :minimum => 3 }, :allow_blank => true
  validates :handle, :format => { :with => Regexes::BUSINESS_HANDLE, :message => I18n.t('business.errors.handle_format')}, :allow_blank => true

  validates :handle, :allow_blank => true, :uniqueness => true

  validates :host, :uniqueness => true, :allow_blank => true, :format => { :with => Regexes::HOST }

  validate :_no_mfe_conflict

  after_create :_have_usage_subscription

  scope :with_features, lambda { joins(:usage_subscription => :features).includes(:usage_subscription => :features) }

  attr_accessible :name, :phone, :address1, :address2, :city, :state, :zip, :email

  introspect do
    can :destroy, :confirm => t('business.confirm_delete')

    attr :name
    group do
      attr :stripe_secret_key
      attr :stripe_publishable_key
    end
    group do
      attr :google_oauth2_client_id
      fmore :hint => t('business.oauth2_fields')

      attr :google_oauth2_client_secret
    end

    attr :it_monitored_computers_key, :read_only
    fmore :label => "Monitored computers API key"

    attr :phone
    attr :address1
    attr :address2
    attr :city
    attr :state
    attr :zip
    attr :email

    attr :splash_html
    fmore :label => "Homepage splash text", :as => :text

    action :regenerate_monitored_computers_api_key, :confirm => t('business.confirm_regenerate_it_monitored_computers_api_key')
  end

  # attr_accessible :name, :stripe_secret_key, :stripe_publishable_key, :google_oauth2_client_id, :google_oauth2_client_secret, :authorizenet_payment_gateway_id, :api_login_id, :transaction_key, :test

  def self.all
    raise "Should not call this on production." if Rails.env.production?
    super
  end

  def self.expire_client_information_when_dormant!
    find_each do |b|
      b.clients.without_active_users.each do |c|
        c.handle_inactive!
      end

      b.clients.with_dormant_payment_info.each do |c|
        c.handle_inactive_payment_info!
      end
    end
  end

  def reload
    super
    @an_owner = nil
  end

  def active_plan?
    usage_subscription.active_plan?
  end

  def supports?(*names)
    names.all? do |name|
      usage_subscription.features.any? { |f| f.name == name }
    end
  end

  def active_and_supports?(name)
    active_plan? && supports?(name)
  end


  def invite_employee(email)
    employee = employees.find_by_email(email)
    if employee.nil?
      employee = employees.build
      employee.email = email
      employee.save!
    end

    invitation = self.invitations.build
    invitation.email = email
    invitation.employee = employee
    invitation.save!
    invitation
  end

  def invite_client(email)
    client = clients.find_by_email(email)
    if client.nil?
      client = clients.build
      client.email = email
      client.save!
    end
    client.invite
  end

  def projects_for_gallery
    projects.map do |p|
      {
        :title => p.title,
        :tech => p.tech,
        :desc => p.description,
        :images => p.images
      }.merge(p.images.count == 0 ? {} : {
                :thumb => p.images.first.data.thumb.url,
                :medium => p.images.first.data.large.url,
                :small => p.images.first.data.small.url
              })
    end
  end

  def an_owner
    return @an_owner if @an_owner
    e = employees.is_owner.first
    @an_owner = e.user if e
  end

  def acquire_default_features!
    self.usage_subscription.features = default_mfe.features.all
    self.usage_subscription.save!
  end

  def default_url_host
    host.blank? ? default_mfe.host : host
  end

  def has_some_address?
    !address1.blank? || !address2.blank? || !city.blank? || !state.blank? || !zip.blank? || !email.blank?
  end

  def has_tail_address?
    !city.blank? || !state.blank? || !zip.blank?
  end

  def lifecycle_deliver!(identifier, mail)
    ln = lifecycle_notifications.build(:identifier => identifier, :body => mail.body.to_s)
    ln.save!
    mail.deliver!
  end

  def notification_deliver!(identifier, mail)
    n = notifications.build(:identifier => identifier,
                            :to => mail.to.join(', '),
                            :from => mail.from.join(', '),
                            :subject => mail.subject,
                            :body => mail.body.to_s)
    n.save!
    mail.deliver!
  end

  def generate_it_monitored_computers_key
    self.it_monitored_computers_key = SecureRandom.hex(16)
  end

  def cycle_it_monitored_computers_key
    generate_it_monitored_computers_key
    save
  end

  private

  def _format_fields
    self.handle.strip!
    self.handle.downcase!

    self.host.strip!
    self.host.downcase!
  end

  def _defaults_on_create
    generate_it_monitored_computers_key if it_monitored_computers_key.blank?
  end

  def _find_default_mfe
    # can be improved...try actually setting one in a controller. or, set a primary
    # mfe for the system.
    self.default_mfe = MarketingFrontEnd.first if !default_mfe
  end

  def _no_mfe_conflict
    errors.add(:host, I18n.t('business.mfe_host_conflict')) if MarketingFrontEnd.find_by_host host
  end

  def _have_usage_subscription
    self.usage_subscription = UsageSubscription.new
    self.usage_subscription.features = default_mfe.features.all
    self.usage_subscription.save!
  end


end
