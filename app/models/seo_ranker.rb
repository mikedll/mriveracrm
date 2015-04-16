require 'cgi'

class SEORanker < ActiveRecord::Base

  include ValidationTier
  include ActionView::Helpers::TranslationHelper

  module SearchEngines
    GOOGLE = 'Google'
  end

  SEARCH_ENGINES = SearchEngines.constants.map { |c| SearchEngines.const_get(c) }

  attr_accessible :search_phrase, :search_engine, :name, :host_to_match, :active

  belongs_to :business, :inverse_of => :seo_rankers

  before_validation :_defaults, :if => :new_record?

  validation_tier do |t|
    t.validates :business_id, :presence => true
  end

  validation_tier do |t|
    t.validate :_limit_seo_rankers, :if => :new_record?
  end

  validation_tier do |t|
    t.validates :name, :presence => true
    t.validates :host_to_match, :presence => true
    t.validates :search_phrase, :presence => true, :length => { :minimum => 3 }
    t.validates :search_engine, :presence => true, :inclusion => { :in => SEARCH_ENGINES }
  end

  WINDOW_DURATION = 3.days

  scope :by_business, lambda { |id| where('business_id = ?', id) }
  scope :resettable, lambda { where('last_window_started_at < ?', Time.now - WINDOW_DURATION) }
  scope :live, lambda { where('active = ?', true) }
  scope :not_run_this_window, lambda { where('runs_since_window_started = ?', 0) }

  MAX_RUNS_PER_WINDOW = 10

  class Worker < WorkerBase
  end

  def self.reset_windows!
    resettable.find_each do |s|
      s.reset_window
      s.save!(:validate => false)
    end
  end

  def self.run_live!
    live.not_run_this_window.find_each do |s|
      s.rank!
    end
  end

  def valid_to?(n)
    validation_level >= 0
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
    self.last_ranked_at = nil
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
            url_found = a_node['href']

            if url_found !~ Regexes::PROTOCOL
              # asssuming google embedded the url in 'q' param
              url_found = "http://www.dummydomain.com/#{url_found}"
              google_uri = URI(url_found)
              url_found = CGI::parse(google_uri.query)['q'].first
            end

            uri = URI(url_found)
            if uri.host =~ Regexp.new("#{Regexp.escape(host_to_match)}\\z")
              self.matching_url = url_found
              self.matching_title = a_node.text()
              self.ranking = (GOOGLE_RESULTS_PER_SEARCH * (runs - 1)) + (page_offset + 1)
              self.last_ranked_at = Time.now
              break
            end
          end
        end
      rescue => e
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
    self.host_to_match = business.host if host_to_match.blank? && business
    reset_window
  end

  MAX_SEO_RANKERS = 10
  def _limit_seo_rankers
    errors.add(:base, t('seo_ranker.errors.max', :max => MAX_SEO_RANKERS)) if self.class.by_business(business_id).count >= MAX_SEO_RANKERS
  end

end
