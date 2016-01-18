class LinkOrdering < ActiveRecord::Base

  belongs_to :business, :inverse_of => :link_orderings

  before_validation :_defaults_on_create, :if => :new_record?

  validates :business_id, :presence => true
  validates :priority, :numericality => { :only_integer => true }
  validates :referenced_link, :uniqueness => true

  DEFAULTS = {
    :home => 1,
    :products => 2,
    :contact_home => 3
  }

  def self.defaults
    DEFAULTS
  end

  def self.retrieval(top_scope = self)
  end

  def _defaults_on_create
    self.priority = (self.class.defaults[referenced_link] || 4) if priority.nil?
  end

end
