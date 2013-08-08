class ProductImage < ActiveRecord::Base

  belongs_to :product
  belongs_to :image

  include ActionView::Helpers::TranslationHelper

  attr_accessible :active, :primary

  scope :primary, where('product_images.primary = ?', true)

  before_validation :_primary_implies_active
  before_save :_only_one_primary

  def _primary_implies_active
    if (primary_changed? || new_record?) && primary?
      self.active = true
    elsif active_changed? && !active?
      self.primary = false
    end
  end

  def _only_one_primary
    if (primary_changed? || new_record?) && primary?
      old_primaries = self.product.product_images.primary.all
      if !old_primaries.empty? && !old_primaries.all? { |pi| pi.update_attributes(:primary => false) }
        errors.add(:base, I18n.t('product_image.unable_to_force_unique_primary'))
        raise ActiveRecord::Rollback
      end
    end
  end

end
