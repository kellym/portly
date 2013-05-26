@namespace 'Portly', -> @namespace 'DOM', ->
  class @Stopwatch extends Backbone.View

    el: '.stopwatch'

    events:
      'start' : 'start'

    render: ->
      @delegateEvents()

    start: (ev) ->
      console.log 'hello'
      el = $(ev.currentTarget)
      stopwatch = el.find('span[data-start]')
      time = Number(stopwatch.data('start'))*1000
      if time > 0
        incrementTime = 500 # Timer speed in milliseconds
        startTime = time
        updateTimer = =>
          stopwatch.html(@formatTime( Math.round(((+new Date()) - startTime) /10) ))

        updateTimer()
        timer = @makeTimer(updateTimer, incrementTime, true)
        el.bind('stop', ->
            currentTime = 0
            timer.stop()
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
      ((if hr > 0 then @pad(hr, 2) else "00")) + ":" + ((if min > 0 then @pad(min, 2) else "00")) + ":" + @pad(sec, 2) # + ":" + hundredths

    makeTimer : (func, time, autostart) =>
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


