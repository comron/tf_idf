#!/bin/env ruby

require "rubygems"
require "bundler/setup"
require "bloomfilter-rb"
require "bindata"
require "./shared.rb"

class SearchFrontend

  include Shared

  FILENAME = "bloomfilter".freeze

  def initialize( location )
    file = File.join( location, FILENAME)
    if File.exists?( file )
      @data = BloomFilter::Native.load(file)
    else 
      @data = BloomFilter::Native.new(
        :size => 10000,
        :seed => 1,
        :hashes => 2,
        :bucket => 1
      )
    end
  end

  def intitialize_from_csv( type, data )
    if type == :data
      data.each do |text|
        bigrams(text).each do |term|
          @data.insert( term ) 
        end
      end
    elsif type == :file
      File.readlines(data).each do |line|
        line_data = line.split("|")
        @data.insert( bigrams( line_data[1] ) )
      end
    end
  end


  def search( text )
    {:ratio => 0, :longest => 0}.tap do |results|
      matched = 0
      current_run = 0
      p text

      all_bigrams = bigrams(text)
      p all_bigrams
      all_bigrams.each do |term|
        if @data.include?(term)
          current_run += 1
          matched += 1
        else
          results[:longest] = [results[:longest], current_run].max
          current_run = 0
        end
      end
      
      results[:longest] = [results[:longest], current_run].max
      results[:ratio] = matched / all_bigrams.size.to_f
    end
  end


  def write!( location )
    @data.save( File.join(location, FILENAME ) ) 
  end

  private
  
  def bigrams( text )
    terms = to_terms(text) 
    terms.select { |word| word.include?(" ") }
  end


end



