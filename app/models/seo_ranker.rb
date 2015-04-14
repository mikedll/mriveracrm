class SeoRanker < ActiveRecord::Base

  module SearchEngines
    GOOGLE = 'Google'
  end

  SEARCH_ENGINES = SearchEngines.constants.map { |c| SeoRanker::SearchEngines.const_get(c) }

  belongs_to :business

  before_validation :_defaults, :if => :new_record?

  validates :name, :presence => true
  validates :search_phrase, :presence => true, :length => { :minimum => 3 }
  validates :search_engine, :presence => true, :inclusion => { :in => SEARCH_ENGINES }

  MAX_RUNS_PER_WINDOW = 10

  def runnable?
    runs_since_window_started < MAX_RUNS_PER_WINDOW
  end

  def rank!
    return if !runnable?
  end

  def rank_remote
    self.ranking = 3
  end

  def reset_window
    self.last_window_started_at = Time.now
    self.runs_since_window_started = 0
  end

  protected

  def _defaults
    self.search_engine = SearchEngines::GOOGLE if search_engine.blank?
    reset_window
  end

end
