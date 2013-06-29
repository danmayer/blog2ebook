Blog2Ebook
===

This is a simple project that started because I was going on a trip and wanted to turn some full blogs into books on my kindle. Take your blogs on the go, or just enjoy reading on a kindle screen more than a computer screen this project can help.

* Currently supports only Kindle
  * RSS feed to kindle
  * Single post to kindle (useful because some https sites no longer allow bookmarklets to work)
  * Copied Text to kindle 

To see a a brief overview of the project see my post [Introducing Blog2Ebook](http://mayerdan.com/ruby/2013/06/20/introducing-blog2ebook/)

## CI Build Status

[![Build Status](https://secure.travis-ci.org/danmayer/blog2ebook.png)](http://travis-ci.org/danmayer/blog2ebook)

This project runs [travis-ci.org](http://travis-ci.org)

## To Run Locally

    foreman start
    open http://localhost:3000
    
    #old way
    bundle exec rackup -p 3000
    redis-server
    open http://localhost:3000


## Examples

    open "http://localhost:3000/kindleizeblog?url=http://mayerdan.com/atom.xml&email=YOUREMAIL@gmail.com"
    open "http://localhost:3000/kindleizeblog?url=http://erinashleymiller.com/feed/&email=YOUREMAIL@gmail.com"
    open "http://localhost:3000/kindleizeblog?url=http://codeascraft.com/feed/&email=YOUREMAIL@gmail.com"
    open "http://localhost:3000/kindleizeblog?url=http://techblog.netflix.com/rss.xml&email=YOUREMAIL@gmail.com"

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
* [blog2book pothi app](http://blog2book.pothi.com/app/)
* [ruby bookshop](https://github.com/blueheadpublishing/bookshop)

## TODO

  * Download and embed images from posts (likely requires compiling to mobi file)
  * This works to convert html with images to mobi `kindlegen -verbose redis_book/redis_book.html -o redisbook.mobi`
  * Support multiple book formats possibly using Calibre for converting
  * Stripe purchase integration
  * Support converting github repos to kindle formatted books
  * Crashes on single article 'http://www.washingtonpost.com/blogs/wonkblog/wp/2013/06/10/going-to-college-is-worth-it-even-if-you-drop-out/'
  
## Contributing

1. Fork it.
2. Create a branch (git checkout -b my_markup)
3. Commit your changes (git commit -am "Added something awesome, it does X which solves problem Y")
4. Push to the branch (git push origin my_markup)
5. If you haven't already read about good [Pull Request practices](http://codeinthehole.com/writing/pull-requests-and-other-good-practices-for-teams-using-github/) or have never submitted one before read about submitting [your first pull request](http://jumpstartlab.com/news/archives/2013/04/15/your-first-pull-request)
6. Open a [Pull Request](https://help.github.com/articles/using-pull-requests)
7. Awesome thanks I will try to get back to you soon.

## MIT License

See the file license.txt for copying permission.

