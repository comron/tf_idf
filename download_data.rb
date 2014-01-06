#!/bin/env ruby

require "rubygems" 
require "bundler/setup" 
require "nokogiri"
require "open-uri"
require "digest"

INSTANT_WATCHER_BASE_URL = %Q{http://instantwatcher.com/titles/highest_rated/}


File.open("movies.dat", "w+") do |file|
  111.times do |index|

  seen_items = {}

  url = [INSTANT_WATCHER_BASE_URL, (index + 1).to_s].join
  page = Nokogiri::HTML( open( url ) )

  list = page.css("#title-listing li")
  list.each do |item| 
    title_tag = item.css(".title-list-item-link")
    title = title_tag.text
    hash = Digest::SHA1.hexdigest(title.downcase.strip)
    link = [%Q{http://instantwatcher.com}, title_tag.attr("href")].join
    year = item.css(".releaseYear").text
   
    unless seen_items.key?(hash)
      seen_items[hash] = title
      file.puts [hash, title, link, year].join("|")
    end
  end

  end
end
