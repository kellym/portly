@namespace 'Portly', ->
  class @Computer extends Backbone.Model

    url: ->
      "/api/tokens/#{@get('id')}"

    name: ->
      @get 'name'

    slug: ->
      @name().toLowerCase().replace(/[^\w ]+/g,'').replace(/\s+/g,'-')

    online_state: ->
      if @get('online') then 'online' else 'offline'

    setState: (val) ->
      @set('online', val == 'online')
      @collection.trigger 'sync'

    setCollection: (val) ->
      @collection = val

    dashboard_url: ->
      "/dashboard/#{@get 'id'}-#{@slug()}"
