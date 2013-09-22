# encoding: utf-8
class BookFormatter

  attr_accessor :title, :content

  def initialize(title, content)
    self.title = title
    self.content = content
  end

  def formatted_title
    title.gsub('.',' ').gsub(/'/,'')
  end

  def book_folder_name(root)
    "#{root}/tmp/#{title.gsub(/( |\.|')/,'_')}"
  end

  def book_file_name(root)
    "#{book_folder_name(root)}/#{formatted_title}.html"
  end

  def formatted_book
    book_start       = "<a name='start' /><h3>#{fixed_encoding_title}</h3>"
    "<html><head><title>#{title}</title></head><body>#{book_start}#{fixed_encoding_content}</body></html>"
  end

  private

  def fixed_encoding_title
    fixed_encoding(content)
  end

  def fixed_encoding_content
    fixed_encoding(content)
  end

  def self.fixed_encoding(text)
    text.gsub(/(’|’)/,"'")
      .gsub(/(“|”)/,'"')
      .gsub(/ /,' ')
      .gsub(/♥/,'<3')
      .encode('ISO-8859-1', {:invalid => :replace, :undef => :replace, :replace => '?'})
  end

end
