redis: redis-server ./config/redis.conf
#web: bundle exec shotgun config.ru
web: bundle exec thin start -p 9393
#nginx: echo '3dhopper/' | sudo -S nginx -c /Users/kelly/w/portly/config/nginx/development.conf
event_machine: sleep 2 && ruby server.rb
#web: bundle exec rackup config.ru -p 9393

