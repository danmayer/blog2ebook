# encoding: UTF-8
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
require 'rack-flash'
require 'email_veracity'
require 'redis'
require 'addressable/uri'
require './lib/book_formatter'
require './lib/document_fetching'
require './lib/book_delivery'
require './lib/redis_initializer'

MAIL_API_KEY = ENV['MAILGUN_API_KEY']
MAIL_API_URL = "https://api:#{MAIL_API_KEY}@api.mailgun.net/v2/app7941314.mailgun.org"

set :public_folder, File.dirname(__FILE__) + '/public'
set :root, File.dirname(__FILE__)
enable :logging

use Rack::Session::Cookie, :key => 'kindleizer.rack.session',
                           :path => '/',
                           :expire_after => 2592000, # In seconds
                           :secret => "update_secret_#{ENV['MAILGUN_API_KEY']}"

use Rack::Flash, :sweep => true

helpers do

  def possilbe_url_value
    if url = params['url']
      "value = '#{url}'"
    else
      ''
    end
  end

  def possilbe_content_value
    if content = params['content']
      content
    else
      ''
    end
  end

  def load_image_option_value
    ((ENV['RACK_ENV']=='production' && params['load_images']=='true') || ENV['RACK_ENV']!='production')
  end

end

def self.get_or_post(url,&block)
  get(url,&block)
  post(url,&block)
end

get_or_post '/' do
  @usage = UsageCount.usage_remaining
  erb :index
end

get_or_post '/kindleizecontent' do
  verify_content_and_email
  verify_usage
  content  = params['content']
  title    = content.split("\n").first
  to_email = user_email

  BookDelivery.email_to_kindle(title, content, to_email)
  success_response('Your content is being emailed to your kindle shortly.')
end

get_or_post '/kindleize' do
  verify_url_and_email
  verify_usage
  doc      = DocumentFetching.new(params['url']).document_from_url
  content  = doc['content']
  title    = doc['title'] 
  to_email = user_email

  BookDelivery.email_to_kindle(title, content, to_email)
  success_response('Your article will be emailed to your kindle shortly.')
end

get_or_post '/kindleizeblog' do
  begin
    verify_url_and_email
    verify_usage
    options = {'load_images' => load_image_option_value}
    doc      = DocumentFetching.new(params['url']).document_from_feed(options)
    content  = doc[:content]
    title    = doc[:title] 
    to_email = user_email

    puts "current env #{ENV['RACK_ENV']} content match #{content.match(/img.*src/)} image option #{load_image_option_value}"
    if ENV['RACK_ENV']=='production' && content.match(/img.*src/) && !load_image_option_value
      puts "delivering #{title} via deferred server"
      BookDelivery.deliver_via_deferred_server(request)
      success_response('Your book is being generated and emailed to your kindle shortly.')
    else
      puts "emailing #{title} to #{to_email} content #{content.length}"
      BookDelivery.email_to_kindle(title, content, to_email)
      success_response('Your book is being emailed to your kindle shortly.')
    end
  rescue => error
    puts "error during book building #{error.class}"
    puts error.backtrace.join("\n")
    error_response("There was a error building your book sorry about that please let me know what problems you had: #{error.message}")
  end
end

private

def user_email
  params['email'] || request.cookies["kindle_mail"]
end

def verify_usage
  unless UsageCount.usage_remaining > 0
    error_response("Sorry we ran out of free usage today try again tomorrow.")
  end
end

def error_response(notice)
  #todo why isn't content type set in test mode?
  if request.content_type.nil?
    flash[:error] = notice
    halt redirect '/'
  end
  request.accept.each do |type|
    case type
    when 'text/json'
      halt ({:error => notice}.to_json)
    else
      flash[:error] = notice
      halt redirect '/'
    end
  end
end

def success_response(notice)
  #todo why isn't content type set in test mode?
  if request.content_type.nil?
    flash[:notice] = notice
    halt redirect '/'
  end
  request.accept.each do |type|
    case type
    when 'text/json'
      halt ({:success => 'true'}.to_json)
    else
      flash[:notice] = notice
      halt redirect '/'
    end
  end
end

def verify_url_and_email
  unless params['url'].to_s.length > 1 && user_email.to_s.length > 1
    request.accept.each do |type|
      case type
      when 'text/json'
        halt ({:error => 'requires url to check for content'}).to_json
      else
        flash[:error] = "missing email or url"
        halt redirect '/'
      end
    end
  end
  verify_email
end

def verify_content_and_email
  unless params['content'].to_s.length > 1 && user_email.to_s.length > 1
    request.accept.each do |type|
      case type
      when 'text/json'
        halt ({:error => 'requires email and content to be passed'}).to_json
      else
        flash[:error] = "missing email or content"
        halt redirect '/'
      end
    end
  end
  verify_email
end

def verify_email
  address = EmailVeracity::Address.new(user_email)
  request.accept.each do |type|
    case type
    when 'text/json'
      unless address.valid?
        halt ({:error => 'email must be valid'}).to_json
      end
      unless address.domain.to_s.match(/kindle\.com/)
        halt ({:error => 'must be a kindle address'}).to_json
      end
    else
      unless address.valid?
        flash[:error] = "email must be valid"
        halt redirect '/'
      end
      unless address.domain.to_s.match(/kindle\.com/)
        flash[:error] = 'must be a kindle address'
        halt redirect '/'
      end
    end
  end
end
