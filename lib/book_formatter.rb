class BookFormatter

  attr_accessor :title, :content

  def initialize(title, content)
    @title = title
    @content = content
  end

  def underscored_title
    @title.gsub(' ','_')
  end

  def book_file_name(root)
    "#{root}/tmp/#{underscored_title}.html"
  end

  def formatted_book
    "<html><head><title>#{title}</title></head><body>#{content}</body></html>"
  end

end
