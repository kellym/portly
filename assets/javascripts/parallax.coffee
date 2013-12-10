# shim layer with setTimeout fallback
window.requestAnimFrame = (->
  window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or window.oRequestAnimationFrame or window.msRequestAnimationFrame or (callback) ->
    window.setTimeout callback, 1000 / 60
)()
$ ->
  ((win, d) ->
    onResize = ->
      canvas.width = window.innerWidth
      canvas.height = window.innerHeight
      updateElements win.scrollY
    onScroll = (evt) ->
      unless ticking
        ticking = true
        requestAnimFrame performScroll
        lastScrollY = win.scrollY
    updateElements = ->
      context.fillStyle = "#ffffff"
      context.fillRect 0, 0, canvas.width, canvas.height
      width = (if canvas.width > 1015 then canvas.width else 1015)
      height = width * bg.height / bg.width
      performScroll()
    performScroll = ->
      if lastScrollY > demo_top
        canvas.height = 0
        ticking = false
      else
        canvas.height = window.innerHeight
        relativeY = lastScrollY * 0.000333
        context.drawImage bg, 0, pos(0, -800, relativeY, 0), width, height
        ticking = false
    pos = (base, range, relY, offset) ->
      base + limit(0, 1, relY - offset) * range
    prefix = (obj, prop, value) ->
      prefs = ["webkit", "Moz", "o", "ms"]
      for pref of prefs
        obj[prefs[pref] + prop] = value
    limit = (min, max, value) ->
      Math.max min, Math.min(max, value)
    $ = d.querySelector.bind(d)
    bg = $(".background")
    demo = $(".demo img")
    canvas = $("#main-canvas")
    demo_canvas = $("#demo-canvas")
    context = canvas.getContext("2d")
    demo_context = canvas.getContext("2d")
    demo_top = jQuery(".demo-top").offset().top
    stripe = $("aside")
    ticking = false
    lastScrollY = 0
    width = undefined
    height = undefined
    win.addEventListener "load", onResize, false
    win.addEventListener "resize", onResize, false
    win.addEventListener "scroll", onScroll, false
  ) window, document

