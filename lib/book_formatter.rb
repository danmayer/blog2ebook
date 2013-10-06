# encoding: utf-8
class BookFormatter

  attr_accessor :title, :content, :type

  def initialize(title, content, type = 'html')
    self.title   = title
    self.content = content
    self.type    = type
  end

  def formatted_title
    title.gsub('.',' ').gsub(/( |\.|')/,'_').gsub(/'/,'')[0...50]
  end

  def book_folder_name
    "#{root_path}/tmp/#{formatted_title}"
  end

  def book_file_name
    "#{book_file_name_without_ext}.#{type}"
  end

  def book_file_name_without_ext
    "#{book_folder_name}/#{formatted_title}"
  end

  def converted_book_file_name
    "#{book_file_name_without_ext}.mobi"
  end

  def target_file_name
    "#{formatted_title}.mobi"
  end

  def formatted_book
    #TODO we do this type check twice move to inheritance based overrides for binary book type
    if type.match(/pdf|mobi|epub/)
      content
    else
      book_start       = "<a name='start' /><h3>#{fixed_encoding_title}</h3>"
      "<html><head><title>#{fixed_encoding_title}</title></head><body>#{book_start}#{fixed_encoding_content}</body></html>"
    end
  end

  def delivery_file
    make_book_folder
    write_book_file

    delivery_file = book_file_name
    
    if ENV['RACK_ENV']=='production' && (content.match(/img.*src/) || type.match(/epub/) )
      kindle_gen_cmd = "kindlegen -verbose \"#{book_file_name}\" -o \"#{target_file_name}\""
      puts "cmd: #{kindle_gen_cmd}"
      conversion_results = `#{kindle_gen_cmd}`
      puts conversion_results
      delivery_file = converted_book_file_name
    end
    delivery_file
  end

  private

  def make_book_folder
    `mkdir -p #{book_folder_name}`
  end

  def write_book_file
    if type.match(/pdf|mobi|epub/)
      File.open(book_file_name, 'w:binary') {|f| f.write(formatted_book) }
    else
      File.open(book_file_name, 'w', encoding: 'ISO-8859-1') {|f| f.write(formatted_book) }
    end
  end

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

  def root_path
    BookFormatter.root_path
  end

  def self.root_path
    defined?(settings) ? settings.root : File.expand_path(File.join(File.dirname(__FILE__), '../'))
  end

end
