require 'active_support/concern'

module UploaderFilenames
  extend ActiveSupport::Concern

  included do
    # Choose what kind of storage to use for this uploader:
    storage (Rails.env.production? ? :fog : :file)

    # saving this in case we want it later...to recover from the sea of uuids were making.
    before :cache, :save_original_filename

    # future image updates give new UUID to burst caches in CDN....or do we not want this,
    # for allowing users to make publically viewable versions? we'll keep it for now.
    before :cache, :reset_unique_id    
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    prefix = (Rails.env.test? ? 'test/' : '')
    "#{prefix}uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def cache_dir
    prefix = (Rails.env.test? ? 'test/' : '')
    "#{prefix}uploads/tmp"
  end

  def filename
    attrname = "#{mounted_as}_unique_id".to_sym
    if original_filename
      if model.read_attribute(attrname)
        # versions will go though here and, being linked to the same model,
        # find the uuid already made. theyll skip regeneration.
        model.read_attribute(attrname)
      else
        # the master Uploader, in a cache call,
        # calls filename, and will find it nil, and so will reset it
        model.send "#{attrname}=".to_sym, "#{generate_unique_id}.#{file.extension}"
      end
    end
  end

  def reset_unique_id(file)
    model.send "#{mounted_as}_unique_id=".to_sym, nil
  end

  def generate_unique_id
    SecureRandom.uuid
  end

  def save_original_filename(file)
    attrname = "#{mounted_as}_original_filename".to_sym
    if model.read_attribute(attrname)
      model.read_attribute(attrname)
    else
      v = file.original_filename if file.respond_to?(:original_filename)
      model.send "#{attrname}=".to_sym, v
    end
  end


end
