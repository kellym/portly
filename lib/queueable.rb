module Queueable

  def queue(*args)
    args.unshift self.name
    Redis.current.lpush('queue_monitor', args.to_msgpack)
  end

end
