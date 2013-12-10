@namespace 'Portly', ->
  class @ComputerCollection extends Backbone.Collection

    model: Portly.Computer

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

    setIndex: (val) ->
      @index = val
