Kindleizer
===

This is a simple project that started because I was going on a trip and wanted to turn some full blogs into books on my kindle.

## To Run Locally

    bundle exec rackup -p 3000
    open http://localhost:3000


## Examples

    open http://localhost:3000/kindleizeblog?url=http://mayerdan.com/atom.xml
    open http://localhost:3000/kindleizeblog?url=http://erinashleymiller.com/feed/
    open http://localhost:3000/kindleizeblog?url=http://codeascraft.com/feed/
    open http://localhost:3000/kindleizeblog?url=http://techblog.netflix.com/rss.xml

## Useful related links

* This project seems very similar to the now defunct [readbeam](http://readbeam.com/) project.
* read beam is now open source [readbeam source](https://github.com/tomschlenkhoff/ReadBeam)
* [HTML Elements for Kindle Ebooks](http://webdesign.about.com/od/mobi/a/html-for-kindle.htm)
* [How to Make an Amazon Kindle Book using HTML and CSS](http://www.perrygarvin.com/blog/2012/01/16/how-to-make-an-amazon-kindle-book-using-html-and-css/)
* [formatting images in kindle boos](https://kdp.amazon.com/self-publishing/help?topicId=A1B6GKJ79HC7AN)
* [software for publishing](http://www.williamking.me/2012/02/08/create-your-own-kindle-ebook-step-by-step-with-pictures/)
* [publish to amazon's platform](http://www.copyblogger.com/how-to-publish-kindle-ebook/)
* [RSS feed parsing useful for converting](http://ramblinglabs.com/blog/2012/02/migrating-your-blog-posts-to-markdown-with-upmark-and-nokogiri)
* [How to turn your blog into a book](http://en.blog.wordpress.com/2012/04/04/how-to-turn-your-blog-into-a-book/)

## Other similar projects

* [blurb](http://www.blurb.com/)
* [blog2book](http://blog2print.sharedbook.com/blogworld/printmyblog/index.html)
* [anthologize](http://anthologize.org/)
* [leanpub](https://leanpub.com/)

## TODO

  * tests / travis CI
  * download and embed images from posts
  * support converting github repos to kindle formatted books
  * support multiple book formats possibly using Calibre for converting
  * this crashes it 'http://readwrite.com/tags/feed/start/articles.xml'
  * If you add your email it writes to a cookie and the big red warning goes away
  * Brad Feld's blog has some bad character encoding issues
