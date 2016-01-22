class LinkOrdering < ActiveRecord::Base

  include Introspectable

  belongs_to :business, :inverse_of => :link_orderings

  before_validation :_defaults_on_create, :if => :new_record?

  validates :business_id, :presence => true
  validates :priority, :numericality => { :only_integer => true }
  validates :referenced_link, :presence => true, :uniqueness => { :scope => :business_id }

  attr_accessible :priority, :title

  introspect do
    attr :referenced_link, :hidden
    attr :title
    attr :priority
  end

  DEFAULTS = {
    :home => {
      :priority => 1,
      :title => "Home"
    },
    :products => {
      :priority =>2,
      :title => "Products"
    },
    :contact_home => {
      :priority => 3,
      :title => "Contact"
    }
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
    missing = defaults.keys.select { |k| !los.any? { |r| r.referenced_link == k.to_s } }
    los += missing.map do |m|
      lo = LinkOrdering.new(:priority => defaults[m][:priority], :title => defaults[m][:title] )
      lo.referenced_link = m.to_s
      lo
    end
    los
  end

  def _defaults_on_create
    self.priority = (self.class.defaults[referenced_link] || 4) if priority.nil?
  end

end
