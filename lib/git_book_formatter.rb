# encoding: utf-8
require 'kindlegen'

class GitBookFormatter < BookFormatter

  attr_accessor :git_folder, :title, :type

  def initialize(git_folder, url)
    self.git_folder = git_folder
    self.title = url.gsub(/.*\//,'').gsub('.git','')
    self.type  = 'html'
  end

  def formatted_title
    title.gsub('.',' ')
  end

  def formatted_book
    content
  end

  def book_file_name
    converted_book_file_name
  end

  def converted_book_file_name
    "#{formatted_title}.mobi"
  end

  def delivery_file
    kindle_gen_cmd = "kindlegen -verbose \"#{html_file_name}\" -o \"#{converted_book_file_name}\""
    self.content = converted_content
    puts "running with gem: #{kindle_gen_cmd}"
    Kindlegen.run("-verbose", html_file_name, "-o", converted_book_file_name)
    sleep(2)
    converted_book_file_name
  end

  private
  
  def html_file_name
    "#{git_folder}/index.html"
  end

  def converted_content
    html = File.read(html_file_name)
    html.gsub("images","tmp_images")
  end

  def fixed_encoding_content
    content.gsub(/(’|’)/,"'")
      .gsub(/(“|”)/,'"')
      .gsub(/ /,' ')
      .encode('ISO-8859-1', {:invalid => :replace, :undef => :replace, :replace => '?'})
  end

end
