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
  end

  def test_email_to_kindle
    File.expects(:open)
    File.stubs(:new).returns("")
    RestClient.expects(:post)
    book = BookFormatter.new("title", "content")
    formatted_book = BookDelivery.email_book_to_kindle(book, "fake@email")
  end

end
