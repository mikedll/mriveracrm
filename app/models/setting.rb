class Setting < ActiveRecord::Base
  attr_accessible :key, :value, :value_type

  VALUE_TYPES = ["String", "Integer", "Boolean"]

  validates :key, :uniqueness => true
  validates :value_type, :inclusion => {  :in => VALUE_TYPES }

  def get
    case value_type
    when "Boolean"; then (!value_type.blank? && value_type != "false")
    when "Integer"; then value_type.to_i
    else; value_type # assume string
    end
  end

end
