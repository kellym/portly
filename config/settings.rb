App.config = {
  defaults: {
    app_string: 'com.fully.portly',
    client_id: 'c0209d3eafecd05f2f8f7',
    client_secret: '26a1f643c98aa11c44539ebcab67ee6ae211834c776d431f669931fa1e02379a5',
    authentication: {
      pepper:    'LfyutEhrLJqn4UushzvZCefeM3AJC7E2DW7BKwYBQhrvLUHt8fv3PfxecafvSFdmXX5bJ4DrcF8mss9gWxhzRnysHVzVqvmarxYv',
      stretches: 10
    },
    memcache: {
      namespace: 'com.fully.portly',
      expires: nil
    },
    site: {
      title: 'Portly'
    },
    suffix: '.portly.co',
    authorized_keys_path: '/home/portlyuser/.ssh/authorized_keys2',
    event_server: {
      host: '0.0.0.0',
      port: 443
    },
    stripe_publishable_key: 'pk_test_eYBXSPksy20ywx0y50AtHXKE',
    cname_domain: 'tunnel.portly.co',
    github_key: ENV['GITHUB_KEY'] || '63b8753bc6ae55e1d562',
    github_secret: ENV['GITHUB_SECRET'] || '0cabe128001ed4f6106a0582cf43ffab05feca98',
    mail: {
      address: 'localhost',
      port: '20025',
      #user_name: ENV['GMAIL_SMTP_USER'],
      #password: ENV['GMAIL_SMTP_PASSWORD'],
      #authentication: :plain,
      #enable_starttls_auto: true
    },
    assets_path: './public/assets/'

  },
  development: {
    forwarding_server: {
      localhost: 'localhost',
      host: 'localhost',
      user: 'portlyuser'
    },
    authorized_keys_path: '/Users/portlyuser/.ssh/authorized_keys',
  },
  staging: {

  },
  production: {
    forwarding_server: {
      localhost: 'localhost',
      host: 'getportly.com',
      user: 'portlyuser'
    },
    mail: {
      address: 'smtp.mandrillapp.com',
      port: 587,
      user_name: 'kellymartinv@gmail.com',
      password: 'F9Pz77iRVP6q1jUYFF90fg'
    }
  },
  test: {}
}
