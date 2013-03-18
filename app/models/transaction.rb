class Transaction < ActiveRecord::Base
  belongs_to :invoice
  belongs_to :payment_gateway_profile

  state_machine :status, :initial => :open do

    event :begin do
      transition [:open] => [:pending]
    end

    event :fail do
      transition [:pending] => [:failed]
    end

    event :succeed do
      transition [:pending] => [:successful]
    end
  end

end

