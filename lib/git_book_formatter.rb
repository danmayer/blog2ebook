# encoding: utf-8
class GitBookFormatter < BookFormatter

  attr_accessor :git_folder

  def initialize(git_folder, url)
    self.git_folder = git_folder
    self.title = url.gsub(/.*\//,'').gsub('.git','')
    kindle_gen_cmd = "kindlegen -verbose \"#{book_file_name}\" -o \"#{book_mobi_file_name}\""
    self.content = converted_content
    puts "running: #{kindle_gen_cmd}"
    `#{kindle_gen_cmd}`
  end

  def formatted_title
    title.gsub('.',' ')
  end

  def formatted_book
    content
  end

  def book_file_name
    "#{git_folder}/index.html"
  end

  def book_mobi_file_name
    "#{formatted_title}.mobi"
  end
  
  def book_mobi_file_path
    "#{git_folder}/#{book_mobi_file_name}"
  end

  private

  def converted_content
    html = File.read(self.book_file_name)
    html.gsub("images","tmp_images")
  end

  def fixed_encoding_content
    content.gsub(/(’|’)/,"'")
      .gsub(/(“|”)/,'"')
      .gsub(/ /,' ')
      .encode('ISO-8859-1', {:invalid => :replace, :undef => :replace, :replace => '?'})
  end

end
