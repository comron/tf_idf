#!/bin/env ruby

require "rubygems" 
require "bundler/setup" 
require "test/unit"

require File.expand_path( File.join( File.dirname(__FILE__), "..", "frontend" ) )


class TestFrontEnd < Test::Unit::TestCase

  MOVIE_DATA = %Q[ Homeland: Season 2
Now You See Me
A Good Day to Die Hard
Identity Thief
The Great Gatsby
Iron Man 3
Silver Linings Playbook
World War Z
Oblivion
Game of Thrones: Season 1
Olympus Has Fallen
Game of Thrones: Season 2].split("\n")

  def test_basic_search
    frontend = SearchFrontend.new(".")
  
    results = frontend.search( "nothing in the filter yet" )
    assert_equal 0, results[:ratio]
    assert_equal 0, results[:longest]

 
    frontend.intitialize_from_csv(:data, MOVIE_DATA)
    results = frontend.search( "you seen the movie the silver linings playbook" )
    assert_equal 2/4.0, results[:ratio]
    assert_equal 2, results[:longest]

    frontend.intitialize_from_csv(:data, MOVIE_DATA)
    results = frontend.search( "good day die hard" )
    assert_equal 1, results[:ratio]
    assert_equal 3, results[:longest]
  end





end


