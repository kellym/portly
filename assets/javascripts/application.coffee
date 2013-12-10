#= require vendor/custom.modernizr.js
#= require vendor/jquery
#= require vendor/smartquotes
#= require vendor/json2
#= require vendor/underscore
#= require vendor/backbone
#= require vendor/creditcard
#= require vendor/autogrow
#= require vendor/modal
#= require vendor/menu
#= require vendor/responsive-nav
#= require vendor/tipsy
#= require vendor/dropdown
#= require application/core
#= require application/dom
#= require forms
#= require vendor/wysihtml5
#= require vendor/wysihtml5-foundation
#= require vendor/highlight
#= require vendor/handlebars.runtime-v1.1.2.js
#= require application/helpers
window.onunload = -> {}


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
        $.modal.close()
        window.location.reload() if el.data('reload')
    )
  )
  $('.wysihtml5').wysihtml5()
