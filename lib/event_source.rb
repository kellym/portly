class EventSource
  include EventMachine::Deferrable

  def send(data, id = nil)
    data.each_line do |line|
      line = "data: #{line.strip}\n"
      @body_callback.call line
    end
    @body_callback.call "id: #{id}\n" if id
    @body_callback.call "\n"
  end

  def each(&blk)
    @body_callback = blk
  end
end

class EventStream
  include EventMachine::Deferrable
  def each
    count = 0
    timer = EventMachine::PeriodicTimer.new(1) do
      yield "data: #{count += 1}\n\n"
    end
    errback { timer.cancel }
  end
end
