class Invitation < ActiveRecord::Base

  belongs_to :business
  belongs_to :client

  scope :open, where('status = ?', :open)

  before_validation :_capture_client_email

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
    if client.nil?
      user.businesses.push(self.business)
    else
      user.clients.push(self.client)
    end
    user.save!
    accept!
  end

  private

  def _capture_client_email
    self.email = client.email if !client.nil? && email.blank?
  end


end
