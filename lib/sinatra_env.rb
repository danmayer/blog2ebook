require 'json'
require 'fileutils'
require 'rest-client'
require 'open-uri'
require 'openssl'
module OpenSSL
  module SSL
    remove_const :VERIFY_PEER
  end
end
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

require 'nokogiri'
require 'sinatra/flash'
require 'email_veracity'
require 'redis'
require 'addressable/uri'
require 'airbrake'

require 'rack_catcher'
require 'book_formatter'
require 'git_book_formatter'
require 'document_fetching'
require 'book_delivery'
require 'redis_initializer'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

MAIL_API_KEY = ENV['MAILGUN_API_KEY']
MAIL_API_URL = "https://api:#{MAIL_API_KEY}@api.mailgun.net/v2/app7941314.mailgun.org"
