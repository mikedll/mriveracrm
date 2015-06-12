class It::Monitor < It::Base

  include BackgroundedPolling
  include ValidationTier
  include ActionView::Helpers::TranslationHelper

  belongs_to :business, :inverse_of => :it_monitors

  before_validation :_defaults, :if => :new_record?

  validates :business_id, :presence => true
  validates :name, :presence => true

  scope :by_business, lambda { |id| where('business_id = ?', id) }

  def handle_poll_result(result)
  end

  protected

  def _defaults
  end

end
