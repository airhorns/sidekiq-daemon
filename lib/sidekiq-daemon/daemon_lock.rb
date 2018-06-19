# frozen_string_literal: true

module SidekiqDaemon
  class DaemonLock
    DEFAULT_LOCK_DURATION = 60
    DEFAULT_RUN_DURATION = 600
    HOSTNAME = `hostname`.strip

    def initialize(worker_class, job)
      @worker_class = worker_class
      @job = job
      @started_at = Time.now.utc
      @lock_duration = sidekiq_options[:daemon_lock_duration] || DEFAULT_LOCK_DURATION
      @run_duration = sidekiq_options[:daemon_max_runtime] || DEFAULT_RUN_DURATION
    end

    def locked?
      Sidekiq.redis { |redis| lock_object(redis).locked? }
    end

    def lock
      Sidekiq.redis do |redis|
        lock_object(redis).lock(0)
        @last_locked_at = Time.now.utc
      end

      yield
    ensure
      Sidekiq.redis { |redis| lock_object(redis).unlock }
    end

    # Just renew the lock, no checking if we've run too long
    def renew
      Sidekiq.redis do |redis|
        if @last_locked_at && Time.now.utc > (@last_locked_at + @lock_duration)
          Sidekiq.logger.warn("Sidekiq daemon lock expired in redis inbetween renewals! Increase the rate #renew or #checkin is called, or increase sidekiq_options[:daemon_lock_duration]")
        end
        lock_object(redis).extend_life(@lock_duration)
        @last_locked_at = Time.now.utc
      end
    end

    # Renew the lock and return a boolean representing if the job should keep running or not.
    def checkin
      renew

      if sidekiq_options[:daemon_max_runtime].nil? || sidekiq_options[:default_max_runtime]
        duration = Time.now.utc - @started_at
        if duration > @run_duration
          false
        else
          true
        end
      else
        true
      end
    end

    private

    def lock_object(redis)
      @key ||= "sidekiq-daemon-lock-#{@worker_class.name}-#{@job['args']}"
      SidekiqDaemon::DaemonInspector.register_daemon(@key)
      Redis::Lock.new(redis, @key, life: @lock_duration, owner: "jid:#{@job['jid']},started_at:#{@started_at},hostname:#{HOSTNAME},pid:#{Process.pid}")
    end

    def sidekiq_options
      @options ||= @worker_class.get_sidekiq_options if @worker_class.respond_to?(:get_sidekiq_options)
      @options ||= Sidekiq.default_worker_options
      @options &&= @options.stringify_keys
    end
  end
end
