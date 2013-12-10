@namespace 'Portly', -> @namespace 'DOM', ->
  class @Index extends Backbone.View

    el: 'body'

    events:
      'click .trigger'       : 'togglePane'
      'click a[data-delete]' : 'deletePath'
      'mouseover .copyable'  : 'setClipboardContent'
      'update'               : 'setupContent'
      'change .masked-radios input': 'toggleRadioClass'

    initialize: ->
      $(document).keydown (e) =>
        @selectClipboard(e)
      $(document).keyup (e) =>
        @deselectClipboard(e)
      $('.tooltipped').tipsy()
      $('.tooltipped-top').tipsy({ gravity : 's', offset: 10})
      $('.btn-group').dropdown()
      @setupContent()

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

    setMaskedRadios: (selector) ->
      selector ?= $('.masked-radios')
      $('input:checked', selector).each ->
        $(@).closest('label').addClass('selected')
      $('input:not(:checked)', selector).each ->
        $(@).closest('label').removeClass('selected')

    toggleRadioClass: (ev) =>
      @setMaskedRadios $(ev.currentTarget).closest('.masked-radios')

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

    setupContent: (ev) ->
      $('.copyable').attr('title', "Press #{if navigator.userAgent.indexOf('Mac') is -1 then 'Ctrl' else '&#8984;'} + C to copy")
      $('.copyable').tipsy(gravity: 's', offset: 10)

    setClipboardContent: (ev) ->
      el = $(ev.currentTarget)
      @clipboard = el.data('copyable') || el.text()

    selectClipboard: (e) =>
      # Only do this if there's something to be put on the clipboard, and it
      # looks like they're starting a copy shortcut
      if !@clipboard || !(e.ctrlKey || e.metaKey)
        return

      if $(e.target).is("textarea")
        return

      # Abort if it looks like they've selected some text (maybe they're trying
      # to copy out a bit of the description or something)
      if window.getSelection?()?.toString()
        return

      if document.selection?.createRange().text
        return

      _.defer =>
        $clipboardContainer = $("#clipboard-container")
        $clipboardContainer.empty().show()
        $("<textarea id='clipboard'></textarea>").val(@clipboard).appendTo($clipboardContainer).focus().select()

    deselectClipboard: (e) ->
      if $(e.target).is("#clipboard")
        $("#clipboard-container").empty().hide()


