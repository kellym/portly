@namespace 'Portly', ->
  class @Port extends Backbone.Model

    events:
      "remove" : "destroyModel"

    url: ->
      "/api/connectors#{if @get('id') then "/#{@get('id')}" else ''}"

    domain: ->
      if @cname() == ''
        "#{@subdomain()}#{@domain_ending}"
      else
        @cname()

    public_url: ->
      @get 'public_url'

    local_path: ->
      @get 'local_path'

    setComputer: (val) ->
      @computer = val
      @setToken val.id

    setToken: (val) ->
      @set 'token_id', val

    setDomain: (val) ->
      @domain_ending = val

    pro_user: ->
      @get('pro_user')

    mirror: =>
      @get('mirror')

    isSyncing: =>
      @get 'syncing'

    startSync: =>
      @set 'syncing', true
      @trigger 'sync'

    stopSync: =>
      @set 'syncing', false
      @trigger 'sync'

    subdomain: =>
      @get 'subdomain'

    cname: =>
      @get 'cname'

    hasDomain: =>
      @get('cname').length > 0

    button_title: ->
      if @isConnected() then "Stop" else "Start"

    connected_title: ->
      if @isConnected() then "Connected" else "Disconnected"

    destroyModel: ->
      @destroy()

    status: ->
      if @computer.online_state() == 'offline'
        'disabled'
      else
        if @get('enabled')
          if @get('connected') then 'online' else 'offline'
        else
          'disabled'

    isOnline: ->
      @status() == 'online'

    isConnected: ->
      @get('connected') || false

    setState: (status) ->
      @set 'connected', status == 'online'
      @trigger 'sync'

    connect: ->
      @set 'enabled', true
      @trigger 'sync'

    disconnect: ->
      @set 'enabled', false
      @trigger 'sync'
