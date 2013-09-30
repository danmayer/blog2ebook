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
    short_title    = title.length > 50 ? "#{title[0...50]}" : title
    "#{root}/tmp/#{short_title.gsub(/( |\.|')/,'_')}"
  end

  def book_file_name(root)
    "#{book_folder_name(root)}/#{formatted_title}.html"
  end

  def formatted_book
    book_start       = "<a name='start' /><h3>#{fixed_encoding_title}</h3>"
    "<html><head><title>#{fixed_encoding_title}</title></head><body>#{book_start}#{fixed_encoding_content}</body></html>"
  end

  private

  def fixed_encoding_title
    BookFormatter.fixed_encoding(title)
  end

  def fixed_encoding_content
    BookFormatter.fixed_encoding(content)
  end

  def self.fixed_encoding(text)
    text.gsub(/(’|’)/,"'")
      .gsub(/(“|”)/,'"')
      .gsub(/ /,' ')
      .gsub(/♥/,'<3')
      .encode('ISO-8859-1', {:invalid => :replace, :undef => :replace, :replace => '?'})
  end

end
