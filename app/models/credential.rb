class Credential < ActiveRecord::Base

  belongs_to :user

  validates :email, :format => { :with => Regexes::EMAIL }

end
