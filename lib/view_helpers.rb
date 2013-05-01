module ViewHelpers

  def link_to(*args)
    opts = args.extract_options!
    opts[:href] = args.pop if args.length > 1
    a = "<a "
    opts.each do |k,v|
      a << "#{k}=\"#{v.gsub('"','&quot;')}\" "
    end
    a << ">#{args[0] || yield}</a>"
  end

  # Public: Generates a navigational link for the views.
  # If a block is passed to this method and a title has already been set
  # for this link, it will set the active
  # class on the parent link if any child is active.
  #
  # *args - a variable list of arguments that matches those of link_to
  #
  # Examples:
  #   %li
  #     = nav_link_to 'Nav with subnav', '/nav' do
  #       %ul#subnav
  #   %li
  #     = nav_link_to '/nav2' do
  #       = 'Nav with interpreted title'
  #
  # Returns a String of a link with optional additional navigational links.
  def nav_link_to(*args)
    opts = args.extract_options!
    (opts[:class] ||= '') << ' nav-item'
    path = request.env['REQUEST_PATH']
    @nav_depth ||= 0
    @nav_depth += 1
    @subnav_active = false if @nav_depth == 1
    if path == args.last || (opts[:restful] && path.match(/^#{path}\/[^\/]*(\/edit)?/))
      @subnav_active = true
    end
    if block_given?
      if args.length == 1
        args.unshift capture_haml { yield }
        subnav = ''
      else
        subnav = block_given? ? capture_haml { yield } : ''
      end
    else
      subnav = ''
    end
    args[0]="<span>#{args[0]}</span>"
    opts[:class] << ' active' if @subnav_active
    args << opts
    @nav_depth -= 1
    link_to(*args) + subnav
  end
end
