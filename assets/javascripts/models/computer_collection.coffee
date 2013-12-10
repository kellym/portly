@namespace 'Portly', ->
  class @ComputerCollection extends Backbone.Collection

    model: Portly.Computer

    events:
      'remove' : 'destroyModel'

    initialize: (models, opts) ->
      opts ||= {}
      @setIndex opts.index
      @each (model) =>
        model.setCollection @

    current: ->
      @get(@index)

    current_name: ->
      @current().name() if @current()

    current_state: ->
      @current().online_state() if @current()

    more_than_one: ->
      @models.length > 1

    destroyModel: ->
      @setIndex()

    setIndex: (val) ->
      if val
        @index = val
      else if @at(0)
        @index = @at(0).get('id')
      else
        @index = 0
