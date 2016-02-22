class PaymentGatewayProfile < ActiveRecord::Base

  include PersistentRequestable

  belongs_to :payment_gateway_profilable, polymorphic: true, inverse_of: :payment_gateway_profile
  has_many :transactions

  after_create :_create_remote

  attr_accessor :card_number, :expiration_month, :expiration_year, :cv_code

  TRIAL_DURATION = 30.days

  module Status
    TRIALING = 'trialing'
    ACTIVE = 'active'
    PAST_DUE = 'past_due'
    CANCELLED = 'canceled'
    UNPAID = 'unpaid'
  end


  def self.card_virtual_attributes
    [:card_number, :expiration_month, :expiration_year, :cv_code]
  end

  def active_plan?
    raise "Implement in subclass."
  end

  def card_from_options(options)
    ActiveMerchant::Billing::CreditCard.new({
                                              :month => options[:expiration_month].to_i,
                                              :year => "20#{options[:expiration_year]}".to_i,
                                              :number => options[:card_number],
                                              :verification_value => options[:cv_code]
                                            }.merge(payment_gateway_profilable.payment_profile_profilable_card_args))
  end

  EXCLUDED_CARD_KEY_ERRORS = ['brand']
  def card_valid?(card)
    card.validate
    if !card.valid?
      lookup = {:month => :expiration_month, :year => :expiration_year, :number => :card_number, :verification_value => :cv_code}
      card.errors.each do |k,es|
        es.each { |e| errors.add(lookup[k.to_sym] ? lookup[k.to_sym] : k, e) if !EXCLUDED_CARD_KEY_ERRORS.any? { |excluded| excluded == k } }
      end
      return false
    end

    true
  end

  def card_prompt
    card_last_4.blank? ? "No card on file" : "#{card_brand.camelize} ending in #{card_last_4}"
  end

  def pay_invoice!(amount, description)
    raise "Implement in subclass."
  end

  def remote_status
    raise "Implement in subclass."
  end

  #
  # Used for expiring an inactive user's information.
  #
  def erase_sensitive_information!
    raise "Implement in subclass."
  end

  #
  # returns nil or Datetime
  #
  def trial_ends_at
    raise "Implement in subclass."
  end

  def trialing?
    !trial_ends_at.nil? && trial_ends_at > Time.zone.now
  end

  protected

  def _create_remote
    raise "Implement in subclass."
  end

end

