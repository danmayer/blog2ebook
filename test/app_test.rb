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

  def test_root
    get '/'
    assert_match 'Convert', last_response.body
  end

  def test_kindleize
    get '/kindleize?url=http://batman.com&content=heythere'
    assert_match redirect_to '/?success=true'
  end

  private

  def script_payload
    {:fake => 'payload'}
  end

end
