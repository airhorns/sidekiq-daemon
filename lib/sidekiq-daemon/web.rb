module SidekiqDaemon
  # Plugin for sidekiq-web
  module Web
    VIEW_PATH = File.expand_path('../../../web', __FILE__)

    def self.registered(app)
      app.get '/daemons' do
        @daemon_inspector = DaemonInspector
        erb File.read(File.join(VIEW_PATH, 'daemons.erb'))
      end

      # app.post '/recurring/:name/enqueue' do |name|
      #   job_name = respond_to?(:route_params) ? route_params[:name] : name
      #
      #   # rubocop:disable Lint/AssignmentInCondition
      #   if spec = Sidecloq::Schedule.from_redis.job_specs[job_name]
      #     JobEnqueuer.new(spec).enqueue
      #   end
      #   # rubocop:enableLint/AssignmentInCondition
      #   redirect "#{root_path}recurring"
      # end
    end
  end
end

Sidekiq::Web.register(SidekiqDaemon::Web)
Sidekiq::Web.tabs['Daemons'] = 'daemons'
