
require 'active_support/concern'

#
# Including class should have defined
# destroy callbacks compatible with ActiveModel::Callback's
# implementation of them.
#
module PersistentRequestable
  extend ActiveSupport::Concern

  DEFAULT_CONCURRENT_REQUESTS = 1

  included do
    include Redis::Objects

    cattr_accessor :requests_allowed
    counter :persistent_requests_count
    set :persistent_requests

    after_destroy :_clean_persistent_requestable_redis_store

    self.requests_allowed = PersistentRequestable::DEFAULT_CONCURRENT_REQUESTS

    def available_for_request?
      _pristine? && persistent_requests_count < requests_allowed
    end

    def start_persistent_request(request_name)
      if !_record_ready_for_request?
        errors.add(:base, t('persistent_requestable.not_pristine', :model => self.class.to_s.humanize.downcase))
        return false
      end

      if persistent_requests_count.increment > requests_allowed
        persistent_requests_count.decrement
        errors.add(:base, t('persistent_requestable.already_requesting', :model => self.class.to_s.humanize.downcase))
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

    private

    def _pristine?
      !new_record? && !changed
    end

    def _clean_persistent_requestable_redis_store
      persistent_requests_count.del
      persistent_requests.del
    end
  end
end
