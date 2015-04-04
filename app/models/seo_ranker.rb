class SeoRanker
  include ActiveModel::Serializers::JSON
  self.include_root_in_json = false

  attr_accessor :results

  def rank!
    self.results = "Here is something."
  end

  def attributes
    { 'results' => nil }
  end

end
