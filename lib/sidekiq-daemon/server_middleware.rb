# frozen_string_literal: true

module SidekiqDaemon
  class ServerMiddleware
    def call(worker, job, _)
      if worker.class.respond_to?(:requires_daemon_locking?) && worker.class.requires_daemon_locking?
        daemon_lock = DaemonLock.new(worker.class, job)
        worker.daemon_lock = daemon_lock
        begin
          daemon_lock.lock do
            yield
          end
        rescue Redis::Lock::LockNotAcquired
          Sidekiq.logger.debug("Lock not aquired, skipping job #{job['jid']}")
          return false
        end
      else
        yield
      end
    end
  end
end
