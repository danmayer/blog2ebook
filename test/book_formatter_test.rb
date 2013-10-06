# encoding: utf-8
ENV['RACK_ENV'] = 'test'
require 'sinatra'
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))
require 'test/unit'
require 'mocha/setup'

class BookFormatterTest < Test::Unit::TestCase

  def test_formatted_title
    formatted_book = BookFormatter.new("replace.periods", "content")
    assert_equal "replace_periods", formatted_book.formatted_title
  end

  def test_book_file_name
    formatted_book = BookFormatter.new("replace.periods", "content")
    assert_match "tmp/replace_periods/replace_periods.html", formatted_book.book_file_name
  end

  def test_formatted_book
    formatted_book = BookFormatter.new("title", "content")
    assert_equal "<html><head><title>title</title></head><body><a name='start' /><h3>title</h3>content</body></html>", formatted_book.formatted_book
  end

  def test_formatted_book__with_replaced_content
    bad_formatted_content = <<EOS
content ’ “  
EOS

    formatted_book = BookFormatter.new("title", bad_formatted_content)
    assert_equal "<html><head><title>title</title></head><body><a name='start' /><h3>title</h3>content ' \"  \n</body></html>", formatted_book.formatted_book
  end

end
