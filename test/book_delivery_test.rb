# encoding: utf-8
ENV['RACK_ENV'] = 'test'
require 'sinatra'
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))
require 'test/unit'
require 'mocha/setup'

class BookDeliveryTest < Test::Unit::TestCase

  def test_email_to_kindle
    File.expects(:open)
    RestClient.expects(:post)
    formatted_book = BookDelivery.email_to_kindle("title", "content", "fake@email")
  end

end
