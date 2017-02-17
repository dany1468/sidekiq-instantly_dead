describe Sidekiq::InstantlyDead do
  class AWorker
    include Sidekiq::Worker

    def perform
      raise 'error!'
    end
  end

  class BWorker
    include Sidekiq::Worker

    def perform
      raise Sidekiq::InstantlyDeadError
    end
  end

  before do
    allow(Redis).to receive(:new) { MockRedis.new }
    Sidekiq.redis {|r| r.flushdb }

    Sidekiq.server_middleware do |chain|
      chain.insert_after Sidekiq::Middleware::Server::RetryJobs, Sidekiq::InstantlyDead::Middleware
    end
  end

  let(:job_hash) { {class: worker.class, retry: 5}.stringify_keys }

  subject { Sidekiq.server_middleware.invoke(worker, job_hash, 'default') { worker.perform } rescue nil }

  context 'when raised RuntimeError' do
    let(:worker) { AWorker.new }

    specify do
      expect { subject }.to change { Sidekiq::RetrySet.new.size }.from(0).to(1)
    end

    specify do
      expect { subject }.not_to change { Sidekiq::DeadSet.new.size }
    end

    specify do
      subject

      expect(job_hash).to include({
        class: AWorker,
        retry: 5,
        retry_count: 0,
        queue: 'default',
        error_message: 'error!',
        error_class: 'RuntimeError',
        failed_at: anything
      }.stringify_keys)
    end
  end

  context 'when raised InstantlyDeadError' do
    let(:worker) { BWorker.new }

    specify do
      expect { subject }.not_to change { Sidekiq::RetrySet.new.size }
    end

    specify do
      expect { subject }.to change { Sidekiq::DeadSet.new.size }.from(0).to(1)
    end

    specify do
      subject

      expect(job_hash).to include({
        class: BWorker,
        retry: 5,
        retry_count: 6,
        queue: 'default',
        error_message: 'Sidekiq::InstantlyDeadError',
        error_class: 'Sidekiq::InstantlyDeadError',
        retried_at: anything
      }.stringify_keys)
    end
  end
end
