# frozen_string_literal: true

module SidekiqDaemon
  class DaemonLock
    DEFAULT_LOCK_DURATION = 60

    def initialize(worker_class, job)
      @worker_class = worker_class
      @job = job
    end

    def locked?
      Sidekiq.redis { |redis| lock_object(redis).locked? }
    end

    def lock
      Sidekiq.redis { |redis| lock_object(redis).lock(0) }
      yield
    ensure
      Sidekiq.redis { |redis| lock_object(redis).unlock }
    end

    def renew
      Sidekiq.redis { |redis| lock_object(redis).extend_life(sidekiq_options[:lock_duration] || DEFAULT_LOCK_DURATION) }
    end

    private

    def lock_object(redis)
      @key ||= @worker_class.name + "-" + @job['args'].to_s
      Redis::Lock.new(redis, @key, life: sidekiq_options[:lock_duration] || DEFAULT_LOCK_DURATION)
    end

    def sidekiq_options
      @options ||= @worker_class.get_sidekiq_options if @worker_class.respond_to?(:get_sidekiq_options)
      @options ||= Sidekiq.default_worker_options
      @options &&= @options.stringify_keys
    end
  end
end
