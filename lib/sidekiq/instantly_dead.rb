require 'sidekiq/instantly_dead/version'

module Sidekiq
  module InstantlyDead
    class Middleware
      def initialize(max_retries: Sidekiq::Middleware::Server::RetryJobs::DEFAULT_MAX_RETRY_ATTEMPTS)
        @max_retries = max_retries
      end

      def call(_worker, msg, _queue)
        yield
      rescue Sidekiq::InstantlyDeadError
        raise unless msg['retry']

        unless msg['dead'] == false
          max_retry_attempts = retry_attempts_from(msg['retry'], @max_retries)

          msg['retry_count'] = max_retry_attempts

          logger.debug { "Increase retry_count to max_retry_attempt(#{max_retry_attempt}) to instantly dead" }
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

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.insert_before Sidekiq::Middleware::Server::RetryJobs, Sidekiq::PerformingContext::Middleware
  end
end
