@namespace 'Portly', -> @namespace 'Account', -> @namespace 'Views', ->
  class @Index extends Backbone.View

    el: 'body'

    events:
      'click a.add-api-key'  : 'addApiKey'
      'click .api-keys a'    : 'removeApiKey'

    initialize: ->
      true

    addApiKey: (ev) ->
      ev.preventDefault()
      href = "/api/keys"
      $.ajax
        url: href
        type: 'POST'
        data: {}
        dataType: 'json'
        success: (data) =>
          console.log data
          $('.api-keys').append("<div class='row small'><div class='large-7 columns strong code'>#{data['code']}</div><div class='large-5 columns text-right'><a href='#/delete'>Remove</a></div></div>")

    removeApiKey: (ev) ->
      ev.preventDefault()
      if window.confirm("You are about to permanently remove this key and disconnect any computers using this token.")
        href = "/api/keys/#{$(ev.currentTarget).closest('.row').find('.code').text()}"
        $.ajax
          url: href
          type: 'DELETE'
          dataType: 'json'
          success: (data) =>
            console.log data
            $(ev.currentTarget).closest('.row').remove()

