class PaymentGatewayProfile < ActiveRecord::Base
  belongs_to :client

  after_create :_create_remote

  def pay_invoice!(invoice)
    return false if self.can_make_payments?

    t = transaction.new(:customer_profile_id => self.vendor_id, :amount => invoice.amount)
    t.begin!
    result = t.process
    if result[:success]
      t.succeed!
    else
      t.fail!
    end
  end

  def _create_remote
    raise "Implement in subclass."
  end

end

