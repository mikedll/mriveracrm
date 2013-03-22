class Invitation < ActiveRecord::Base

  belongs_to :business
  belongs_to :employee
  belongs_to :client

  scope :cb, lambda { where('invitations.business_id = ?', Business.current.try(:id)) }
  scope :open, where('invitations.status = ?', :open)

  before_validation :_capture_client_email

  validate :_employee_or_contact
  validates :email, :format => { :with => Regexes::EMAIL }

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
      user = user.employee = employee
    else
      raise "Nonsensical invitation. Neither employee nor client relationship."
    end
    user.save!
    accept!
  end

  private

  def _employee_or_contact
    errors.add(:base, I18n.t('invitation.errors.only_one')) if (employee.nil? && client.nil?) || (!employee.nil? && !client.nil?)
  end

  def _capture_client_email
    self.email = client.email if !client.nil? && email.blank?
  end


end
