class StatusMonitor
  def self.check_stripe
    begin
      count = Stripe::Customer.all(:count => 5)
      return "Customers retrievable. Stripe seems to be working."
    rescue => e
      return "Stripe is not working. Received error while getting customer count: #{e.message}"
    end
  end
end
