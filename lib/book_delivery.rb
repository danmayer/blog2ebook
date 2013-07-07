class BookDelivery
  DEFERRED_SERVER_ENDPOINT = "http://git-hook-responder.herokuapp.com/deferred_project_command"
  BLOG_TO_BOOK_TOKEN = ENV['BLOG_2_BOOK_TOKEN']

  def self.email_to_kindle(title, content, to_email)
    # TODO (update template project as well) heroku needs tmp have sinatra template always include the directory but ignore all files
    `mkdir -p #{settings.root}/tmp`

    book = BookFormatter.new(title, content)
    book_file = book.book_file_name(settings.root)

    File.open(book_file, 'w', encoding: 'ISO-8859-1') {|f| f.write(book.formatted_book) }

    if ENV['RACK_ENV']=='production' && content.match(/img.*src/)
      kindle_gen_cmd = "kindlegen -verbose \"#{book_file}\" -o \"#{book.formatted_title}.mobi\""
      puts "cmd: #{kindle_gen_cmd}"
      conversion_results = `#{kindle_gen_cmd}`
      puts conversion_results
    end
    
    UsageCount.increase

    RestClient.post MAIL_API_URL+"/messages",
    :from => "kindleizer@mayerdan.com",
    :to => to_email,
    :subject => "kindle book",
    :text => 'kindle book attached',
    :attachment => File.new(book_file.gsub('.html','.mobi'))
  end

  def self.deliver_via_deferred_server(request)
    uri = Addressable::URI.new
    uri.query_values = request.params.merge('load_images' => true)
    request_endpoint = "#{request.path}?#{uri.query}"

    RestClient.post DEFERRED_SERVER_ENDPOINT,
    :signature => BLOG_TO_BOOK_TOKEN,
    :project => 'danmayer/blog2ebook',
    :project_request => request_endpoint
  end

end
