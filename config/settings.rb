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
      expires: 3600
    },
    site: {
      title: 'Portly'
    },
    suffix: '.aka.so',
    authorized_keys_path: '/home/portlyuser/.ssh/authorized_keys2',
    event_server: {
      host: '0.0.0.0',
      port: 8900
    }
  },
  development: {
    forwarding_server: {
      localhost: 'localhost',
      host: 'localhost',
      user: 'portlyuser'
    },
    authorized_keys_path: '/Users/portlyuser/.ssh/authorized_keys',
  },
  production: {
    forwarding_server: {
      localhost: 'localhost',
      host: 'getportly.com',
      user: 'portlyuser'
    }
  },
  test: {}
}
