
namespace :assets do


  desc "Deploy assets to prod - uses Rails.env or the FIRST selected heroku app"
  task :deploy => [:environment, 'assets:precompile'] do

    require 'aws/s3'

    environment = @environment_config || Rails.env
    s3_config = YAML.load( File.read( Rails.root.join("config", "cloudfront.yml") ) )[environment.to_s]
    AWS::S3::Base.establish_connection!(
                                        :access_key_id     => ENV['AMAZON_ACCESS_KEY_ID'],
                                        :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY']
                                        )

    puts "Connected to S3..."      
    bucket = AWS::S3::Bucket.find s3_config['bucket']
    s3_upload_directory Rails.root.join("public"), bucket

    Rake::Task['assets:clean'].execute
  end


  def s3_upload_directory(upload_target, bucket)
    number_uploaded = 0

    puts "Uploading #{upload_target} to #{bucket.name}"

    uploadable = Dir.glob(upload_target.join("**", "*")).select { |f| !File.directory?(f) }.map(&:to_s)
    uploadable.each do |file|
      number_uploaded += 1 if s3_update_asset( bucket, file, :access => :public_read )
    end

    puts "Uploaded #{number_uploaded}, Skipped #{uploadable.length - number_uploaded}"

    live_keys = uploadable.map{ |file| s3_key_for file }
    deleted = 0
    to_delete = bucket.objects.select { |obj| !live_keys.include? obj.key }
    puts "Found #{to_delete.count} object(s) to delete."
    to_delete.each do |obj|
      obj.delete 
      puts "Deleting #{obj.key} from S3"
      deleted += 1
    end

    puts "Deleted #{deleted} stale objects from S3"
  end

  def s3_key_for(file_path)
    @root_path_length ||= Rails.root.join("public").to_s.length + "/".length
    relative_to_public = file_path[ @root_path_length, file_path.length]
    relative_to_public
  end

  def s3_update_asset( bucket, file_path, options = {} )
    key = s3_key_for( file_path )
    return false if !bucket[key].nil?

    AWS::S3::S3Object.store( key,
                             File.open(file_path),
                             bucket.name,
                             options )
    puts "S3 Uploaded: #{key}"
    true
  end

end

