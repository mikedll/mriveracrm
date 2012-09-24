
CarrierWave.configure do |config|

  s3store = YAML.load( File.read(Rails.root.join('config', 's3store.yml')))[Rails.env]

  config.fog_credentials = {
    :provider               => 'AWS',       # required
    :aws_access_key_id      => ENV['AMAZON_ACCESS_KEY_ID'],
    :aws_secret_access_key  => ENV['AMAZON_SECRET_ACCESS_KEY'],       # required
    :region                 => 'eu-west-1'  # optional, defaults to 'us-east-1'
  }
  config.fog_directory  = s3store['bucket']
  # config.fog_public     = false                                   # optional, defaults to true
  # config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}
  # config.asset_host     = 'https://assets.example.com'            # optional, defaults to nil
end
