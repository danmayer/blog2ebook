# encoding: utf-8
ENV['RACK_ENV'] = 'test'
require 'sinatra'
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))
require 'test/unit'
require 'mocha/setup'

class BookDeliveryTest < Test::Unit::TestCase

  def setup
    REDIS.stubs(:incr).returns(1)
    REDIS.stubs(:get).returns(2)
    settings = stub(:root => '')
  end

  def test_email_to_kindle
    File.expects(:open)
    File.stubs(:new).returns("")
    RestClient.expects(:post)
    formatted_book = BookDelivery.email_to_kindle("title", "content", "fake@email")
  end

end
