# encoding: utf-8

class ImageUploader < CarrierWave::Uploader::Base

  include CarrierWave::RMagick
  include UploaderFilenames

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

  def extension_white_list
    %w(jpg jpeg gif png)
  end

end
