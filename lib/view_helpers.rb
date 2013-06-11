module ViewHelpers

  def content_for(key, &block)
    @content_for ||= Hash.new {|h, k| h[k] = [] }
    if block_given?
      @content_for[key] << block
    else
      content = ''
      @content_for[key].each do |b|
        content << capture_haml(&b)
      end
      content
    end
  end

  def link_to(*args)
    opts = args.extract_options!
    opts[:href] = args.pop if args.length > 1
    a = "<a "
    opts.each do |k,v|
      a << "#{k}=\"#{v.to_s.gsub('"','&quot;')}\" "
    end
    a << "><span>#{args[0] || yield}</span></a>"
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

    if path == args.last || (opts[:restful] && path.match(/^#{args.last}\/[^\/]+(\/edit)?$/))
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

  def javascript_include_tag(file)
    if ENV['RACK_ENV'] == 'production'
      %[<script type="text/javascript" src="/assets/#{file}.#{ENV['ASSETS_VERSION']}.js"></script>]
    else
      %[<script type="text/javascript" src="/assets/#{file}.js"></script>]
    end
  end

  def stylesheet_include_tag(file)
    if ENV['RACK_ENV'] == 'production'
      %[<link href="/assets/#{file}.#{ENV['ASSETS_VERSION']}.css" rel="stylesheet" />]
    else
      %[<link href="/assets/#{file}.css" rel="stylesheet" />]
    end
  end

  def human_number(number)
    return 0 if number.nil?
    number = Integer(number)
    result = number.to_s

    if number < 1048576
      number = number / 1024
      result = "#{number.to_s} KB"
    elsif number >= 1048576
      number = number / 1048576
      result = "#{number.to_s} MB"
    end

    result
  end

end
