class EventSource
  include EventMachine::Deferrable

  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
    # SOCKETS[user_id] << self
    super()
  end

  def send(data, id = nil)
    return unless @body_callback
    @body_callback.call %Q(event: #{data.strip}\ndata: { "id": "#{id}" }\n\n)
  end

  def ping
    return unless @body_callback
    @body_callback.call %Q(data: {}\n\n)
  end

  def each(&block)
    @body_callback = block

    # for IE
    @body_callback.call ':' + (' ' * 2049) + "\n"
    @body_callback.call "retry: 2000\n"

    timer = EventMachine::PeriodicTimer.new(20) { self.ping }
    errback do
      puts 'Session Killed'
      timer.cancel
      SOCKETS[self.user_id].delete self
    end
  end

  # Public: Send an action to any open sockets for a particular user.
  def self.publish(user_id, action, id)
    SOCKETS[user_id].each { |s| s.send(action, id) } if SOCKETS.include?(user_id)
  end
end
