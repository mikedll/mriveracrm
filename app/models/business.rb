class Business < ActiveRecord::Base

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
  has_one :usage_subscription, :dependent => :destroy

  before_validation :_format_handle

  validates :handle, :presence => true
  validates :handle, :length => { :minimum => 3 }, :allow_blank => true
  validates :handle, :format => { :with => Regexes::BUSINESS_HANDLE, :message => I18n.t('business.errors.handle_format')}, :allow_blank => true

  validates :handle, :allow_blank => true, :uniqueness => true

  validates :host, :uniqueness => true, :allow_blank => true

  validate :_no_mfe_conflict

  # attr_accessible :name, :stripe_secret_key, :stripe_publishable_key, :google_oauth2_client_id, :google_oauth2_client_secret, :authorizenet_payment_gateway_id, :api_login_id, :transaction_key, :test

  def self.all
    raise "Should never be calling this in prod." if Rails.env.production?
    super
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


  private

  def _format_handle
    self.handle.strip!
    self.handle.downcase!
  end

  def _no_mfe_conflict
    errors.add(:host, I18n.t('business.mfe_host_conflict')) if MarketingFrontEnd.find_by_host host
  end


end
