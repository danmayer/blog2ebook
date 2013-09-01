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
require 'sinatra/flash'
require 'email_veracity'
require 'redis'
require 'addressable/uri'
require 'airbrake'

require './lib/rack_catcher'
require './lib/book_formatter'
require './lib/git_book_formatter'
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

configure :development do
  require "better_errors"
  use BetterErrors::Middleware
  BetterErrors.application_root = File.dirname(__FILE__)
end

configure :production do
  require 'newrelic_rpm'
  Airbrake.configure do |config|
    config.api_key = ENV['B2B_ERRBIT_API_KEY']
    config.host    = ENV['ERRBIT_HOST']
    config.port    = 80
    config.secure  = config.port == 443
  end
  use Rack::Catcher
  use Airbrake::Rack
  set :raise_errors, true
end

helpers do

  def possilbe_url_value
    if url = params['url']
      "value = '#{url}'"
    else
      ''
    end
  end

  def possilbe_content_value
    if @content
      @content
    elsif content = params['content']
      content
    else
      ''
    end
  end

  def load_image_option_value
    ((ENV['RACK_ENV']=='production' && params['load_images']=='true') || ENV['RACK_ENV']!='production') && !params['preview']
  end

end

before /.*/ do
  if request.host.match(/herokuapp.com/)
    redirect request.url.gsub("herokuapp.com",'picoappz.com'), 301
  end
end

get "/tmp_images/:file" do |file|
  send_file File.join("./tmp/git_book/images/", file)
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
  puts params.inspect

  if params['submit']
    BookDelivery.email_to_kindle(title, content, to_email)
    success_response('Your content is being emailed to your kindle shortly.')
  else
    @content = content
    render_preview(title,content)
  end
end

#TODO this all needs some serious refactoring
get_or_post '/kindleize' do
  verify_url_and_email
  verify_usage
  document_fetcher = DocumentFetching.new(params['url'])

  if params['url'].match(/\.git/)
    if params['submit'] && ENV['RACK_ENV']=='production' && !params['load_images']
      puts "delivering via deferred server"
      BookDelivery.deliver_via_deferred_server(request)
      success_response('Your book is being generated and emailed to your kindle shortly.')
    else
      location = document_fetcher.document_from_git
      book     = GitBookFormatter.new(location, params['url'])
      title    = book.formatted_title
      to_email = user_email
    
      if params['submit']
        file  = book.book_mobi_file_path
        BookDelivery.email_file_to_kindle(title, file, to_email)
        success_response('Your book is being emailed to your kindle shortly.')
      else
        render_book_preview(book)
      end
    end
  elsif params['url'].match(/\.rss/) || params['url'].match(/\.atom/) || params['url'].match(/\.xml/) || document_fetcher.rss_content?
    begin
      options = {'load_images' => load_image_option_value}
      doc      = document_fetcher.document_from_feed(options)
      content  = doc[:content]
      title    = doc[:title] 
      to_email = user_email

      puts "current env #{ENV['RACK_ENV']} content match #{content.match(/img.*src/)} image option #{load_image_option_value}"
      if params['submit']
        if ENV['RACK_ENV']=='production' && content.match(/img.*src/) && !load_image_option_value
          puts "delivering #{title} via deferred server"
          BookDelivery.deliver_via_deferred_server(request)
          success_response('Your book is being generated and emailed to your kindle shortly.')
        else
          puts "emailing #{title} to #{to_email} content #{content.length}"
          BookDelivery.email_to_kindle(title, content, to_email)
          success_response('Your book is being emailed to your kindle shortly.')
        end
      else
        render_preview(title,content)
      end
    rescue => error
      puts "error during book building #{error.class}"
      puts error.backtrace.join("\n")
      error_response("There was a error building your book sorry about that please let me know what problems you had: #{error.message}")
    end
  elsif params['url'].match(/\.pdf/)
    doc      = document_fetcher.file_from_url
    content  = doc['content']
    title    = doc['title'] 
    to_email = user_email

    BookDelivery.email_filecontent_to_kindle(title, content, to_email)
    if params['submit']
      success_response('Your PDF document will be emailed to your kindle shortly.')
    else
      success_response("PDFs can't be previewed it will be emailed to your kindle shortly.")
    end
  else
    doc      = document_fetcher.document_from_url
    content  = doc['content']
    title    = doc['title'] 
    to_email = user_email
    
    if params['submit']
      if ENV['RACK_ENV']=='production' && content.match(/img.*src/) && !load_image_option_value
        puts "delivering #{title} via deferred server"
        BookDelivery.deliver_via_deferred_server(request)
        success_response('Your book is being generated and emailed to your kindle shortly.')
      else
        BookDelivery.email_to_kindle(title, content, to_email)
        success_response('Your article will be emailed to your kindle shortly.')
      end
    else
      render_preview(title,content)
    end
  end
end

private

def render_book_preview(book)
  @preview = book.formatted_book
  @usage = UsageCount.usage_remaining
  erb :index
end

def render_preview(title,content)
  book = BookFormatter.new(title, content)
  render_book_preview(book)
end

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
  if params['url'].to_s.length < 1 || (user_email.to_s.length < 1 && params['submit'])
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
  verify_email if params['submit']
end

def verify_content_and_email
  if params['content'].to_s.length < 1 || (user_email.to_s.length < 1 && params['submit'])
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
  verify_email if params['submit']
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
