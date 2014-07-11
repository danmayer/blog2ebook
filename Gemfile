source 'https://rubygems.org'
gem 'rake'
gem 'sinatra'
gem 'json'
gem 'rest-client'
gem 'nokogiri'
gem 'sinatra-flash'
gem 'email_veracity'
gem 'redis'
gem 'addressable'
gem 'airbrake'
gem 'kindlegen'

# disabled for now but used to test other single article rendering methods
# gem 'pismo'
# gem "ruby-readability", :require => 'readability'

group :production do
  gem 'unicorn'
  gem 'newrelic_rpm'
end

group :test do
  gem 'rack-test'
  gem 'mocha'
end

group :development do
  gem 'shotgun'
  gem 'pry'
  gem 'leader', :git => 'git://github.com/halo/leader.git'
  gem 'foreman'
  gem "better_errors"
  gem "binding_of_caller"
end
