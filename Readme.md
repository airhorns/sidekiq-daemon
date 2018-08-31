# sidekiq-daemon

`sidekiq-daemon` makes it easy to keep a job running forever in the background. If you need to injest from a datastream, or poll for changes somewhere, sometime's it's more convienient to write a daemon that the infrastructure keeps running always, even as things fail. If you already have to keep your sidekiq job processes running, you can re-use that existing infrastructure for other daemon processes you might need with `sidekiq-daemon`.

### Status

Super alpha.

### Motivation

Running long or forever running processes in web applications can be annoying. There's a lot of options for supervisors with systemd, cron, god, foreman, Docker, Kubernetes, sidekiq-pro, sidekiq-scheduler, and all sorts of other things offering overlapping primitives for getting something to be running always.

Let's say you want to keep a Kafka consumer running forever ingesting and reacting to events in the background for the rest of the application to use later. Some folks run a different process type via a Procfile or a different Kubernetes Pod type that runs forever, and rely on the supervision of Heroku or Kubernetes to keep that thing running. That works just fine, but it adds a whole other class of process operators and developers need to care about. Any instrumentation that cares about where stuff is running has to know about this different tier, any liveness checks need to be adapted to run in or beside the tier, and you have one more thing that can fail.

Instead, I think those processes should be run the same way as other background jobs in your system and on the same infrastructure. There's already robust tooling to understand what happens to background jobs, to scale them out across many workers, to hook into them and instrument them, and a great plugin ecosystem so you don't have to invent the pieces yourself. The hard part is keeping exactly one of whatever your daemon process running using Sidekiq primitives, which is what 'sidekiq-daemon' bottles up for you.

### What it does

`sidekiq-daemon` locks around a job's execution using Redis locks such that only one instance of the job can be running at once, and then treats that lock as a liveness check for the rest of the system. If a job dies, the lock expires, and the next job that gets enqueued will take out the lock, and move along. For jobs that need to be running always, it's a good idea to use a sidekiq scheduler like Sidecloq to try to enqueue a job every minute or what have you. Sidecloq is robust to failures in that all Sidekiq job processes can be elected to be the sidecloq leader so there's no single point of failure for keeping the job alive.

It's like `sidekiq-unique-jobs`, but way simpler, and allows for lock renewing to keep timeouts tight.

### Using it

You require two pieces: a scheduler entry to try to enqueue the job every so often, and then a job including `SidekiqDaemon::Worker`. Your job will only ever have one instance running once it includes the `SidekiqDaemon::Worker` module, but to keep the liveness check working, that job needs to call the `daemon_lock.renew` method more frequently than the `sidekiq_options[:daemon_lock_timeout]`. 

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
