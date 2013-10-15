# encoding: UTF-8
require 'rubygems'
require 'bundler/setup'
$LOAD_PATH << File.dirname(__FILE__) + '/lib'

require 'sinatra_env'

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

#this allows preview of git books to work
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

  if pubish_request?
    book = BookFormatter.new(title, content)
    BookDelivery.email_book_to_kindle(book, to_email)
    success_response('Your content is being emailed to your kindle shortly.')
  else
    @content = content
    render_preview(title,content)
  end
end

get_or_post '/kindleize' do
  begin
    if params['url'].nil?
      error_response("You must provide the url param")
    else
      verify_url_and_email
      verify_usage
      document_fetcher = DocumentFetching.new(params['url'])
      
      if params['url'].match(/\.git/)
        process_git_book(document_fetcher)
      elsif params['url'].match(/\.rss/) || params['url'].match(/\.atom/) || params['url'].match(/\.xml/) || document_fetcher.rss_content?
        process_feed_url(document_fetcher)
      elsif params['url'].match(/\.pdf/) || params['url'].match(/\.epub/)
        process_document_url(document_fetcher)
      else
        process_webpage(document_fetcher)
      end
    end
  rescue RestClient::GatewayTimeout
    error_response("Hmmm looks like I can't reach that article.")
  rescue => error
    puts "error during book building #{error.class} : #{error.message}"
    puts error.backtrace.join("\n")
    error_response("There was a error building your book! Sorry try again or let me know what problems you had: #{error.message}")
  end
end

private

def deferred_request?
  !!(ENV['RACK_ENV']=='production' && params['load_images'])
end

def non_deferred_request?
  !deferred_request?
end

def process_git_book(document_fetcher)
  if pubish_request? && non_deferred_request?
    BookDelivery.deliver_via_deferred_server(request)
    success_response('Your book is being generated and emailed to your kindle shortly.')
  else
    location = document_fetcher.document_from_git
    book     = GitBookFormatter.new(location, params['url'])
    to_email = user_email
    
    if pubish_request?
      BookDelivery.email_book_to_kindle(book, to_email)
      success_response('Your book is being emailed to your kindle shortly.')
    else
      render_book_preview(book)
    end
  end
end

def process_feed_url(document_fetcher)
  options = {'load_images' => load_image_option_value}
  doc      = document_fetcher.document_from_feed(options)
  content  = doc[:content]
  title    = doc[:title] 
  to_email = user_email
  
  if pubish_request?
    if non_deferred_request? && content.match(/img.*src/)
      BookDelivery.deliver_via_deferred_server(request)
      success_response('Your book is being generated and emailed to your kindle shortly.')
    else
      book = BookFormatter.new(title, content)
      BookDelivery.email_book_to_kindle(book, to_email)
      success_response('Your book #{title} is being emailed to #{to_email} your kindle shortly.')
    end
  else
    render_preview(title,content)
  end
end

def process_document_url(document_fetcher)
  type     = params['url'].match(/\.pdf/) ? 'pdf' : 'epub'
  doc      = document_fetcher.file_from_url
  content  = doc['content']
  title    = doc['title'] 
  to_email = user_email
  
  if non_deferred_request? && type.match(/epub/)
    BookDelivery.deliver_via_deferred_server(request)
    message = "Your #{type} book is being generated and emailed to your kindle shortly."
  else
    book = BookFormatter.new(title, content, type)
    BookDelivery.email_book_to_kindle(book, to_email)
    message = "Your #{type} document will be emailed to your kindle shortly."
  end
  if pubish_request?
    success_response(message)
  else
    success_response("#{type}'s can't be previewed it will be emailed to your kindle shortly.")
  end
end

def process_webpage(document_fetcher)
  doc      = document_fetcher.document_from_url
  content  = doc['content']
  title    = doc['title'] 
  to_email = user_email
  
  if pubish_request?
    if non_deferred_request? && content.match(/img.*src/)
      BookDelivery.deliver_via_deferred_server(request)
      success_response('Your book is being generated and emailed to your kindle shortly.')
    else
      book = BookFormatter.new(title, content)
      BookDelivery.email_book_to_kindle(book, to_email)
      success_response('Your article will be emailed to your kindle shortly.')
    end
  else
    render_preview(title,content)
  end
end

def pubish_request?
  !!params['submit']
end

def preview_request?
  !pubish_request
end

def render_book_preview(book)
  @preview = book.formatted_book.force_encoding("UTF-8")
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
  puts "error response #{notice}" unless ENV['RACK_ENV']=='test'
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
  puts "sucess response #{notice}" unless ENV['RACK_ENV']=='test'
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
