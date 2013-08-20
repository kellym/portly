@namespace 'Portly', -> @namespace 'Forms', -> @namespace 'Views', ->
  class @CreditCard extends Backbone.View

    el: 'form.stripe-form'

    events:
      'submit'              : 'submitForm'
      'change .card-cvc'    : 'validateForm'
      'keyup .card-cvc'     : 'validateForm'
      'change .card-number' : 'validateForm'
      'keyup .card-number'  : 'validateForm'
      'change select'       : 'validateForm'
      'keyup select'        : 'validateForm'

    initialize: (args) =>

      @post_url = args.post
      @success_url = args.success
      Stripe.setPublishableKey args.key
      @number = @$('.card-number')
      @button = @$('button')
      @cvc = @$('.card-cvc')
      @expmo = @$('.card-exp-month')
      @expyr = @$('.card-exp-year')
      @original_button_text = @button.text()
      @number.validateCreditCard((result) =>
        if @number.val().indexOf('*') > -1
          @number.data('valid', true)
          return true
        if result.card_type
          @$(".card-icon.#{result.card_type.name}").removeClass('disabled').siblings().addClass('disabled')
          if result.luhn_valid && result.length_valid
            @number.data('valid', true)
            @number.data('type', result.card_type.name)
          else
            @number.data('valid', false)
            @number.data('type', '')
        else
          @$('.card-icon').addClass('disabled')
        @validateForm
      )

    validateForm:  =>
      if @number.data('valid') && @cvc.val().length == (if @number.data('type') == 'amex' then 4 else 3) && @expmo.val() != 'Month' && @expyr.val() != 'Year'
        @button.prop('disabled', false)
      else
        @button.prop('disabled', true)

    submitForm: (ev) =>
      ev.preventDefault()
      @button.prop('disabled', true)
      if @number.val().indexOf('*') > -1
        @button.text('Submitting information...')
        $.post(@post_url, @$el.serialize())
          .success( =>
            window.location = @success_url
          ).fail( =>
            @button.prop('disabled', false)
            @button.text(@original_button_text)
            alert('There was an error processing your request. Please verify your information is correct.')
          )
        return true
      else
        card = {
          number: @number.val(),
          cvc: @cvc.val(),
          expMonth: @expmo.val(),
          expYear: @expyr.val()
        };
        @button.text('Submitting information...')
        Stripe.createToken(card, @handleToken)

    handleToken: (status, response) =>
      if status == 200
        # send this response on to us
        response['billing_period'] = $('input[name=billing_period]:checked').val()
        response['plan'] = $('input[name=plan]').val()
        $.post(@post_url, response)
          .success( =>
            window.location = @success_url
          ).fail( =>
            @button.prop('disabled', false)
            @button.text(@original_button_text)
            alert('There was an error processing your request. Please verify your information is correct.')
          )
      else
        # handle the error
        alert('There was an error processing your request. Please verify your information is correct.')
