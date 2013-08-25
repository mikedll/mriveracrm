class Business < ActiveRecord::Base

  has_many :projects
  has_many :users, :dependent => :destroy
  has_many :credentials # used validations in credential. destroyed by users, not here.

  cattr_accessor :current

  has_many :clients, :dependent => :destroy
  has_many :products, :dependent => :destroy
  has_many :employees, :dependent => :destroy

  has_many :invitations, :dependent => :destroy
  has_many :images, :dependent => :destroy

  # attr_accessible :name, :stripe_secret_key, :stripe_publishable_key, :google_oauth2_client_id, :google_oauth2_client_secret, :authorizenet_payment_gateway_id, :api_login_id, :transaction_key, :test

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

end
