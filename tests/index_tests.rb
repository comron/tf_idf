#!/bin/env ruby

require "rubygems" 
require "bundler/setup" 
require "test/unit"

require File.expand_path( File.join( File.dirname(__FILE__), "..", "index" ) )


class TestGenerateIndex < Test::Unit::TestCase

MOVIE_DATA = [
"abcd|The Wolf of Wall Street|http://www.wows.com|2013",
"efgh|American Hustle|http://www.hustle.com|2013",
"gfhs|American Pie|http://www.Pie.com|2010",
"fhjd|Wall Street|http://www.ws.com|1982",
"zdew|Wall Street Wall|http://www.Pie.com|2010",
]

def idf(term_docs, total_docs)
  term_docs == 0 ? 0 : Math.log( total_docs.to_f / term_docs )
end


def test_term_frequency_matrx
  index = Index.new
  index.intitialize_from_csv( :data, MOVIE_DATA )
  matrix = index.term_frequency_matrix

  wolf_results = matrix["abcd"]
  assert_equal 1, wolf_results["wolf"]
  assert_equal 1, wolf_results["wall"]
  assert_equal 1, wolf_results["street"]
  assert_equal 0, wolf_results["the"]
  assert_equal 0, wolf_results["of"]
  assert_equal 0, wolf_results["american"]

  wsw_results = matrix["zdew"]
  assert_equal 2, wsw_results["wall"]
  assert_equal 1, wsw_results["street"]
end

def test_inverse_document_frequency
  index = Index.new
  index.intitialize_from_csv( :data, MOVIE_DATA )
  matrix = index.inverse_document_frequency

  assert_equal idf(1,5), matrix["wolf"]
  assert_equal idf(3,5), matrix["wall"]
  assert_equal idf(3,5), matrix["street"]
  assert_equal idf(0,5), matrix["the"]
  assert_equal idf(0,5), matrix["of"]
  assert_equal idf(2,5), matrix["american"]

end

def test_index_all_documents
  index = Index.new
  index.intitialize_from_csv( :data, MOVIE_DATA )

  wolf_results = index["abcd"]
  assert_equal 1*idf(1,5), wolf_results["wolf"]
  assert_equal 1*idf(3,5), wolf_results["wall"]
  assert_equal 1*idf(3,5), wolf_results["street"]
  assert_equal 0, wolf_results["the"]
  assert_equal 0, wolf_results["of"]
  assert_equal 0, wolf_results["american"]


  wsw_results = index["zdew"]
  assert_equal 2*idf(3,5), wsw_results["wall"]
  assert_equal 1*idf(3,5), wsw_results["street"]

end

def test_vector
  vector_a = IndexVector.new( {:x => 1, :y => 2, :z => 3 })
  vector_b = IndexVector.new( {:x => 3, :y => 4, :z => 5 })

  assert_equal 26, vector_a.dot_product(vector_b)
  assert_equal Math.sqrt(14), vector_a.norm
  assert_equal Math.sqrt(50), vector_b.norm
  assert_equal 26/(Math.sqrt(14)*Math.sqrt(50)), vector_a.cosine_score(vector_b)

end


end
