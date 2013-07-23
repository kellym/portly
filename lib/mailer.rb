class Mailer

  def initialize(render_view)
    @render = render_view
    @mail = Mail.new
    mail.from = 'Portly <support@getportly.com>'
    mail.content_type = 'text/html; charset=UTF-8'
  end

  def mail
    @mail
  end

  def deliver
    render = File.read(ROOT_PATH + "/views/mailers/#{self.class.name.underscore}/#{@render}.haml")
    layout = File.read(ROOT_PATH + "/views/layouts/email.haml")
    mail.body = Haml::Engine.new(layout).render(self, {mail: mail}) do
      Haml::Engine.new(render).render(self, {mail: mail})
    end
    mail.deliver!
  end

  def self.create(method, *args)
    body = method.to_sym
    mailer = self.new(body)
    mailer.send(method, *args)
    mailer
  end

  def self.method_missing(*args)
    args.unshift self.name
    args.unshift SecureRandom.hex
    Redis.current.lpush('email_monitor', args.to_msgpack)
    true
  end

end
