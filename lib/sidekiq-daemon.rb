# frozen_string_literal: true

require 'redis'
require 'redis-lock'
require 'sidekiq-daemon/worker'
require 'sidekiq-daemon/daemon_lock'
require 'sidekiq-daemon/client_middleware'
require 'sidekiq-daemon/server_middleware'

module SidekiqDaemon
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add SidekiqDaemon::ClientMiddleware
  end
end

Sidekiq.configure_server do |config|
  config.client_middleware do |chain|
    chain.add SidekiqDaemon::ClientMiddleware
  end

  config.server_middleware do |chain|
    chain.add SidekiqDaemon::ServerMiddleware
  end
end
