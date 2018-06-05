# frozen_string_literal: true

module SidekiqDaemon
  module Worker
    module ClassMethods
      def requires_daemon_locking?
        true
      end
    end

    attr_accessor :daemon_lock

    def self.included(base)
      base.extend ClassMethods
    end
  end
end
