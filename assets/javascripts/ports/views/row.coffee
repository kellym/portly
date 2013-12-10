@namespace 'Portly', -> @namespace 'Ports', ->
  class @RowView extends Backbone.View

    tagName: 'div'
    className: 'row connector'

    events:
      'click a[data-action=connect]'    : 'handlePortConnection'
      'click a[data-action=edit]'       : 'editPort'
      'click a[data-action=destroy]'    : 'destroyPort'
      'submit form[data-action=update]' : 'saveModel'
      'submit form[data-action=destroy]': 'destroyModel'

    template: Handlebars.templates['ports.show']
    edit_template: Handlebars.templates['ports.edit']
    destroy_template: Handlebars.templates['ports.destroy']

    initialize: (args) ->
      @render
      @collection = args.collection
      @listenTo @model, 'reset', @render

    render: ->
      content = @template @model
      @$el.empty()
      @$el.html content
      @delegateEvents()
      @$el.find('.copyable').attr('title', "Press #{if navigator.userAgent.indexOf('Mac') is -1 then 'Ctrl' else '&#8984;'} + C to copy")
      @$el.find('.copyable').tipsy(gravity: 's', offset: 10)
      @

    editPort: (e) ->
      e.preventDefault()
      modal = $ @edit_template(@model)
      modal.prependTo(@$el)
      modal.modal
        afterOpen: =>
          modal.find('input.subdomain').autoGrow(2)
          modal.find('.connection-string').focus()
        onClose: ->
          modal.remove()

    saveModel: (ev) ->
      ev.preventDefault()
      form = $(ev.currentTarget)
      $.each(form.serializeArray(), (k,v) =>
        @model.set(v.name, v.value)
      )
      @model.save(null,
        success: =>
          $.modal.close()
      )

    destroyModel: (ev) ->
      ev.preventDefault()
      @model.destroy()
      @remove()
      @undelegateEvents()
      @collection.collection.remove @
      @collection.removeView @
      $.modal.close()

    destroyPort: (e) ->
      e.preventDefault()
      modal = $ @destroy_template(@model)
      modal.appendTo @$el
      modal.modal
        onClose: ->
          modal.remove()

    handlePortConnection: (e) ->
      e.preventDefault()
      return if $(e.currentTarget).hasClass 'disabled'
      $(e.currentTarget).addClass 'disabled'
      if @model.isConnected()
        $.ajax
          url: "/api/tunnels/#{@model.get 'id'}"
          type: "DELETE"
      else
        $.post "/api/tunnels", { id: @model.get('id') }
