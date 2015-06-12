
require 'active_support/concern'

#
# Client must define:
#
#   before_poll
#   handle_poll_result(response, request, result)
#   target_endpoint
#
#   class Worker < WorkerBase
#   end
#
#
# And these fields in db:
#
#  last_error
#  last_polled_at
#  active
#
module BackgroundedPolling
  extend ActiveSupport::Concern

  POLL_PERIOD = 1.hour
  BACKGROUND_POLL = 'background_poll'

  included do
    include PersistentRequestable

    scope :live, lambda { where('active = ?', true) }
    scope :pollable, lambda { live.where('last_polled_at is null OR last_polled_at < ?', Time.now - POLL_PERIOD) }

    def self.run_live!
      pollable.find_each do |s|
        s.poll!
      end
    end

    def poll!
      if !start_persistent_request(BACKGROUND_POLL)
        errors.add(:base, t('backgrounded_polling.backgrounded_polling'))
        return false
      end
      self.class::Worker.obj_enqueue(self, :poll_background)
      true
    end

    def poll_background
      before_poll
      self.last_error = ""
      self.last_polled_at = nil

      begin
        result = RestClient.get target_endpoint, :params => {}, :from => from_header do |response, request, result|
          handle_poll_result(response, request, result)
        end
      rescue => e
        self.last_error = e.message
      end

      self.last_polled_at = Time.now
      save!
      stop_persistent_request(BACKGROUND_POLL)
    end

    def reset_last_poll
      self.last_polled_at = Time.now
    end

  end

end
