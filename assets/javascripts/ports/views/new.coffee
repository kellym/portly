@namespace 'Portly', -> @namespace 'Ports', ->
  class @NewView extends Backbone.View

    el: '#ports'

    events:
      #'click [data-action=new]'           : 'newPort'
      'submit form[data-action=create]'   : 'createPort'

    template: Handlebars.templates['ports.new']

    initialize: (args) ->
      @collection = args.collection
      @model = new Portly.Port
      @model.setDomain @collection.domain
      @model.setComputer @collection.computer
      @render()

    render: ->
      modal = $ @template(@model)
      modal.appendTo $(@collection.el)
      modal.modal
        afterOpen: =>
          modal.find('input.subdomain').autoGrow(2)
          modal.find('.connection-string').focus()
        onClose: =>
          modal.remove()
          @undelegateEvents()
          @collection.destroyNewView

    createPort: (e) ->
      e.preventDefault()
      form = $(e.currentTarget)
      $.each(form.serializeArray(), (k,v) =>
        @model.set(v.name, v.value)
      )
      @model.save(null,
        success: =>
          $.modal.close()
          @collection.addNewModel @model
      )



