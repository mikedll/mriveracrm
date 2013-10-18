
class PaymentGateway
  def self.authorizenet
    raise "Need to reimplement to use auth keys off of business"

    return @gateway if @gateway

    ActiveMerchant::Billing::Base.mode = :test if MikedllCrm::AUTHNET_TEST
    @gateway = ActiveMerchant::Billing::AuthorizeNetCimGateway.new(:login => "",
                                                                   :password => "",
                                                                   :test => "")

  end
end
