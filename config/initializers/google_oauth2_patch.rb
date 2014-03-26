require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class GoogleOauth2 < OmniAuth::Strategies::OAuth2
      def raw_info
        return @raw_info if @raw_info
        @raw_info ||= access_token.get('https://www.googleapis.com/oauth2/v1/userinfo').parsed
        
        if !@raw_info.is_a?(Hash)
          # probably a parse error where we got a binary body...shame on faraday.
          s = RestClient.get("https://www.googleapis.com/oauth2/v1/userinfo?access_token=#{access_token.token}")
          @raw_info = MultiJson.decode(s)
        end
        @raw_info
      end
    end
  end
end
