class StatusMonitor
  def self.check_stripe(key)
    begin
      with_stripe_key(key) do
        count = Stripe::Customer.all(:count => 5)
      end
      return "Customers retrievable. Stripe seems to be working."
    rescue => e
      return "Stripe is not working. Received error while getting customer count: #{e.message}"
    end
  end

  def self.with_stripe_key(key)
    begin
      Stripe.api_key = key
      yield
    ensure
      Stripe.api_key = ""
    end
  end

end
