# encoding: utf-8
class BookDelivery
  DEFERRED_SERVER_ENDPOINT = "http://git-hook-responder.herokuapp.com/deferred_project_command"
  BLOG_TO_BOOK_TOKEN = ENV['BLOG_2_BOOK_TOKEN']
  
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
