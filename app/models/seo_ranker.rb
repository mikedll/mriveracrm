require 'cgi'

class SEORanker < ActiveRecord::Base

  module SearchEngines
    GOOGLE = 'Google'
  end

  SEARCH_ENGINES = SearchEngines.constants.map { |c| SearchEngines.const_get(c) }

  attr_accessible :search_phrase, :search_engine, :name, :host_to_match

  belongs_to :business, :inverse_of => :seo_rankers

  before_validation :_defaults, :if => :new_record?

  validates :business_id, :presence => true
  validates :name, :presence => true
  validates :host_to_match, :presence => true
  validates :search_phrase, :presence => true, :length => { :minimum => 3 }
  validates :search_engine, :presence => true, :inclusion => { :in => SEARCH_ENGINES }

  MAX_RUNS_PER_WINDOW = 10

  class Worker < WorkerBase
  end

  def runnable?
    runs_since_window_started < MAX_RUNS_PER_WINDOW
  end

  def rank!
    return if !runnable?
    Worker.obj_enqueue(self, :rank_background)
  end

  GOOGLE_API = 'http://www.google.com/search'
  GOOGLE_RESULTS_PER_SEARCH = 10
  def rank_background
    self.matching_url = ""
    self.matching_title = ""
    self.last_error = ""
    self.ranking = 0

    runs = 0
    per_search = GOOGLE_RESULTS_PER_SEARCH
    while runs < MAX_RUNS_PER_WINDOW
      q_params = { :q => search_phrase }
      q_params.merge!(:start => runs * per_search) if runs >= 1

      result = nil
      begin
        runs += 1
        result = RestClient.get GOOGLE_API, :params => q_params
      rescue => e
        self.last_error = e.response
        break
      end

      begin
        doc = Nokogiri::HTML(result)
        doc.css('#search li.g').each_with_index do |li_node, page_offset|
          a_node = li_node.css('a').first
          if a_node
            google_uri = URI("http://www.example.com/#{a_node['href']}")
            url_found = CGI::parse(google_uri.query)['q'].first
            uri = URI(url_found)
            if uri.host =~ Regexp.new("\\A#{Regexp.escape(host_to_match)}\\z")
              self.matching_url = url_found
              self.matching_title = a_node.text()
              self.ranking = (GOOGLE_RESULTS_PER_SEARCH * (runs - 1)) + (page_offset + 1)
              break
            end
          end
        end
      rescue => e
        puts e.message
        self.last_error = I18n.t('seo_ranker.parse_error')
        break
      end
    end

    self.runs_since_window_started += runs
    save!
  end

  def reset_window
    self.last_window_started_at = Time.now
    self.runs_since_window_started = 0
  end

  protected

  def _defaults
    self.search_engine = SearchEngines::GOOGLE if search_engine.blank?
    self.host_to_match = business.host if host_to_match.blank?
    reset_window
  end

end
