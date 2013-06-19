class Invitation < ActiveRecord::Base

  include ActionView::Helpers::TranslationHelper

  belongs_to :business
  belongs_to :employee
  belongs_to :client

  scope :cb, lambda { where('invitations.business_id = ?', Business.current.try(:id)) }
  scope :open, where('invitations.status = ?', :open)

  before_validation { @_virtual_path = 'invitation' }
  before_validation :_capture_client_email
  before_validation :_capture_business
  before_validation :_no_email_conflict

  validates :business_id, :presence => true
  validate :_employee_or_client
  validates :email, :format => { :with => Regexes::EMAIL }

  attr_accessible :email
  state_machine :status, :initial => :open do
    event :accept do
      transition [:open] => :accepted
    end

    event :decline do
      transition [:open] => :declined
    end
  end

  def accept_user!(user)
    if client
      user.client = client
    elsif employee
      user.employee = employee
    else
      raise "Nonsensical invitation. Neither employee nor client relationship."
    end
    return false if !user.save
    accept!
  end

  private

  def _employee_or_client
    errors.add(:base, I18n.t('invitation.errors.only_one')) if (employee.nil? && client.nil?) || (!employee.nil? && !client.nil?)
  end

  def _capture_client_email
    self.email = client.email if !client.nil? && email.blank?
  end

  def _capture_business
    if business.nil?
      if !client.nil?
        self.business = client.business
      elsif !employee.nil?
        self.business = employee.business
      end
    end
  end

  def _no_email_conflict
    if self.business.users.where(:email => self.email).first
      errors.add(:email, t('.errors.email_conflict'))
    end
  end


end
