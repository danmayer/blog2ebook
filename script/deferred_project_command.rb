#!/usr/bin/env ruby

require 'pry'
require 'sinatra'
require './app.rb'
disable :run

puts "running..."
results = `curl -X POST "http://git-hook-responder.herokuapp.com/deferred_project_command?project=danmayer/blog2ebook&signature=#{ENV['BLOG_2_BOOK_TOKEN']}&project_request=/"`
puts "results: #{results}"
results_hash = JSON.parse(results)
puts 'waiting...'
sleep(8)
results_data = `curl "http://git-hook-responder.herokuapp.com/#{results_hash['results_location']}"`
puts results_data
