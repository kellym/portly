redis: redis-server ./config/redis.conf
#web: bundle exec shotgun config.ru
web: bundle exec thin start -p 9393
##web: bundle exec rainbows -p 9393 -E production -c /Users/kelly/w/portly/config/rainbows/rainbows.rb
#nginx: echo '3dhopper/' | sudo -S nginx -c /Users/kelly/w/portly/config/nginx/development.conf
event_machine: sleep 2 && ruby server.rb
#web: bundle exec rackup config.ru -p 9393
post_office: bundle exec post_office --pop 20110 --smtp 20025

