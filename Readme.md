# sidekiq-daemon

`sidekiq-daemon` makes it very easy to keep a job running forever in the background workers you already have in your application. You already have to keep your sidekiq job processes running, so let's just re-use that existing infrastructure for other daemon processes you might need.

### Status

Super alpha.

### Motivation

Running long or forever running processes in web applications can be annoying. There's a lot of options for supervisors with systemd, cron, god, foreman, Docker, Kubernetes, sidekiq-pro, sidekiq-scheduler, and all sorts of other things offering overlapping primitives for getting something to be running always.

Let's say you want to keep a Kafka consumer running forever ingesting and reacting to events in the background for the rest of the application to use later. Some folks run a different process type via a Procfile or a different Kubernetes Pod type that runs forever, and rely on the supervision of Heroku or Kubernetes to keep that thing running. That works just fine, but it adds a whole other class of process operators and developers need to care about. Any instrumentation that cares about where stuff is running has to know about this different tier, any liveness checks need to be adapted to run in or beside the tier, and you have one more thing that can fail.

Instead, I think those processes should be run the same way as other background jobs in your system and on the same infrastructure. There's already robust tooling to understand what happens to background jobs, to hook into them to instrument them, and a great plugin ecosystem so you don't have to invent it yourself. The trick is keeping that Kafka consumer always running, and only one copy of it running, so enter 'sidekiq-daemon'.

It requires two pieces: a scheduler entry to try to enqueue the job every so often, and then a call out to the `daemon_lock.renew` method to keep the system aware that the long running job is still alive.

It's like `sidekiq-unique-jobs`, but way simpler, and allows for lock renewing to keep timeouts tight.

### Example

```yml
mqtt_state_injest:
  class: MqttStateInjest
  cron: "* * * * *" # try to run every minute
  queue: "default"
```

```ruby
class MqttStateInjest
  include Sidekiq::Worker
  include SidekiqDaemon::Worker # means only one will run at once

  sidekiq_options retries: 0

  def perform(farm_id)
    $mqtt_client.subscribe('#')
    $mqtt_client.get do |topic, payload|
      MqttHandler.handle(topic, payload)
      daemon_lock.renew
    end
  end
end
```
