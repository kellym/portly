SITEMAP = {
  home: {
    url: '/',
    priority: 1.0,
    controller: 'application',
    view: 'homepage.haml',
  },
  plans: {
    url: '/plans',
    priority: 0.8,
    controller: 'application',
    view: 'plans.haml',
  },
  support: {
    url: '/support',
    priority: 0.7,
    controller: 'application',
    view: 'support.haml',
  },
  blog: {
    url: '/blog',
    changefreq: 'daily',
    priority: 0.7,
    file: '/blog/sitemap.xml',
  },
  signin: {
    url: '/signin',
    priority: 0.5,
    changefreq: 'monthly',
    controller: 'application',
    view: 'signin.haml',
  },
  signup: {
    url: '/signup',
    priority: 0.9,
    changefreq: 'monthly',
    controller: 'application',
    view: 'signup.haml',
  },
  download: {
    url: '/download',
    priority: 0.6,
    controller: 'application',
    view: 'downloads/index.haml',
  },
  download_current: {
    url: '/downloads/current',
    changefreq: 'daily',
    priority: 0.5,
    lastmod: proc { Dir[ROOT_PATH + '/downloads'].map { |f| File.mtime(f) }.max }
  },
  terms: {
    url: '/terms',
    priority: 0.2,
    view: 'terms.haml',
    changefreq: 'monthly',
  },
}
