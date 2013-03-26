class PaymentGatewayProfile < ActiveRecord::Base
  belongs_to :client
  has_many :transactions

  after_create :_create_remote

  attr_accessor :last_error, :card_number, :expiration_month, :expiration_year, :cv_code

  def card_prompt
    card_last_4.blank? ? "No card on file" : "#{card_brand.camelize} ending in #{card_last_4}"
  end

  def pay_invoice!(invoice)
    raise "Implement in subclass."
  end

  def _create_remote
    raise "Implement in subclass."
  end

end

