class OutsideTransaction < Transaction

  OUTSIDE_VENDORS = ['Bank Wire', 'Paypal', 'Venmo', 'Stripe', 'Braintree', 'Chargify', 'Cash', 'Check']

  validates :outside_id, :presence => true, :if => Proc.new { |r| !r.open? && r.outside_vendor != 'Cash' }
  validates :outside_vendor, :presence => true, :inclusion => OUTSIDE_VENDORS

  before_validation :_default_vendor
  before_validation { :_strip_outside_transaction_fields }

  def _default_vendor
    self.outside_vendor = OUTSIDE_VENDORS.first if self.outside_vendor.blank?
  end

  def _strip_outside_transaction_fields
    self.vendor_id.strip!
    self.outside_vendor.strip!
  end

end
