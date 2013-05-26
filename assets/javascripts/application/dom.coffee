@namespace 'Portly', -> @namespace 'DOM', ->
  class @Index extends Backbone.View

    el: 'body'

    events:
      'click .trigger': 'togglePane'
      'click .close-reveal': 'closeReveal'
      'click a[data-delete]': 'deletePath'
      'click a[data-pjax]': 'pjaxClick'

    togglePane: (ev) ->
      ev.preventDefault()
      el = $(ev.currentTarget)
      pane = el.closest('.toggle')
      state = pane.data('state') || false

      if state == false
        hide = pane.find('.hide')
        hide.removeClass('hide').show()
        pane.find('.show').hide()
        pane.data('state', hide)
      else
        state.addClass('hide').hide()
        pane.find('.show').show()
        pane.data('state', false)

    closeReveal: (ev) ->
      ev.preventDefault()
      $(ev.currentTarget).closest('.reveal-modal').foundation('reveal', 'close')

    deletePath: (ev) ->
      ev.preventDefault()
      el = $(ev.currentTarget)
      $.ajax
        type: 'DELETE'
        url: el.data('delete')
        dataType: 'json'
        success: (data, status) =>
          window.location.reload()
        error: (xhr, error_type, error) =>
          alert("We couldn't do that right now, sorry!")

    pjaxClick: (ev) ->
      ev.preventDefault()
      container = $(ev.currentTarget).data('container')
      $.pjax.click(ev,
        container: container
        fragment: container
      )
