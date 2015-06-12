class It::Base < ActiveRecord::Base

  def self.table_name_prefix
    'it_'
  end

end
