require 'cgi'

class ODeskLister < ActiveRecord::Base

  include BackgroundedPolling
  include ValidationTier
  include ActionView::Helpers::TranslationHelper

  RANKING_REQUEST = 'ranking'

  attr_accessible :search_phrase, :name, :host_to_match, :active
  attr_accessor :last_result_halted_poll

  belongs_to :business, :inverse_of => :odesk_listers

  before_validation :_defaults, :if => :new_record?

  validation_tier do |t|
    t.validates :business_id, :presence => true
  end

  validation_tier do |t|
    t.validates :name, :presence => true
    t.validates :host_to_match, :presence => true
  end

  scope :by_business, lambda { |id| where('business_id = ?', id) }

  def target_endpoint
    "http://www.google.com/search"
  end

  def before_poll
    self.matching_url = ""
    self.matching_title = ""
    self.ranking = 0
  end

  def params_for_poll_request(n)
    q_params = { :q => search_phrase }
    q_params.merge!(:start => n * per_search) if n >= 2
    q_params
  end

  def handle_poll_result(result)
    doc = Nokogiri::HTML(result)
    doc.css('#search li.g').each_with_index do |li_node, page_offset|
      a_node = li_node.css('a').first
      if a_node
        url_found = a_node['href']

        if url_found !~ Regexes::PROTOCOL
          # asssuming google embedded the url in 'q' param
          url_found = "http://www.dummydomain.com/#{url_found}"
          google_uri = URI(url_found)
          url_found = CGI::parse(google_uri.query)['q'].first
        end

        begin
          uri = URI(url_found)
        rescue => e
          if e.message.include?("bad argument (expected URI object or URI string)")
            # for later debugging.
            # puts "Found bad url in: #{url_found} from #{a_node.to_s}"
            raise
          end
        end
        if uri.host =~ Regexp.new("#{Regexp.escape(host_to_match)}\\z")
          self.matching_url = url_found
          self.matching_title = a_node.text()
          self.ranking = (GOOGLE_RESULTS_PER_SEARCH * (runs - 1)) + (page_offset + 1)
          self.last_result_halted_poll = true
        end
      end
    end
  end

  protected

  def _defaults
    self.host_to_match = business.host if host_to_match.blank? && business
    reset_polling_window
  end

end
