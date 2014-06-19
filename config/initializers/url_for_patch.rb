module ActionDispatch::Routing::UrlFor
  def url_for(options = nil)
    case options
    when String
      options
    when nil, Hash
      opts = url_options
      options.merge!(:use_route => "bhandle_#{options[:use_route]}") if opts[:business_handle] && options[:use_route]
      _routes.url_for((options || {}).symbolize_keys.reverse_merge!(opts))
    else
      polymorphic_url(options)
    end
  end
end

# dunno why this didnt work.
# ActionDispatch::Routing::UrlFor.send :include, UrlForPatch
