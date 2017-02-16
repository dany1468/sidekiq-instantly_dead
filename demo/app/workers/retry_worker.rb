class RetryWorker
  include Sidekiq::Worker
  sidekiq_options retry: 10

  def perform
    raise 'error!'
  end
end
