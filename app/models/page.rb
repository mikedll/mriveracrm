class Page < ActiveRecord::Base

  include Introspectable

  belongs_to :business, :inverse_of => :pages

  before_validation :_clean
  before_validation :_defaults_on_create, :if => :new_record?
  before_validation :_compile
  before_validation :_slugify

  validates :business_id, :presence => true
  validates :slug, :uniqueness => { :scope => :business_id }

  attr_accessible :title, :slug, :body, :active

  introspect do
    can :destroy

    group do
      attr :title
      attr :slug, [:read_only, :string]
      attr :active
    end

    attr :body, :text
    attr :compiled_body, :read_only
  end

  scope :active, -> { where('active = ?', true) }

  def _compile
    self.compiled_body = Kramdown::Document.new(body).to_html
  end

  def _clean
    self.title.strip!
  end

  def _slugify
    self.slug = title.downcase.gsub(/[^a-zA-Z0-9 _\t\n]/, '').gsub(/\s+/, '-').dasherize
  end

  def _defaults_on_create
    self.active = true
  end

end
