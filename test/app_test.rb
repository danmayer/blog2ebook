ENV['RACK_ENV'] = 'test'
require 'sinatra'
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))
require 'test/unit'
require 'rack/test'
require 'mocha/setup'

class MyAppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    REDIS.stubs(:incr).returns(1)
    REDIS.stubs(:get).returns(2)
  end

  def test_root
    get '/'
    assert_match 'Convert', last_response.body
  end

  def test_kindleize
    DocumentFetching.any_instance.stubs(:document_from_url).returns({'content' => 'hey', 'title' => 'rock on'})
    BookDelivery.stubs(:email_book_to_kindle).returns(true)
    get '/kindleize?url=http://google.com&email=fake@kindle.com&submit=true'
    assert_equal true, last_response.redirect?
    follow_redirect!
    assert_equal last_request.url, 'http://example.org/'
  end

  private

  def script_payload
    {:fake => 'payload'}
  end

end
