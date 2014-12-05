class BetaTester < ActiveRecord::Base

  before_validation :_format_fields

  def _format_fields
    self.email.strip!
    self.email.downcase!
  end

end
