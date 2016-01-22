class LinkOrdering < ActiveRecord::Base

  belongs_to :business, :inverse_of => :link_orderings

  before_validation :_defaults_on_create, :if => :new_record?

  validates :business_id, :presence => true
  validates :priority, :numericality => { :only_integer => true }
  validates :referenced_link, :uniqueness => true

  attr_accessible :referenced_link, :priority, :scope

  DEFAULTS = {
    :home => 1,
    :products => 2,
    :contact_home => 3
  }

  def self.defaults
    DEFAULTS
  end

  #
  # This add defaults if a query does not come up
  # with such results. Assumes LinkOrderings is a small-scale
  # table for a given business.
  #
  def self.with_defaults(los)
    missing = defaults.keys.select { |k| !los.any? { |r| r.referenced_link == k } }
    los += missing.map { |m| LinkOrdering.new(:referenced_link => m.to_s, :priority => defaults[m] ) }
    los
  end

  def _defaults_on_create
    self.priority = (self.class.defaults[referenced_link] || 4) if priority.nil?
  end

end
