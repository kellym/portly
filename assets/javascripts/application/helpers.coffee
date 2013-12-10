window.Handlebars.registerHelper "select", (value, options) ->
  $el = $("<select />").html(options.fn(this))
  $el.find("[value=" + value() + "]").attr selected: "selected"
  $el.html()

