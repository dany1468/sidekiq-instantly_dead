class DeadInstantlyWorker
  include Sidekiq::Worker
  sidekiq_options retry: 10

  def perform
    raise Sidekiq::InstantlyDeadError
  end
end
