# levee_watch

## Prerequisites
Ruby
bundler
Redis

## Running
For development:
foreman start
ruby start_levee_watch.rb

## Caution
Redis caches job definitions so if you update your job class you should clear data in Redis. You can do this by starting redis-cli and executing FLUSHALL command that clears all data in Redis. Be carefull if you use Redis also for other projecets.
