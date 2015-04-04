class SeoRanker
  include ActiveModel::Serializers::JSON

  attr_accessor :results

  def rank!
  end

  def attributes
    { 'results' => nil }
  end

end
