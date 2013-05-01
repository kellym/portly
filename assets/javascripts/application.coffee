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
