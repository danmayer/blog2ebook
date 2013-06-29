# encoding: utf-8
ENV['RACK_ENV'] = 'test'
require 'sinatra'
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))
require 'test/unit'
require 'mocha/setup'

class DocumentFetchingTest < Test::Unit::TestCase
  
  def test_document_from_url
    fetcher = DocumentFetching.new('url')
    fake_results = {'title' => 'title', 'content' => 'content'}

    RestClient::Request.expects(:execute).returns(fake_results.to_json)

    results = fetcher.document_from_url
    assert_equal fake_results, results
  end

end
