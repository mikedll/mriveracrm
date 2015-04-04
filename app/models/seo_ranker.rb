class SeoRanker
  include ActiveModel::Serializers::JSON

  attr_accessor :results

  def rank!
    self.results = "Here is something."
  end

  def attributes
    { 'results' => nil }
  end

end
