
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
    include AttributesInFineGrained
    include ActionView::Helpers::TranslationHelper

    cattr_accessor :requests_allowed
    counter :persistent_requests_count
    set :persistent_requests
    value :last_error

    after_destroy :_clean_persistent_requestable_fine_grained_store

    self.requests_allowed = PersistentRequestable::DEFAULT_CONCURRENT_REQUESTS

    def available_for_request?
      _pristine? && persistent_requests_count < requests_allowed
    end

    def start_persistent_request(request_name)
      if !_pristine?
        errors.add(:base, t('persistent_requestable.not_pristine', :model => self.class.to_s.titleize.humanize.downcase))
        return false
      end

      if persistent_requests_count.incr > requests_allowed
        persistent_requests_count.decr
        errors.add(:base, t('persistent_requestable.already_requesting', :model => self.class.to_s.titleize.humanize.downcase))
        return false
      end

      persistent_requests << request_name
      self.last_error = ""
      true
    end

    def stop_persistent_request(request_name)
      persistent_requests_count.decr
      if !persistent_requests.include? request_name
        DetectedError.create(:message => "Attempted to remove nonexistent request of #{request_name} for class #{self.class.to_s} having id #{id}")
        return false
      end

      persistent_requests.remove(request_name)
      true
    end

    protected

    def _with_stop_persistence(request_name)
      begin
        yield
      rescue => e
        self.last_error = I18n.t('internal_server_error')
        return false
      ensure
        stop_persistent_request(request_name)
      end
    end

    private

    def _pristine?
      !new_record? && !changed?
    end

    def _clean_persistent_requestable_fine_grained_store
      last_error.del
      persistent_requests_count.del
      persistent_requests.del
    end
  end
end
