
require 'active_support/concern'

module PersistentRequestable
  extend ActiveSupport::Concern

  DEFAULT_CONCURRENT_REQUESTS = 1

  included do
    include Redis::Objects

    cattr_accessor :requests_allowed
    counter :persistent_requests_count
    set :persistent_requests

    self.requests_allowed = PersistentRequestable::DEFAULT_CONCURRENT_REQUESTS

    def available_for_request?
      !new_record? && persistent_requests_count < requests_allowed
    end

    def start_persistent_request(request_name)
      if persistent_requests_count.increment > requests_allowed
        persistent_requests_count.decrement
        return false
      end

      persistent_requests << request_name
      true
    end

    def stop_persistent_request(request_name)
      persistent_requests_count.decrement
      if !persistent_requests.member? request_name
        DetectedError.create(:message => "Attempted to remove nonexistent request of #{request_name} for class #{self.class.to_s} having id #{id}")
        return false
      end

      persistent_requests.delete(request_name)
      true
    end

  end
end
