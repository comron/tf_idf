#!/bin/env ruby

require "io/console"
require "./index.rb"
require "./frontend.rb"

DATA_FILE = File.join(File.dirname(__FILE__), "movies.dat")

puts "Loading index..."

movie_lookup = File.readlines(DATA_FILE).inject({}) do |h,line|
  data = line.split("|")
  h.merge( data[0] => data )
end

index = Index.new(File.dirname(__FILE__))
frontend = SearchFrontend.new(File.dirname(__FILE__))

# Read index from file and write it out
#index.intitialize_from_csv( :file, DATA_FILE )
#frontend.intitialize_from_csv( :file, DATA_FILE )
#
#index.write!( File.dirname(__FILE__))
#frontend.write!( File.dirname(__FILE__))

puts "Ready for searches..."

while line = gets
  line = line.strip
  frontend_results = frontend.search( line )
  p frontend_results

  if frontend_results[:longest] >= 1
    STDOUT.print "Do you want to search for a movie? [y/n]: "   
    ch = STDIN.getch
    STDOUT.print ch + "\n"

    if ch =~ /[yY]/
      results = index.search(line.strip)
      if results.empty?
        puts " ==> NO RESULTS"
      else
        puts results.map { |res| 
          " ==> " + 
            [movie_lookup[res[0]].map(&:strip)[1..3], res[1]].flatten.join(" - ")
        }.join("\n")
      end
    end
  end

  puts
end
