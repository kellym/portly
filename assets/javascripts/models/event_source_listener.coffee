@namespace 'Portly', ->
  class @EventSourceListener

    url: '/subscribe/ports'

    events:
      'open'                 : 'open'
      'socket'               : 'socket'
      'connect'              : 'connect'
      'disconnect'           : 'disconnect'
      'new_connector'        : 'loadItem'
      'delete'               : 'deleteItem'
      'state'                : 'setState'
      'message'              : 'message'
      'sync'                 : 'sync'
      'error'                : 'error'

    constructor:(args) ->
      @delegate = args.delegate
      @es = new EventSource(@url)
      for event,method of @events
        @es.addEventListener(event, @[method])

    connect: (event) =>
      # connect: is the state of the server side
      # state:   is the state of the client side
      data = $.parseJSON(event.data)
      row = @delegate.collection.get(data.id)
      row.connect()

    disconnect: (event) =>
      data = $.parseJSON(event.data)
      row = @delegate.collection.get(data.id)
      row.disconnect()

    socket: (event) =>
      data = $.parseJSON(event.data)
      computer = @delegate.computers.get(data.id)
      if computer
        computer.setState "#{data.args[0]}line"
      else
        # create a new computer and add it.
        computer = new Portly.Computer(id: data.id)
        computer.fetch(success: =>
          @delegate.computers.setIndex data.id
          @delegate.computers.add(computer)
        )

    loadItem: (event) =>
      # handle checking that this model isn't already created by us.
      data = $.parseJSON(event.data)
      if @delegate.collection.get(data['id'])
        return
      else
        $.get("/api/connectors/#{data['id']}", {}, (data) =>
          model = new Portly.Port(data)
          @delegate.view.addNewModel(model)
        , 'json')

    deleteItem: (event) ->
      data = $.parseJSON(event.data)
      row = @delegate.collection.get(data.id)
      row.trigger 'remove' if row

    setState: (event) =>
      data = $.parseJSON(event.data)
      row = @delegate.collection.get(data.args[0])
      row.setState "#{data.args[1]}line" if row

    open: (event) =>
      true

    message: (event) ->
      true

    sync: (event) =>
      data = $.parseJSON(event.data)
      row = @delegate.collection.get(data.id)
      if row
        if data.state == 'started'
          row.startSync()
        else if data.state == 'completed'
          row.stopSync()

    error: (event) ->
      true


