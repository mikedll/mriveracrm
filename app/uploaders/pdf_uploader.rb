# encoding: utf-8

class PdfUploader < CarrierWave::Uploader::Base
  include UploaderFilenames

  def extension_white_list
    %w(pdf)
  end

end
