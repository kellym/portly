@namespace 'Portly', -> @namespace 'Ports', ->
  class @Router extends Backbone.Router

    el: 'body'

    routes:
      'dashboard/:id' : 'changeComputer'

    initialize: (data)=>
      if data
        @computers = data['computers']
        current_computer = @computers.current()
        @collection = data['collection']
        @view = new Portly.Ports.IndexView
          computers: @computers
          collection: @collection
          domain: data['domain']
        if @computers.length > 1
          @navigate "dashboard/#{current_computer.id}-#{current_computer.slug()}",
            trigger: true
      else
        @new_user = true

      @event_source = new Portly.EventSourceListener
        delegate: @

    changeComputer: (id)->
      @computers.setIndex parseInt(id)
      @collection.setComputer @computers.current()
      @collection.fetch
        reset: true

