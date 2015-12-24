require 'kramdown'

class Letter < ActiveRecord::Base

  include Introspectable

  belongs_to :business
  validates :business_id, :presence => true
  validates :title, :presence => true

  attr_accessible :title, :body

  introspect do
    nested_association :preview, :icon => 'icon-play'

    attr :title
    attr :body
    fmore :as => :text, :hint => "This will be processed with Markdown formatting rules. You can use %{addressee} to capture a client's addressee information as this letter is sent to many recipients."
  end

  def previewed
    c = Client.new(:first_name => "John", :last_name => "Doe")
    subbed = body.gsub('%{addressee}', c.addressee)
    Kramdown::Document.new(subbed).to_html
  end

end
