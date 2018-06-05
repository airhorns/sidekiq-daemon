# frozen_string_literal: true

module SidekiqDaemon
  class ClientMiddleware
    def call(worker_class, job, _queue, _connection_pool = nil)
      klass = worker_class.constantize
      if klass.respond_to?(:requires_daemon_locking?) && klass.requires_daemon_locking?
        lock = DaemonLock.new(klass, job)
        if !lock.locked?
          yield
        else
          Sidekiq.logger.debug("Skipped enqueung worker_class=#{worker_class} with params=#{job} because its daemon lock is currently held")
          false
        end
      else
        yield
      end
    end
  end
end
