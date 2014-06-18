class Invitation < ActiveRecord::Base

  include ActionView::Helpers::TranslationHelper

  belongs_to :business
  belongs_to :employee
  belongs_to :client

  scope :cb, lambda { where('invitations.business_id = ?', Business.current.try(:id)) }
  scope :handled, where("invitations.business_id is null and invitations.handle <> ''")
  scope :open, where('invitations.status = ?', :open)

  before_validation :_strip_fields
  before_validation { @virtual_path = 'invitation' }
  before_validation :_capture_client_email
  before_validation :_capture_business

  validate :_employee_or_client_or_handle
  validates :email, :presence => true
  validates :email, :format => { :with => Regexes::EMAIL }, :allow_blank => true
  validate :_no_email_conflict, :if => lambda { |i| !i.email.blank? }
  validates :business_id, :presence => true, :if => lambda { |i| i.handle.blank? }

  attr_accessible :email, :handle 
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
    elsif !handle.blank?
      user.become_owner_of_new_business(handle)
    else
      raise "Nonsensical invitation. Neither employee nor client relationship."
    end

    return false if !user.save
    accept!
  end

  private

  def _employee_or_client_or_handle
    if handle.blank?
      errors.add(:base, I18n.t('invitation.errors.only_one')) if (employee.nil? && client.nil?) || (!employee.nil? && !client.nil?)
    else
      errors.add(:base, I18n.t('invitation.errors.no_client_or_employee_for_handle')) if !(employee.nil? && client.nil?)
    end
  end

  def _strip_fields
    self.handle.strip!
    self.email.strip!
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
    return if !self.open?

    if handle.blank? && self.business
       if self.business.users.where(:email => self.email).first
        errors.add(:email, t('.errors.email_conflict'))
      end
    else
      finder = Invitation.open.handled.where(:email => self.email, :handle => self.handle)
      if persisted?
        finder = finder.where('id <> ?', self.id)
      end
      errors.add(:email, t('.errors.email_conflict')) if finder.first
    end
  end


end
