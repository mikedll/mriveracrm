
class PaymentGateway
  def self.get
    @gateway ||= ActiveMerchant::Billing::AuthorizeNetCimGateway.new(:login => AUTHNET_LOGIN, :password => AUTHNET_PASSWORD)
  end
end
