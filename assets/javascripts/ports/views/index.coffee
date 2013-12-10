@namespace 'Portly', -> @namespace 'Ports', ->
  class @IndexView extends Backbone.View

    el: '#ports'

    events:
      'click [data-action=new]'      : 'newPort'
      'click .dropdown a'            : 'changeComputer'
      'mousedown .inline-input'      : 'focusInlineInput'
      'blur .inline-input input'     : 'unfocusInlineInput'

    actions_template:     Handlebars.templates['ports._actions']
    blank_slate_template: Handlebars.templates['ports.blank_slate']
    computers_template:   Handlebars.templates['computers._dropdown']

    initialize: (args) ->
      @domain = args.domain

      # set up the computers lists
      @computers = args.computers
      @_computer_view = $ @computers_template(@computers)

      @computer = @computers.current()
      @token = @computer.id if @computer

      @refresh()
      @listenTo(@collection, 'reset', @refresh)
      @listenTo @computers, 'sync', @refresh_computers

    changeComputer: (ev) ->
      ev.preventDefault()
      $(ev.currentTarget).trigger('close')
      Backbone.history.navigate $(ev.currentTarget).attr('href'),
        trigger: true

    refresh: ->
      # set up the ports lists
      @computer = @computers.current()
      if @computer
        @collection.setComputer @computer
        @token = @computer.id
      @_views = []
      @collection.each (model) =>
        model.setDomain @domain
        @_views.push(new Portly.Ports.RowView( model: model, collection: @ ))
        @listenTo model, 'sync', @render

      @render()

    refresh_computers: ->
      @computer = @computers.current()
      @token = @computer.id if @computer

      @_computer_view = $ @computers_template(@computers)
      @render()

    render: ->
      if @computers.length == 0
        return
      @undelegateEvents()
      @$el.empty()
      @$el.append @_computer_view
      @_computer_view.find('.btn-group').dropdown() if @computers.more_than_one()
      if @_views.length == 0
        @$el.append @blank_slate_template(self)
      else
        sorted_views = _.sortBy(@_views, (subview) ->
          subview.model.domain()
        )
        if sorted_views.length < 10
          compression = "#{21 - ( 10 / (10 - sorted_views.length)) }px"
        else
          compression = '10px'
        _.each sorted_views, (subview) =>
          el = $(subview.render().el)
          el.css(paddingTop: compression, paddingBottom: compression)
          @$el.append el
        @$el.append @actions_template()
      @delegateEvents()

    newPort: (e) ->
      e.preventDefault()
      @new_view = new Portly.Ports.NewView(collection: @)

    destroyNewView: ->
      delete @new_view if @new_view

    removeView: (view) ->
      i = @_views.indexOf view
      @_views.splice i, 1
      @render()

    addNewModel: (model) ->
      model.setComputer @computer
      @collection.add model
      @_views.push(new Portly.Ports.RowView(model: model, collection: @))
      @listenTo model, 'sync', @render
      @render()
      @destroyNewView()

    focusInlineInput: (ev) ->
      return true if $(ev.target).hasClass('input')
      ev.preventDefault()
      $(ev.currentTarget).addClass('focus').find('input').focus()

    unfocusInlineInput: (ev) ->
      $(ev.currentTarget).closest('.inline-input').removeClass('focus')


