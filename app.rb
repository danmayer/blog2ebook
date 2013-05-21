require 'json'
require 'fileutils'
require 'pismo'
require 'readability'
require 'rest-client'
require 'open-uri'
require 'nokogiri'

MAIL_API_KEY = ENV['MAILGUN_API_KEY']
MAIL_API_URL = "https://api:#{MAIL_API_KEY}@api.mailgun.net/v2/app7941314.mailgun.org"

#use Rack::SslEnforcer unless ENV['RACK_ENV']=='test'
set :public_folder, File.dirname(__FILE__) + '/public'
set :root, File.dirname(__FILE__)
enable :logging

helpers do
  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Testing HTTP Auth")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', 'responder']
  end

end

#before { protected! if request.path_info == "/" && request.request_method == "GET" && ENV['RACK_ENV']!='test' }

def self.get_or_post(url,&block)
  get(url,&block)
  post(url,&block)
end

get '/' do
  if params['error']
    @error = params['error']
  end
  erb :index
end

get '/get_content' do
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

get '/kindleize' do
  unless params['url'].to_s.length > 1 && params['email'].to_s.length > 1
    return {:error => 'requires url to check for content'}.to_json
  end
  doc      = document_from_url(params['url'])
  content  = doc['content']
  title    = doc['title'] 
  to_email = params['email']

  email_to_kindle(title, content, to_email)
end

get_or_post '/kindleizeblog' do
  unless params['url'].to_s.length > 1 && params['email'].to_s.length > 1
    request.accept.each do |type|
      case type
      when 'text/json'
        halt ({:error => 'requires url to check for content'}).to_json
      else
        halt redirect '/?error=missing email or url'
      end
    end
  end

  doc      = document_from_feed(params['url'])
  content  = doc[:content]
  title    = doc[:title] 
  to_email = params['email']

  puts "emailing #{title} to #{to_email}"
  response = email_to_kindle(title, content, to_email)

  request.accept.each do |type|
    case type
    when 'text/html'
      halt redirect '/?success=true'
    when 'text/json'
      halt response
    else
      halt redirect '/?success=true'
    end
  end

end

private

def email_to_kindle(title, content, to_email)
  attached = "#{__FILE__}/tmp/#{title.gsub(' ','_')}.html"
  File.open(attached, 'w') {|f| f.write(kindle_format_wrapper(title, content)) }

  RestClient.post MAIL_API_URL+"/messages",
  :from => "kindleizer@mayerdan.com",
  :to => to_email,
  :subject => "kindle book",
  :text => 'kindle book attached',
  :attachment =>  File.new(attached)
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
