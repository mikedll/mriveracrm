
require 'active_support/concern'

#
# Client must define:
#
#   handle_result
#   target_url
#
# And these fields in db:
#
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

    class Worker < WorkerBase
    end

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
      Worker.obj_enqueue(self, :poll_background)
      true
    end

    def poll_background
      self.last_polled_at = nil

      handle_result(result)

      self.last_polled_at = Time.now
      save!
      stop_persistent_request(BACKGROUND_POLL)
    end

    def reset_last_poll
      self.last_polled_at = Time.now
    end

  end

end
