class PaymentGatewayProfile < ActiveRecord::Base
  belongs_to :payment_gateway_profilable, polymorphic: true
  has_many :transactions

  after_create :_create_remote

  attr_accessor :last_error, :card_number, :expiration_month, :expiration_year, :cv_code

  def card_from_opts(opts)
    ActiveMerchant::Billing::CreditCard.new({
                                              :month => opts[:expiration_month].to_i,
                                              :year => "20#{opts[:expiration_year]}".to_i,
                                              :number => opts[:card_number],
                                              :verification_value => opts[:cv_code]
                                            }.merge(payment_gateway_profilable.payment_profile_profilable_card_args))
  end

  def card_valid?(card)
    card.validate
    if !card.valid?
      lookup = {:month => :expiration_month, :year => :expiration_year, :number => :card_number, :verification_value => :cv_code}
      card.errors.each do |k,es|
        es.each { |e| errors.add(lookup[k.to_sym] ? lookup[k.to_sym] : k, e) }
      end
      return false
    end

    true
  end

  def card_prompt
    card_last_4.blank? ? "No card on file" : "#{card_brand.camelize} ending in #{card_last_4}"
  end

  def pay_invoice!(invoice)
    raise "Implement in subclass."
  end

  protected 

  def _create_remote
    raise "Implement in subclass."
  end

end

