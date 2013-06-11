#= require vendor/chart

@namespace 'Portly', -> @namespace 'Tunnels', -> @namespace 'Views', ->
  class @Index extends Backbone.View

    el: 'body'

    events:
      'es:open'                 : 'open'
      'es:socket'               : 'socket'
      'es:connect'              : 'connect'
      'es:disconnect'           : 'disconnect'
      'es:new_connector'        : 'loadItem'
      'es:delete'               : 'deleteItem'
      'es:state'                : 'setConnectorState'
      'es:message'              : 'message'
      'es:error'                : 'error'
      'click a[data-connector]' : 'changeState'
      'opened .add-modal'       : 'focusReveal'
      'closed .add-modal'       : 'clearReveal'
      'change .hosting-type'    : 'changeHostingType'
      'click .inline-input'     : 'focusInlineInput'
      'blur .inline-input input': 'unfocusInlineInput'
      'click .subnav a[data-section]' : 'showComputer'
      'click a.update-tunnel'      : 'openUpdateReveal'
      'opened .update-modal'    : 'updateReveal'
      'pjax:end'                : 'pjaxEnd'

    initialize: (data)=>
      @$('.inline-input input').autoGrow(2)
      @menu = @$('.subnav').overflowmenu(
        open: ->
          console.log 'open'
        change: ->
          console.log 'hello'
        appendTo: @$('.subnav .large-1')
        handleClass: 'p-menu'
        label: ''
      )
      @sections = $('.sections')
      @tipsy = $('.summary').tipsy( {trigger: 'manual', gravity: 's', fade: false, title: ->
        $('.summary').data('title')
      })
      $('.summary').on('mouseout', (ev) ->
        $(@).tipsy('hide')
      )
      @tipsy.tipsy('show')
      @chart = new Chart($('.summary canvas')[0].getContext('2d'))
      labels = []
      for i in [0..data[0].length-1] by 1
        labels[i] = ''
      @chart.StackedBar( {
        labels : labels,
        datasets : [
          {
            fillColor : "rgba(131,200,152,0.8)",
            strokeColor : "rgba(131,200,152,1)",
            data : data[0]
          },
          {
            fillColor : "rgba(198,221,171,0.8)",
            strokeColor : "rgba(198,221,171,1)",
            data : data[1],
            mouseover: (e, pt, data, i, j) =>
              e['currentTarget'] = $('.summary')
              @tipsy.data('title', "#{@humanNumber(data.datasets[0].data[i] || 0)} in / #{@humanNumber(data.datasets[1].data[i] || 0)} out")
              t = @tipsy.enter(e)
              t.reset()
              t.setPosition(pt.x1 + 4, (pt.y2 || 150) - 3)

            mouseout: (e, pt) =>
              e['currentTarget'] = $('.summary')
              @tipsy.leave(e)
          }
        ]}, {
          scaleShowLabels: false,
          scaleShowGridLines: false,
          barValueSpacing: 1,
          scaleGridLineColor: 'rgba(0,0,0,0)',
          scaleFontSize: 8
        }
      )
      @stopwatches = []

      @$('.stopwatch').each (i, el) =>
        @startWatch $(el)

      @es = new EventSource("/subscribe/tunnels")

      for event,method of @events
        @es.addEventListener(event.substring(3), @[method]) if /^es\:/.test(event)

    humanNumber: (number) ->
      if number < 1048576
        number = parseInt(number / 1024) + ' KB'
      else if number >= 1048576
        number = parseInt(number / 1048576) + ' MB'
      number

    focusInlineInput: (ev) ->
      ev.preventDefault()
      $(ev.currentTarget).addClass('focus').find('input').focus()

    unfocusInlineInput: (ev) ->
      $(ev.currentTarget).closest('.inline-input').removeClass('focus')

    changeState: (ev) =>
      ev.preventDefault()
      el = $(ev.currentTarget)
      data = el.data()
      if data.connector == true
        href = "/api/tunnels/#{data.connector_id}"
        $.ajax
          url: href
          data: data
          type: "DELETE"
      else
        href ="/api/tunnels"
        $.post href, data
      el.addClass('disabled')

    connect: (event) =>
      data = $.parseJSON(event.data)
      row = $(".connector[data-id=\"" + data["id"] + "\"]")
      span = row.find('.domain span')
      span.replaceWith($("<a class='link' href='#{span.data('url')}' target='_blank'>#{span.text()}</a>"))
      row.find(".connected-state").addClass("state-online").removeClass "state-offline"
      connect = row.find(".connect")
      connect.attr('title', 'Disconnect')
      #connect.attr('original-title', 'Disconnect')
      $tipsy[connect.data('tipsy-id')].reset()
      connect.removeClass('disabled')
      connect.find('span').addClass('p-pause').removeClass('p-play')
      connect.data('connector', true)
      @startWatch(row.find(".stopwatch"), +new Date())
      console.log "connect"
      console.log event.data

    disconnect: (event) ->
      data = $.parseJSON(event.data)
      row = $(".connector[data-id=\"" + data["id"] + "\"]")
      link = row.find('.domain a.link')
      link.replaceWith($("<span data-url='#{link.prop('href')}'>#{link.text()}</span>"))
      row.find(".connected-state").addClass("state-offline").removeClass "state-online"
      connect = row.find(".connect")
      connect.attr('title', 'Connect')
      #connect.attr('original-title', 'Connect')
      $tipsy[connect.data('tipsy-id')].reset()
      connect.removeClass('disabled')
      connect.data('connector', false)
      connect.find('span').removeClass('p-pause').addClass('p-play')
      row.find(".stopwatch").trigger "stop"
      console.log "disconnect"
      console.log event.data

    socket: (event) ->
      data = $.parseJSON(event.data)
      if data["args"][0] == "on"
        console.log "socket:on ->" + data["id"]
        link = $("a[data-section=\"" + data["id"] + "\"]")
        link.addClass('online').removeClass('offline')
        link.find(".online-state").removeClass('offline').text "ONLINE"
        socket = $("section[data-section=\"" + data["id"] + "\"]")
        socket.find(".connected-state").removeClass "state-disabled"
        socket.find('.connect').show()
      else
        console.log "socket:off ->" + data["id"]
        link = $("a[data-section=\"" + data["id"] + "\"]")
        link.addClass('offline').removeClass('online')
        link.find(".online-state").addClass('offline').text "OFFLINE"
        socket = $("section[data-section=\"" + data["id"] + "\"]")
        socket.find(".connected-state").addClass "state-disabled"
        socket.find('.connect').hide()

    loadItem: (event) ->
      data = $.parseJSON(event.data)
      $.get("/api/connectors/#{data['id']}", {access_id: data.token_id}, (html) ->
        $("section[data-section='#{data['token_id']}'] .connectors").append($(html))
      , 'html')
      console.log event

    deleteItem: (event) ->
      data = $.parseJSON(event.data)
      $("section[data-section='#{data['token_id']}'] div[data-id='#{data['id']}']").fadeOut().remove()

    setConnectorState: (event) ->
      data = $.parseJSON(event.data)
      row = $(".connector[data-id=\"" + data["args"][0] + "\"]")
      if data["args"][1] == "on"
        row.find('.connected-state').removeClass('state-disabled')
        row.find('.connect').show()
      else
        row.find('.connected-state').addClass('state-disabled')
        row.find('.connect').hide()

    open: (event) =>
      console.log "opened: " + @es.url

    message: (event) ->
      console.log event.data

    error: (event) ->
      console.log "closed"

    focusReveal: (ev) ->
      el = $(ev.currentTarget)
      el.find('.connection-string').focus()

    clearReveal: (ev) ->
      el = $(ev.currentTarget)
      el.find('input.input').val('')

    openUpdateReveal: (ev) ->
      ev.preventDefault()
      el = $(ev.currentTarget)
      modal = $("#update-tunnel-modal-#{el.data('access_id')}")
      modal.find('input.cname').val(el.data('cname'))
      modal.find('input.subdomain').val(el.data('subdomain'))
      if el.data('cname') == ''
        modal.find('.for-local').removeClass('hide')
        modal.find('.for-remote').addClass('hide')
        modal.find('.hosting-type option[value="local"]').prop('selected', true)
      else
        modal.find('.for-local').addClass('hide')
        modal.find('.for-remote').removeClass('hide')
        modal.find('.hosting-type option[value="remote"]').prop('selected', true)
      modal.find('.connection-string').val(el.data('connection-string'))
      form = modal.find('form')
      form.data('action', "#{form.data('action-base')}/#{el.data('id')}")
      modal.find('input.access_id').val(el.data('access-id'))
      modal.foundation('reveal','open')

    updateReveal: (ev) ->
      modal = $(ev.currentTarget)
      modal.find('input.subdomain').autoGrow(2)
      connection_string = modal.find('.connection-string').val()
      modal.find('.connection-string').focus().val('').val(connection_string)

    changeHostingType: (ev) ->
      el = $(ev.currentTarget)
      if el.val() == 'local'
        $('.for-remote').addClass('hide')
        $('.for-local').removeClass('hide')
      else
        $('.for-local').addClass('hide')
        $('.for-remote').removeClass('hide')

    showComputer: (ev) ->
      ev.preventDefault()
      el = $(ev.currentTarget)
      @sections.find("section[data-section='#{el.data('section')}']").show().siblings().hide()
      @menu.close()
      li = el.parent()
      if @menu.secondaryMenu.has(li).length > 0
        li = @menu.primaryMenu.find("a[data-section='#{el.data('section')}']").parent()
        li.prependTo(@menu.primaryMenu)
        @menu.refresh()
      li.parent().find('.active').removeClass('active')
      li.find('a').addClass('active')

    pjaxEnd: (ev) ->
      @$('.inline-input input').autoGrow(2)
      @$('.stopwatch').each (i, el) =>
        @startWatch($(el))

    startWatch: (el, time) ->
      stopwatch = el.find('span[data-start]')
      @stopwatches.push stopwatch
      time ||= Number(stopwatch.data('start'))*1000
      if time > 0
        incrementTime = 500 # Timer speed in milliseconds
        stopwatch.data('startTime', time)
        updateTimer = =>
          $.each(@stopwatches, (i, el) =>
            el.html(@formatTime( Math.round(((+new Date()) - el.data('startTime')) /10) ))
          )
        updateTimer()
        timer = @makeTimer(el, updateTimer, incrementTime, true)
        el.bind('stop', =>
            currentTime = 0
            @stopwatches.splice( $.inArray(el, @stopwatches), 1)
            #timer.stop()
            el.hide()
        )
        el.hide().removeClass('hide').fadeIn('slow')

    pad : (number, length) ->
      str = "" + number
      str = "0" + str  while str.length < length
      str

    formatTime : (time) =>
      hr = parseInt(time / 360000)
      min = parseInt(time / 6000) - (hr * 60)
      sec = parseInt(time / 100) - (min * 60) - (hr * 3600)
      #hundredths = pad(time - (sec * 100) - (min * 6000), 2)
      ((if hr > 0 then "#{@pad(hr, 2)}:" else "")) + ((if min > 0 then @pad(min, 2) else "00")) + ":" + @pad(sec, 2) # + ":" + hundredths

    makeTimer : (el, func, time, autostart, @init=false) =>
      @set = (func, time, autostart) ->
        @init = true
        if typeof func is "object"
          paramList = ["autostart", "time"]
          for arg of paramList
            eval_ paramList[arg] + " = func[paramList[arg]]"  unless func[paramList[arg]] is `undefined`
          func = func.action
        @action = func  if typeof func is "function"
        @intervalTime = time  unless isNaN(time)
        if autostart and not @isActive
          @isActive = true
          @setTimer()
        this

      @once = (time) ->
        timer = this
        time = 0  if isNaN(time)
        window.setTimeout (->
          timer.action()
        ), time
        this

      @play = (reset) ->
        unless @isActive
          if reset
            @setTimer()
          else
            @setTimer @remaining
          @isActive = true
        this

      @pause = ->
        if @isActive
          @isActive = false
          @remaining -= new Date() - @last
          @clearTimer()
        this

      @stop = ->
        @isActive = false
        @remaining = @intervalTime
        @clearTimer()
        this

      @toggle = (reset) ->
        if @isActive
          @pause()
        else if reset
          @play true
        else
          @play()
        this

      @reset = ->
        @isActive = false
        @play true
        this

      @clearTimer = ->
        window.clearTimeout @timeoutObject

      @setTimer = (time) ->
        timer = this
        return  unless typeof @action is "function"
        time = @intervalTime  if isNaN(time)
        @remaining = time
        @last = new Date()
        @clearTimer()
        @timeoutObject = window.setTimeout(->
          timer.go()
        , time)

      @go = ->
        if @isActive
          @action()
          @setTimer()

      if @init
        new @makeTimer(func, time, autostart)
      else
        @set func, time, autostart
        this

