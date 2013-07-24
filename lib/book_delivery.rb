# encoding: utf-8
class BookDelivery
  DEFERRED_SERVER_ENDPOINT = "http://git-hook-responder.herokuapp.com/deferred_project_command"
  BLOG_TO_BOOK_TOKEN = ENV['BLOG_2_BOOK_TOKEN']

  def self.email_filecontent_to_kindle(title, file_content, to_email)
    # TODO (update template project as well) heroku needs tmp have sinatra template always include the directory but ignore all files
    `mkdir -p #{settings.root}/tmp`

    book = BookFormatter.new(title, file_content)
    book_file = book.book_file_name(settings.root).gsub(/\.html/,'.pdf')
    `mkdir -p #{settings.root}/tmp/#{title.gsub(/( |\.)/,'_')}`

    File.open(book_file, 'w') {|f| f.write(file_content) }

    email_file_to_kindle(title, book_file, to_email)      
  end

  def self.email_file_to_kindle(title, book_file, to_email)    
    UsageCount.increase

    RestClient.post MAIL_API_URL+"/messages",
    :from => "kindleizer@mayerdan.com",
    :to => to_email,
    :subject => "kindle book",
    :text => 'kindle book attached',
    :attachment => File.new(book_file)
  end

  def self.email_to_kindle(title, content, to_email)
    # TODO (update template project as well) heroku needs tmp have sinatra template always include the directory but ignore all files
    `mkdir -p #{settings.root}/tmp`

    book = BookFormatter.new(title, content)
    book_file = book.book_file_name(settings.root)
    `mkdir -p #{settings.root}/tmp/#{title.gsub(/( |\.)/,'_')}`

    File.open(book_file, 'w', encoding: 'ISO-8859-1') {|f| f.write(book.formatted_book) }
    delivery_file = book_file

    if ENV['RACK_ENV']=='production' && content.match(/img.*src/)
      kindle_gen_cmd = "kindlegen -verbose \"#{book_file}\" -o \"#{book.formatted_title}.mobi\""
      puts "cmd: #{kindle_gen_cmd}"
      conversion_results = `#{kindle_gen_cmd}`
      puts conversion_results
      delivery_file = book_file.gsub('.html','.mobi')
    end
    
    UsageCount.increase

    RestClient.post MAIL_API_URL+"/messages",
    :from => "kindleizer@mayerdan.com",
    :to => to_email,
    :subject => "kindle book",
    :text => 'kindle book attached',
    :attachment => File.new(delivery_file)
  end

  def self.deliver_via_deferred_server(request)
    begin
      uri = Addressable::URI.new
      uri.query_values = request.params.merge('load_images' => true)
      request_endpoint = "#{request.path}?#{uri.query}"
      
      resource = RestClient::Resource.new(DEFERRED_SERVER_ENDPOINT, 
                                          :timeout => 18, 
                                          :open_timeout => 10)
      
      resource.post(:signature => BLOG_TO_BOOK_TOKEN,
                    :project => 'danmayer/blog2ebook',
                    :project_request => request_endpoint)
    rescue RestClient::RequestTimeout
      puts "Sorry, accessing book generator failed, please try again... As it might be waking up from sleeping... request likely OK fire and forget and all"
    end
  end

end
