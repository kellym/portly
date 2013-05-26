@namespace 'Portly', -> @namespace 'Forms', -> @namespace 'Views', ->
  class @Login extends Backbone.View

    el: 'form.login-form'

    events:
      'submit': 'submitForm'

    initialize: (args) ->
      @post_url = args.post
      @button = @$('button')

    submitForm: (ev) ->
      ev.preventDefault()
      @button.prop('disabled', true).text('Submitting information...')
      $.ajax
        type: 'POST'
        url: @post_url
        data: @$el.serialize()
        dataType: 'json'
        success: (data, status) =>
          @$('input').removeClass('error')
          @$('small.error').remove()
          @$('input[name=password]').val('')
          @$('input[name=password_confirmation]').val('')
          @button.prop('disabled', false).text('Save')
          $('.login-email').text(@$('input[name=email]').val())
          @$('.trigger').trigger('click')
        error: (xhr, error_type, error) =>
          @$('input').removeClass('error')
          @$('small.error').remove()
          @button.prop('disabled', false).text('Save')
          data = $.parseJSON(xhr.responseText)
          for attr, err of data.errors
            a = @$("input[name=#{attr}]")
            a.addClass 'error'
            error_text = if a.siblings('small.error').length then a.siblings('small.error') else $('<small class="error" />')
            error_text.text(err[0])
            error_text.insertAfter(a)


