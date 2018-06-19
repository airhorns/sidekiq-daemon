# frozen_string_literal: true

module SidekiqDaemon
  module DaemonInspector
    DAEMON_LOCK_KEYS_KEY = "sidekiq-daemon-lock-keys"

    def self.register_daemon(lock_key)
      Sidekiq.redis { |redis| redis.sadd(DAEMON_LOCK_KEYS_KEY, lock_key) }
    end

    def self.daemons
      Sidekiq.redis do |redis|
        redis.smembers(DAEMON_LOCK_KEYS_KEY).reduce({}) do |result, lock_key|
          result[lock_key] = {
            owner: redis.get("lock:owner:#{lock_key}") || "not owned",
            expiry: "expired"
          }

          if expiry = redis.get("lock:expire:#{lock_key}")
            result[lock_key][:expiry] = Time.new(expiry.to_i)
          end

          result
        end
      end
    end
  end
end
