source 'https://rubygems.org'
gem 'rake'
gem 'sinatra'
gem 'json'
gem 'pismo'
gem "ruby-readability", :require => 'readability'
gem 'rest-client'
gem 'nokogiri'
gem 'rack-flash3'
gem 'email_veracity'
gem 'redis'
#gem 'rack-ssl-enforcer'

# Prevent installation on Heroku with
# heroku config:add BUNDLE_WITHOUT="development:test"
group :development, :test do
#  gem 'ruby-debug19', :require => 'ruby-debug'
   gem 'rack-test'
   gem 'mocha'
   gem 'pry'
end

if RbConfig::CONFIG['host_os'] =~ /darwin/
  group :development do
    #gem 'thin'
    #gem 'pry'
  end
end