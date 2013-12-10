@namespace 'Portly', ->
  class @PortCollection extends Backbone.Collection

    model: Portly.Port

    url: ->
      "/dashboard/#{@token}"

    setComputer: (computer) ->
      @computer = computer
      @token = computer.id
      @each (model) =>
        model.setComputer computer
