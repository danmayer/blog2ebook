require 'json'
require 'fileutils'
require 'pismo'
require 'readability'
require 'rest-client'
require 'open-uri'
require 'nokogiri'
require 'rack-flash'
require 'email_veracity'

MAIL_API_KEY = ENV['MAILGUN_API_KEY']
MAIL_API_URL = "https://api:#{MAIL_API_KEY}@api.mailgun.net/v2/app7941314.mailgun.org"

set :public_folder, File.dirname(__FILE__) + '/public'
set :root, File.dirname(__FILE__)
enable :logging
enable :sessions
use Rack::Flash, :sweep => true

helpers do

end

def self.get_or_post(url,&block)
  get(url,&block)
  post(url,&block)
end

get '/' do
  erb :index
end

get_or_post '/get_content' do
  unless params['url'].to_s.length > 1
    return {:error => 'requires url to check for content'}.to_json
  end
  # Pismo
  # doc = Pismo::Document.new(params['url'])
  # {:content => doc.html_body}.to_json

  #ruby-readability
  #source = open('http://mayerdan.com/2013/05/08/performance_bugs_cluster/')
  # {:content => Readability::Document.new(source).content}

  {:content => document_from_url(params['url'])['content']}.to_json
end

get_or_post '/kindleizecontent' do
  verify_content_and_email
  content  = params['content']
  title    = content.split("\n").first
  to_email = params['email']

  email_to_kindle(title, content, to_email)
  success_response('Your content is being emailed to your kindle shortly.')
end

get_or_post '/kindleize' do
  verify_url_and_email
  doc      = document_from_url(params['url'])
  content  = doc['content']
  title    = doc['title'] 
  to_email = params['email']

  email_to_kindle(title, content, to_email)
  success_response('Your article will be emailed to your kindle shortly.')
end

get_or_post '/kindleizeblog' do
  verify_url_and_email
  doc      = document_from_feed(params['url'])
  content  = doc[:content]
  title    = doc[:title] 
  to_email = params['email']

  puts "emailing #{title} to #{to_email} content #{content.length}"
  response = email_to_kindle(title, content, to_email)
  success_response('Your book is being emailed to your kindle shortly.')
end

private

def success_response(notice)
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
  unless params['url'].to_s.length > 1 && params['email'].to_s.length > 1
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
  unless params['content'].to_s.length > 1 && params['email'].to_s.length > 1
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
  address = EmailVeracity::Address.new(params['email'])
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

def email_to_kindle(title, content, to_email)
  # heroku needs tmp have sinatra template always include the directory but ignore all files
  `mkdir -p #{settings.root}/tmp`
  attached = "#{settings.root}/tmp/#{title.gsub(' ','_')}.html"
  File.open(attached, 'w') {|f| f.write(kindle_format_wrapper(title, content)) }

  RestClient.post MAIL_API_URL+"/messages",
  :from => "kindleizer@mayerdan.com",
  :to => to_email,
  :subject => "kindle book",
  :text => 'kindle book attached',
  :attachment => File.new(attached)
end

def kindle_format_wrapper(title, content)
  template = "<html><head><title>#{title}</title></head><body>#{content}</body></html>"
end

def document_from_url(url)
  results = RestClient.get("http://www.readability.com/api/content/v1/parser?url=#{params['url']}&token=6ca222fd6f857c2a27a560edbfc3c9400f3b9bec")
  json_results = JSON.parse(results)
  json_results
end

def title_from_feed(xml_doc)
  title = xml_doc.search('title').first.content
end

def link_from_entry(entry)
  entry.search('link').first['href'] || entry.search('link').first.content
end

def date_from_entry(entry)
  if entry.search('updated').length > 0
    post_date = entry.search('updated').first.content
    post_date = Date.parse(post_date).strftime("%m/%d/%Y at %I:%M%p")
  else
    post_date = entry.search('pubDate').first.content
    post_date = Date.parse(post_date).strftime("%m/%d/%Y at %I:%M%p")
  end
end

def content_from_entry(entry)
  if entry.search('content').length > 0
    entry.search('content').first.content
  else
    entry.at_xpath("content:encoded").text
  end
end

def contents_from_entry(entry)
  post_title   = entry.search('title').first.content
  post_content = content_from_entry(entry)
  post_date    = date_from_entry(entry)
  post_link    = link_from_entry(entry)
  {
    :title => post_title,
    :content => post_content,
    :date => post_date,
    :link => post_link
  }
end

####
# Method converts data from a feed format to a html kindle book format
# 
# Kindle formatting notes:
# <a name="start" /> — This is the start of the book.
# It’s where the book will open the first time someone reads it.
# You can use it to skip over title and dedication pages and get your readers right in the meat of the book.
# <a name="TOC" /> — Place this at the top of your table of contents.
# <a name="chap1" /> 
###
def document_from_feed(url)
  results = RestClient.get(url)
  xml_doc  = Nokogiri::XML::Document.parse(results)
  #puts xml_doc.inspect
  
  title = title_from_feed(xml_doc)
  content = ''
  chapters = {}

  xml_doc.search(feed_item_element(xml_doc)).each do |entry|
    post = contents_from_entry(entry)
    post_chapter = "chap#{(chapters.length + 1)}"
    chapters[post[:title]] = post_chapter
    seperator = "<br/><hr/><a name='#{post_chapter}' /><h3><a href='#{post[:link]}'>#{post[:title]}</a></h3>"
    seperator += "<div>updated: #{post[:date]}</div><br/>"
    content   += "#{seperator}#{post[:content]}<mbp:pagebreak />"
  end

  book_start       = "<a name='start' /><h3>#{title}</h3>"
  table_of_content = "<a name='TOC' /><h3>Table of Contents</h3><ul>"
  chapters.each_pair do |post_title, chapter|
    table_of_content += "<li><a href='##{chapter}'>#{post_title}</a></li>"
  end
  table_of_content += "</ul><hr/><mbp:pagebreak />"
  content = "#{book_start}#{table_of_content}#{content}"

  {:title => title, :content => content}
end

def feed_item_element(xml_doc)
  if xml_doc.search("entry").length > 1
    'entry'
  else
    'item'
  end
end
