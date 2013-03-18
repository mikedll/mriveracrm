
class PaymentGateway
  def self.authorizenet
    return @gateway if @gateway

    ActiveMerchant::Billing::Base.mode = :test if MikedllCrm::AUTHNET_TEST
    @gateway = ActiveMerchant::Billing::AuthorizeNetCimGateway.new(:login => MikedllCrm::AUTHNET_LOGIN, :password => MikedllCrm::AUTHNET_PASSWORD, :test => MikedllCrm::AUTHNET_TEST)

  end
end
