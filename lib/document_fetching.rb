require 'pismo'
require 'readability'

class DocumentFetching

  def initialize(url)
    @url = url
  end

  def document_from_url
  end

  # Pismo
  # doc = Pismo::Document.new(params['url'])
  # {:content => doc.html_body}.to_json

  #ruby-readability
  #source = open('http://mayerdan.com/2013/05/08/performance_bugs_cluster/')
  # {:content => Readability::Document.new(source).content}

end
