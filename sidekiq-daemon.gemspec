# frozen_string_literal: true

$LOAD_PATH.unshift 'lib'
require "sidekiq-daemon/version"
Gem::Specification.new do |s|
  s.name              = "sidekiq-daemon"
  s.version           = SidekiqDaemon::VERSION
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Run long or forever running background jobs in Sidekiq instead of as their own processes."
  s.homepage          = "http://github.com/hornairs/sidekiq-daemon"
  s.email             = "harry.brundage@gmail.com"
  s.authors           = ["Harry Brundage"]
  s.files             = %w(README.md LICENSE)
  s.files            += Dir.glob("lib/**/*")
  s.add_runtime_dependency 'sidekiq', '~> 5.1.3'
  s.add_runtime_dependency 'redis', '~> 4.0.1'
  s.add_runtime_dependency 'mlanett-redis-lock', '~> 0.2.7'
  s.description = "Run long or forever running background jobs in Sidekiq instead of as their own processes."
end
