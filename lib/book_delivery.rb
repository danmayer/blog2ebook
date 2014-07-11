# encoding: utf-8
class BookDelivery

  def self.root_path
    defined?(settings) ? settings.root : File.expand_path(File.join(File.dirname(__FILE__), '../'))
  end

  def self.email_book_to_kindle(book, to_email)
    UsageCount.increase

    RestClient.post MAIL_API_URL+"/messages",
    :from => "kindleizer@mayerdan.com",
    :to => to_email,
    :subject => "kindle book",
    :text => 'kindle book attached',
    :attachment => File.new(book.delivery_file)
  end

end
