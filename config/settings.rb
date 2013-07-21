App.config = {
  defaults: {
    app_string: 'com.fully.portly',
    client_id: 'c0209d3eafecd05f2f8f7',
    client_secret: '26a1f643c98aa11c44539ebcab67ee6ae211834c776d431f669931fa1e02379a5',
    public_key: "getportly.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5kgL2OMp9nvRDGTlZDbKMSpEnEjDzcTdD9bE5BSfEvcTlhw1vCCqMjLwRqZRT2aMcdX8XelIeGBGmhYbleuioJ0qWe15rj/DPk4SWM7YARMo2xShSUdyM3X4zsbRmwlGLwFyWemM38rnz9wvdcg4AvtyPtI4ztmFTAYxSH3qaUwOcI5LnP8XzI5cjOTz3KRswX93Wovz/+mmTkcIBm7lUKvEDWANtS0P7dTdFCEbwCctoHIur/otYuF5X4X/MWnkh+R3N1SuuQHDkJpBj/vAD2Ou5ua7x2OFkkTt/H8pX8Iqcm9Q8fzprm8iOz9fRlOJeQREjuzCkgMhcKJlc4Inn\n",
    authentication: {
      pepper:    'LfyutEhrLJqn4UushzvZCefeM3AJC7E2DW7BKwYBQhrvLUHt8fv3PfxecafvSFdmXX5bJ4DrcF8mss9gWxhzRnysHVzVqvmarxYv',
      stretches: 10
    },
    memcache: {
      namespace: 'com.fully.portly',
      expires: nil,
      secure: true
    },
    site: {
      title: 'Portly'
    },
    suffix: '.portly.co',
    authorized_keys_path: '/home/portlyuser/.ssh/authorized_keys2',
    event_server: {
      host: '0.0.0.0',
      port: 8900
    },
    stripe_secret_key: 'sk_test_yYgPRbp3ijZjGEZ0IWHHz3T9',
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
    assets_path: './public/assets/',
    server_key_path: '/Users/kelly/w/portly/config/server/'
  },
  development: {
    memcache: {
      namespace: 'com.fully.portly',
      expires: nil,
      secure: false
    },
    forwarding_server: {
      localhost: 'localhost',
      host: 'localhost',
      user: 'portlyuser'
    },
    authorized_keys_path: '/Users/portlyuser/.ssh/authorized_keys',
    tmp_path: '/Users/kelly/w/portly/tmp/'
  },
  staging: {

  },
  production: {
    host: 'getportly.com',
    forwarding_server: {
      localhost: 'localhost',
      host: 'getportly.com',
      user: 'portly_user'
    },
    event_server: {
      host: '72.14.178.208',
      port: 8900
    },
    mail: {
      address: 'smtp.mandrillapp.com',
      port: 587,
      user_name: 'kellymartinv@gmail.com',
      password: 'F9Pz77iRVP6q1jUYFF90fg'
    },
    stripe_secret_key: 'sk_live_PCHtykd8a92Emk7MwWytkOov',
    stripe_publishable_key: 'pk_live_lj3AYsMDdlNPKWhmMtgZDUhr',
    authorized_keys_path: '/home/portly_user/.ssh/authorized_keys2',
    server_key_path: '/var/www/portly/current/config/server/',
    log_path: '/var/www/portly/shared/log/',
    tmp_path: '/var/www/portly/shared/tmp/'
  },
  test: {}
}
