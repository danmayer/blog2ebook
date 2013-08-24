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

#enable https
#gem 'rack-ssl-enforcer'

# disabled for now but used to test other single article rendering methods
# gem 'pismo'
# gem "ruby-readability", :require => 'readability'

group :production do
  gem 'unicorn'
  gem 'newrelic_rpm'
end

group :development, :test do
  gem 'shotgun'
  gem 'rack-test'
  gem 'mocha'
  gem 'pry'
  gem 'leader', :git => 'git://github.com/halo/leader.git'
  gem 'foreman'
end
