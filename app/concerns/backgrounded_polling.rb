
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
#  consecutive_error_count
#
module BackgroundedPolling
  extend ActiveSupport::Concern

  class IneligibleToPoll < StandardError
  end

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
      raise IneligibleToPoll if !active?

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
      self.consecutive_error_count ||= 0

      begin
        result = RestClient.get target_endpoint, :params => {} do |response, request, result|
          if ![200, 201].include?(response.net_http_res.code.to_i)
            self.last_error = I18n.t('computer_monitor.errors.unexpected_http_result', :code => response.net_http_res.code.to_i)
          else
            handle_poll_result(response, request, result)
          end
        end
      rescue => e
        self.last_error = e.message
      end

      if !last_error.blank?
        self.consecutive_error_count += 1
        self.active = false if consecutive_error_count >= Repetition::MAX_CONSECUTIVE
      else
        self.consecutive_error_count = 0
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
