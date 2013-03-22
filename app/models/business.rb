class Business < ActiveRecord::Base

  has_many :users, :dependent => :destroy
  has_many :credentials # used validations in credential. destroyed by users, not here.

  cattr_accessor :current

  has_many :clients, :dependent => :destroy
  has_many :employees, :dependent => :destroy

  has_many :invitations, :dependent => :destroy

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

end
