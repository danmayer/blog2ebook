web: bundle exec rackup -p $PORT
redis: redis-server > log/redis.log
log: touch log/sinatra.log; tail -f log/sinatra.log