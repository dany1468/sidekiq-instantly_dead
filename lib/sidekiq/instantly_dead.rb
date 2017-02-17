require 'sidekiq'

require 'sidekiq/instantly_dead/version'
require 'sidekiq/instantly_dead_error'

module Sidekiq
  module InstantlyDead
    class Middleware
      def initialize(options = {})
        @max_retries = options.fetch(:max_retries, Sidekiq::Middleware::Server::RetryJobs::DEFAULT_MAX_RETRY_ATTEMPTS)
      end

      def call(_worker, msg, _queue)
        yield
      rescue Sidekiq::InstantlyDeadError
        raise unless msg['retry']

        unless msg['dead'] == false
          max_retry_attempts = retry_attempts_from(msg['retry'], @max_retries)

          msg['retry_count'] = max_retry_attempts

          Sidekiq.logger.debug { "Increase retry_count to max_retry_attempt(#{max_retry_attempt}) to instantly dead" }
        end

        raise
      end

      private

      def retry_attempts_from(msg_retry, default)
        if Fixnum === msg_retry
          msg_retry
        else
          default
        end
      end
    end
  end
end
