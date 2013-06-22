class BookDelivery

  def self.email_to_kindle(title, content, to_email)
    # TODO (update template project as well) heroku needs tmp have sinatra template always include the directory but ignore all files
    `mkdir -p #{settings.root}/tmp`

    book = BookFormatter.new(title, content)
    book_file = book.book_file_name(settings.root)

    File.open(book_file, 'w', encoding: 'ISO-8859-1') {|f| f.write(book.formatted_book) }
    UsageCount.increase

    RestClient.post MAIL_API_URL+"/messages",
    :from => "kindleizer@mayerdan.com",
    :to => to_email,
    :subject => "kindle book",
    :text => 'kindle book attached',
    :attachment => File.new(book_file)
  end

end
