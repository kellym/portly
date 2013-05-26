@namespace 'Portly', -> @namespace 'Forms', -> @namespace 'Views', ->
  class @CreditCard extends Backbone.View

    el: 'form.stripe-form'

    events:
      'submit': 'submitForm'
      'change .card-cvc' : 'validateForm'
      'keyup .card-cvc': 'validateForm'
      'change select': 'validateForm'
      'keyup select': 'validateForm'

    initialize: (args) =>

      @post_url = args.post
      Stripe.setPublishableKey args.key
      @number = @$('.card-number')
      @button = @$('button')
      @cvc = @$('.card-cvc')
      @expmo = @$('.card-exp-month')
      @expyr = @$('.card-exp-year')
      @number.validateCreditCard((result) =>
        if result.card_type
          @$(".card-icon.#{result.card_type.name}").removeClass('disabled').siblings().addClass('disabled')
          if result.luhn_valid && result.length_valid
            console.log 'valid'
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
      console.log 'validating'
      if @number.data('valid') && @cvc.val().length == (if @number.data('type') == 'amex' then 4 else 3) && @expmo.val() != 'Month' && @expyr.val() != 'Year'
        @button.prop('disabled', false)
      else
        @button.prop('disabled', true)

    submitForm: (ev) ->
      ev.preventDefault()
      @button.prop('disabled', true).text('Submitting information...')
      Stripe.createToken(@$el, @handleToken)

    handleToken: (status, response) ->
      if status == 200
        # send this response on to us
        $.post(@post_url, response.serialize())
      else
        # handle the error
        console.log status
        console.log response
