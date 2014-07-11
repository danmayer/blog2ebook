# encoding: utf-8
# Currently disabled gems use for testing improved single article porting
#require 'pismo'
#require 'readability'

class DocumentFetching
  READ_API_TOKEN = ENV['READ_API_TOKEN']

  def initialize(url)
    @url = url
  end

  def rss_content?
    file_content_from_url.match(/<rss/)
  end

  # Pismo
  # doc = Pismo::Document.new(params['url'])
  # {:content => doc.html_body, :title => doc.title}.to_json

  #ruby-readability
  #source = open('http://mayerdan.com/2013/05/08/performance_bugs_cluster/')
  #doc = Readability::Document.new(source)
  # {:content => doc.content}

  ###
  # Above examples are using other parsers
  # currently just using readbilty api
  # this isn't really the best support, clearly more focused on RSS feeds
  ###
  def document_from_url
    results = RestClient::Request.execute(:method => :get, :url => "http://www.readability.com/api/content/v1/parser?url=#{@url}&token=#{READ_API_TOKEN}", :timeout => 10, :open_timeout => 10)
    json_results = JSON.parse(results)
    json_results
  end

  def document_from_git
    `rm -rf ./tmp/git_book/`
    puts "getting #{@url}"
    git_cmd = "git clone #{@url} ./tmp/git_book"
    puts git_cmd
    puts `#{git_cmd}`
    "./tmp/git_book"
  end

  def file_from_url
    begin
      file_name = @url.split('/').last
      file_contents = file_content_from_url
      {'content' => file_contents, 'title' => file_name}
    rescue RestClient::GatewayTimeout
      error_response("Hmmm looks like I can't reach that file.")
    end
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
  #
  # TODO move more to book_formatter
  ###
  def document_from_feed(options = {})
    results = file_content_from_url
    xml_doc  = Nokogiri::XML::Document.parse(results)
    
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

   
    table_of_content = "<a name='TOC' /><h3>Table of Contents</h3><ul>"
    chapters.each_pair do |post_title, chapter|
      table_of_content += "<li><a href='##{chapter}'>#{post_title}</a></li>"
    end
    table_of_content += "</ul><hr/><mbp:pagebreak />"
    content = "#{table_of_content}#{content}"

    if(options['load_images'])
      content = filter_for_images(content)
      download_document_images(xml_doc)
    end

    {:title => title, :content => content}
  rescue RestClient::GatewayTimeout, RestClient::ResourceNotFound
    error_response("Hmmm looks like I can't reach that file.")
  end

  private

  def file_content_from_url
    @file_contents ||= RestClient::Request.execute(:method => :get, :url => URI.escape(@url), :timeout => 10, :open_timeout => 10)
  end

  def url_base
    @url_base ||= "#{URI.parse(@url).scheme}://#{URI.parse(@url).host}/"
  end

  def download_document_images(xml_doc)
    images = []

    xml_doc.document.css('entry').css('content').children.each do |child|
      Nokogiri::HTML(child.text).css('img').each do |node|
        img_url = node.attributes['src'].value
        unless img_url.match(/:\/\//)
          img_url = "#{url_base}#{img_url}"         
        end
        images << img_url
      end
    end

    puts "downloading #{images.length} images"
    title = title_from_feed(xml_doc).gsub(/( |\.)/,'_')

    unless File.exists?("./tmp/#{title}")
      puts "making directory"
      `mkdir ./tmp/#{title}` 
    end

    images.each do |image_url|
      filename = "./tmp/#{title}/#{image_url.split('/').last}"
      open(filename, 'wb') do |file|
        begin
          file << open(image_url).read
        rescue Errno::ECONNRESET, Errno::ENOENT, SocketError, OpenURI::HTTPError
          puts "skipping #{image_url}"
        end
      end
    end
  end

  def filter_for_images(content)
    images = content.scan(/src="(.*?)"/)
    images += content.scan(/src='(.*?)'/)
    images = images.flatten
    puts "replacing #{images.length} images"
    images.each do |image_src|
      local_src = "./#{image_src.split('/').last}"
      puts "replacing #{image_src} with #{local_src}"
      content = content.gsub(image_src, local_src)
    end
    content
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
    elsif entry.search('description').length > 0
      entry.search('description').map(&:content).join("\n")
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

  def feed_item_element(xml_doc)
    if xml_doc.search("entry").length > 1
      'entry'
    else
      'item'
    end
  end

end
