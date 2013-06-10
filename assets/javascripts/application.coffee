#= require vendor/custom.modernizr.js
#= require vendor/zepto
#= require vendor/json2
#= require vendor/underscore
#= require vendor/backbone
#= require vendor/creditcard
#= require vendor/autogrow
#= require vendor/menu
#= require vendor/pjax
#= require vendor/tipsy
#= require foundation/index
#= require application/core
#= require application/dom
#= require application/stopwatch
#= require forms
$ ->
  signin_box = $("#signin")
  $(".signin-button").dblclick((e) ->
    signin_email = $("#signin .email")
    signin_password = $("#signin .password")
    $("#signin form").submit()  if signin_email.val() isnt "" and signin_password.val() isnt ""
  ).click (e) ->
    e.preventDefault()
    if signin_box.hasClass("open")
      console.log "close it"
      signin_box.removeClass("open").hide()
    else
      signin_box.addClass("open").show()

  $('form[data-action], form.ajax-form').submit((e) ->
    e.preventDefault()
    el = $(e.currentTarget)
    el.ajaxSubmit(
      url: el.data('action')
      type: el.attr('method')
      data: el.serialize()
      dataType: 'json'
      success: (data) =>
        el.parent().foundation('reveal', 'close')
        window.location.reload() if el.data('reload')
    )
  )
