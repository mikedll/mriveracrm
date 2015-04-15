module Regexes

  BUSINESS_HANDLE = /\A[A-Za-z0-9]+\z/
  BUSINESS_HANDLE_ROUTING = /[A-Za-z0-9]+/

  EMAIL = /[a-z0-9!#$\%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$\%&'*+\/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/

  ZIP = /[\-0-9]+/

  HOST = /\A[A-Za-z0-9-]+\.[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\z/

  PROTOCOL = /\Ahttp(s)?/
end
