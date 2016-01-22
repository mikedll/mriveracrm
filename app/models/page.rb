class Page < ActiveRecord::Base

  include Introspectable

  belongs_to :business, :inverse_of => :pages

  before_validation :_clean
  before_validation :_defaults_on_create, :if => :new_record?
  before_validation :_compile

  validates :business_id, :presence => true
  validates :slug, :uniqueness => { :scope => :business_id }
  validates :link_priority, :numericality => { :only_integer => true }

  attr_accessible :title, :slug, :body, :active, :link_priority, :is_stub

  introspect do
    can :destroy

    group do
      attr :title
      attr :slug, [:read_only, :string]
      attr :active
    end

    attr :link_priority
    attr :body, :text
    attr :compiled_body, :read_only
  end

  scope :active, -> { where('active = ?', true) }

  def self.new_stub(name, priority)
    new(:is_stub => true, :title => name, :link_priority => priority)
  end

  def _compile
    self.compiled_body = Kramdown::Document.new(body).to_html
    self.slug = title.downcase.gsub(/[^a-zA-Z0-9 _\t\n]/, '').gsub(/\s+/, '-').dasherize
  end

  def _clean
    self.title.strip!
  end

  def _defaults_on_create
    self.active = true
    self.link_priority = 4 if link_priority.nil?
  end

end
