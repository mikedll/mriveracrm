# encoding: utf-8

class ImageUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  include CarrierWave::RMagick
  # include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage (Rails.env.production? ? :fog : :file)

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

  # saving this in case we want it later...to recover from the sea of uuids were making.
  before :cache, :save_original_filename

  # future image updates give new UUID to burst caches in CDN....or do we not want this,
  # for allowing users to make publically viewable versions? we'll keep it for now.
  before :cache, :reset_unique_id

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

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Create different versions of your uploaded files:
  version :large do
    process :resize_to_fill => [900, 750]
  end

  version :medium do
    process :resize_to_fill => [600, 500]
  end

  version :small do
    process :resize_to_fill => [360, 300]
  end

  version :thumb do
    process :resize_to_fill => [160, 133]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

end
