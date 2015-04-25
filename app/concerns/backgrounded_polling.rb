
require 'active_support/concern'

#
# Client must define:
#
#   target_endpoint
#   before_poll
#   handle_result
#   params_for_poll_request(n)
#
module BackgroundedPolling
  extend ActiveSupport::Concern

  WINDOW_DURATION = 1.day
  MAX_RUNS_PER_WINDOW = 10
  MAX_REQUESTS_PER_RUN = 10

  included do
    include PersistentRequestable

    scope :resettable, lambda { where('last_window_started_at is null OR last_window_started_at < ?', Time.now - WINDOW_DURATION) }
    scope :live, lambda { where('active = ?', true) }
    scope :has_runs_available, lambda { where('runs_since_window_started < ?', MAX_RUNS_PER_WINDOW) }
    scope :not_polled_this_window, lambda { where('last_polled_at is null ') }
    scope :auto_pollable, lambda { live.not_polled_this_window.has_runs_available }

    class Worker < WorkerBase
    end

    def self.reset_windows!
      resettable.find_each do |s|
        s.reset_window
        s.save!(:validate => false)
      end
    end

    def self.run_live!
      auto_pollable.find_each do |s|
        s.poll!
      end
    end

    def window_will_reset_at
      (last_window_started_at + WINDOW_DURATION).end_of_hour + 1.second # coordinate this with scheduler
    end

    def runs_available?
      runs_since_window_started < MAX_RUNS_PER_WINDOW
    end

    def runnable?
      runs_available? && available_for_request?
    end

    def poll!
      return false if !runs_available?
      if !start_persistent_request(RANKING_REQUEST)
        errors.add(:base, t('seo_ranker.already_requesting'))
        return false
      end
      Worker.obj_enqueue(self, :poll_background)
      true
    end

    def poll_background
      self.last_polled_at = nil
      self.last_error = ""

      requests = 0
      self.last_result_halted_poll = false
      done = false
      while !done && requests < MAX_REQUESTS_PER_RUN
        result = nil
        begin
          requests += 1
          result = RestClient.get target_endpoint, :params => params_for_request(requests)
        rescue => e
          self.last_error = e.response
          done = true
          break
        end

        begin
          handle_result(result)
          if last_result_halted_poll
            done = true
            break
          end
        rescue => e
          self.last_error = t('seo_ranker.parse_error')
          done = true
          break
        end
      end

      self.runs_since_window_started += 1
      save!
      stop_persistent_request(RANKING_REQUEST)
    end

    def reset_polling_window
      self.last_window_started_at = Time.now
      self.runs_since_window_started = 0
    end

  end

end
