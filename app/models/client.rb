class Client < ActiveRecord::Base

  belongs_to :business
  has_many :users
  has_many :invitations
  has_many :invoices
  has_one :authorize_net_customer_profile


  attr_accessible :first_name, :last_name, :email

  validates :business_id, :presence => true
  validates :email, :format => { :with => Regexes::EMAIL }, :uniqueness => { :scope => :business_id }

  validate :_static_business

  scope :cb, lambda { where('clients.business_id = ?', Business.current.try(:id)) }

  def _static_business
    if persisted? && business_id_changed?
      errors.add(:base, "cannot change business of client")
    end
  end

end
