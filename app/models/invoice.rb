class Invoice < ActiveRecord::Base
  has_many :authorize_net_transactions

  def charge!
    self.client.payment_gateway_profile.pay!(self)
  end

end
