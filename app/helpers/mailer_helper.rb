module MailerHelper
  def business_home_url(business)
    if business.host.blank?
      business_url(:use_route => 'bhandle_home', :business_handle => business.handle, :host => business.default_url_host)
    else
      business_url(:host => business.default_url_host)
    end

  end
end
