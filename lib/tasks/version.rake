

task :tag_version => [] do
  version_file = File.dirname(__FILE__) + "/../../config/version.rb"
  version = `git rev-parse HEAD`.split('\n').first.chomp
  code = <<-RUBY
module MikedllCrm
  VERSION = '#{version}'
end
RUBY

  File.open(version_file, 'w') do |f|
    f.write code
  end


end
