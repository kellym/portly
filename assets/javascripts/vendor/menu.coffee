$.fn.overflowmenu = (options) ->
  @options = $.extend(
    items: "li"
    itemsParentTag: "ul"
    label: "more"
    appendTo: false

    #call the refresh method when this element changes size, with out a special event window is the only element that this gets called on
    refreshOn: $(window)

    #attempt to guess the height of the menu, if not the target element needs to have a height
    guessHeight: true

    #clone helper, since http://api.jquery.com/clone/ still keeps a reference to the original data if its an object or an array, you many need to add your own cloning method by doing something like this:
    #
    #		 * lifted from  http://api.jquery.com/clone/
    #		 *
    #		 * var $elem = $('#elem').data( "arr": [ 1 ] ), // Original element with attached data
    #		    $clone = $elem.clone( true )
    #		    .data( "arr", $.extend( [], $elem.data("arr") ) ); // Deep copy to prevent data sharing
    #		 *
    #		 * elements are a jquery collection of items  that will be displayed in the secondaryMenu
    #		 * has to return a jquery collection
    #
    clone: ($elements) ->
      $elements.clone true, true
  , options)

  $(@).bind('open', @options.open) if @options.open

  @_create = =>
    $(@).addClass "overflowmenu"
    @primaryMenu = $(@).find(@options.itemsParentTag).addClass("jb-overflowmenu-menu-primary jb-overflowmenu-helper-position")
    @_setHeight()

    #TODO: allow the user to change the markup for this because they might not be using ul -> li
    @secondaryMenuContainer = $(["<div class=\"nav-overflowmenu-container\">", "<a href=\"#\" class=\"#{@options.handleClass} nav-overflowmenu-handle\"></a>", "<" + @options.itemsParentTag + " class=\"nav-overflowmenu\"></" + @options.itemsParentTag + ">", "</div>"].join(""))
    @secondaryMenu = @secondaryMenuContainer.find("ul").hide()
    @secondaryMenuContainer.children("a").bind "click.overflowmenu", (e) =>
      e.preventDefault()
      @toggle()
    @secondaryMenuContainer.appendTo(@options.appendTo || @primaryMenu.parent())

    #has to be set first
    @_setOption "label", @options.label
    @_setOption "refreshOn", @options.refreshOn

  @destroy = ->
    @$.removeClass "overflowmenu"
    @primaryMenu.removeClass("nav-overflowmenu-main").find(@options.items).filter(":hidden").css "display", ""
    @options.refreshOn.unbind "resize.overflowmenu"
    @secondaryMenuContainer.remove()

    #TODO: possibly clean up the height & right on the ul
    #$.Widget::destroy.apply this, arguments_

  @refresh = =>
    $(@).trigger "beforeChange", {}, @_uiHash()
    vHeight = @primaryMenuHeight

    #get the items, filter out the the visible ones
    itemsToHide = @_getItems().css("display", "").filter(->
      @offsetTop + $(@).height() > vHeight
    )

    #remove all of the actions out of the overflow menu
    @secondaryMenu.children().remove()
    @options.clone.apply(this, [itemsToHide]).prependTo @secondaryMenu

    #hide the original items
    itemsToHide.css "display", "none"
    if itemsToHide.length is 0
      @close()
      @secondaryMenuContainer.hide()
    else
      @secondaryMenuContainer.show()

    $(@).trigger "change", {}, @_uiHash()
    @


  #more menu opitons
  @open = ->
    return  if @secondaryMenu.find(@options.items).length is 0
    @secondaryMenuContainer.show()
    @secondaryMenu.show()
    $(@).trigger "open", {}, @_uiHash()
    this

  @close = ->
    @secondaryMenu.hide()
    $(@).trigger "close", {}, @_uiHash()
    this

  @toggle = ->
    if @secondaryMenu.is(":visible")
      @close()
    else
      @open()
    this

  @_getItems = ->
    @primaryMenu.find @options.items

  @_setHeight = =>
    if @options.guessHeight
      #get the first items height and set that as the height of the parent
      @primaryMenuHeight = @primaryMenu.outerHeight()
      @primaryMenu.css "height", @primaryMenuHeight
    else
      @primaryMenuHeight = $(@).innerHeight()

  @_setOption = (key, value) =>
    if key is "refreshOn" and value
      @options.refreshOn.unbind "resize.overflowmenu"
      @options.refreshOn = $(value).bind("resize.overflowmenu", =>
        @refresh()
      )

      #call to set option
      @refresh()
    else if key is "label" and value
      #figure out the width of the hadel and subtract that from the parend with and set that as the right
      width = @secondaryMenuContainer.find(".nav-overflowmenu-handle").html(value).outerWidth()
      @primaryMenu.css "right", width
    #$.Widget::_setOption.apply this, arguments_

  @_uiHash = ->
    primary: @primaryMenu
    secondary: @secondaryMenu
    container: @secondaryMenuContainer

  @_create()
  @
