window.namespace = (name, fn) ->
  if not @[name]?
    this[name] = {}
  if not @[name].namespace?
    @[name].namespace = window.namespace
  fn.apply this[name], []

