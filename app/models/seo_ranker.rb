class SEORanker < ActiveRecord::Base

  module SearchEngines
    GOOGLE = 'Google'
  end

  SEARCH_ENGINES = SearchEngines.constants.map { |c| SearchEngines.const_get(c) }

  attr_accessible :search_phrase, :search_engine, :name

  belongs_to :business, :inverse_of => :seo_rankers

  before_validation :_defaults, :if => :new_record?

  validates :business_id, :presence => true
  validates :name, :presence => true
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

  def rank_background
    self.runs_since_window_started += 1
    self.ranking = 3
    save!
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
