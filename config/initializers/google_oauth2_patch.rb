require 'omniauth/strategies/oauth2'
require 'oauth2/strategy/auth_code'
require 'oauth2/strategy/base'

#
# Disable gzip encoding from Google since Faraday does not handle it.
#
# Also override google_oauth2 omniauth gem's url at which the raw info is fetched,
# since it sometimes uses a Google+ one.
#



module OmniAuth
  module Strategies
    class GoogleOauth2 < OmniAuth::Strategies::OAuth2
      def raw_info
        @raw_info ||= access_token.get('https://www.googleapis.com/oauth2/v1/userinfo', :headers => {'Accept-Encoding' => 'gzip;q=0,deflate,sdch'}).parsed
      end
    end
  end
end

module OAuth2
  module Strategy
    class AuthCode < OAuth2::Strategy::Base
      def get_token(code, params={}, opts={})
        params = {:headers => {'Accept-Encoding' => 'gzip;q=0,deflate,sdch'}, 'grant_type' => 'authorization_code', 'code' => code}.merge(client_params).merge(params)
        @client.get_token(params, opts)
      end
    end
  end
end


