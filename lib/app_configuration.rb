class AppConfiguration

  def self.config
    return @config if @config
    @config = {
      # :google_oauth2_scope => 'userinfo.email,userinfo.profile,https://mail.google.com/mail/feed/atom,https://www.google.com/m8/feeds/'
      :google_oauth2_scope => 'userinfo.email,userinfo.profile'
    }

    config = {}
    (defined?(Rails) ? Rails.root : Bundler.root).tap do |root|
      config = if File.exists? root.join('config', 'credentials.yml')
                 YAML.load( File.read( root.join('config', 'credentials.yml'))).with_indifferent_access 
               else
                 {}
               end
    end
    @config.merge!(config)
  end

  def self.get(path)
    cur = config
    path.to_s.split('.').each do |segment|
      cur = cur[segment.force_encoding('UTF-8').to_s] if cur
    end

    # retry, this time with env prefix.
    if cur.nil?
      cur = config[Rails.env]
      path.to_s.split('.').each do |segment|
        cur = cur[segment.force_encoding('UTF-8').to_s] if cur
      end
    end

    if cur.nil?
      cur = ENV[path]
    end

    cur
  end
end
