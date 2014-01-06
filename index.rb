#!/bin/env ruby

require "rubygems" 
require "bundler/setup" 
require "bindata"

DATA_FILE = File.join(File.dirname(__FILE__), "movies.dat")
STOP_WORDS = "a,able,about,across,after,all,almost,also,am,among,an,and,any,are,as,at,be,because,been,but,by,can,cannot,could,dear,did,do,does,either,else,ever,every,for,from,get,got,had,has,have,he,her,hers,him,his,how,however,i,if,in,into,is,it,its,just,least,let,like,likely,may,me,might,most,must,my,neither,no,nor,not,of,off,often,on,only,or,other,our,own,rather,said,say,says,she,should,since,so,some,than,that,the,their,them,then,there,these,they,this,tis,to,too,twas,us,wants,was,we,were,what,when,where,which,while,who,whom,why,will,with,would,yet,you,your".split(",").freeze

class IndexVector

  [:size, :[], :each, :keys].each do |method|
    define_method(method) do |*args|
      @data.send(method, *args)
    end
  end
  
  def initialize( hash )
    @data = hash
  end

  def norm
    Math.sqrt( @data.values.map { |v| v*v }.inject(0, &:+) )
  end

  def dot_product( other_vector )
    result = 0

    reference_vector = other_vector
    if size < other_vector.size 
      reference_vector = self 
    end

    reference_vector.keys.each do |term|
      result += (other_vector[term] || 0) * (@data[term] || 0)
    end
    
    result.to_f
  end


  def cosine_score( other_vector )
    dot_product( other_vector ) / (norm * other_vector.norm ) 
  end

end


class Index
  attr_reader :term_frequency_matrix, :inverse_document_frequency, :document_index 

  SCALE = 1_000

  def initialize( location = nil )
    @term_frequency_matrix = {}
    @inverse_document_frequency = Hash.new(0) 
    @total_document_count = 0
    @all_terms = []
    @document_index = {}
    
    unless location.nil?
      index_file = File.join(location, "index")
      idf_file = File.join(location, "idf")
      terms_file = File.join(location, "terms")
      
      @all_terms = File.readlines(terms_file).map(&:strip)
     
      File.open(index_file, "r+") do |f|
        until f.eof?
          document = ""
          vector = {}
          20.times do 
            document << BinData::Uint8be.read(f).snapshot.to_s(16).rjust(2,"0")
          end
          
          size = BinData::Uint8be.read(f).snapshot
          size.times do 
            term_index = BinData::Uint16be.read(f).snapshot 
            value = BinData::Uint16be.read(f).snapshot / SCALE 
            vector[ @all_terms[term_index] ] = value
          end
          
          @document_index[document] = vector
        end
      end

      File.open(idf_file, "r") do |f|  
        idx = 0
        until f.eof?
          value = f.read(4).unpack("I").first / SCALE.to_f
          @inverse_document_frequency[@all_terms[idx]] = value
          idx += 1
        end
      end
    end 
  end

  def [](key)
    @document_index[key]
  end
  
  def intitialize_from_csv( type, data )
    if type == :data
      @data = data
    elsif type == :file
      @data = File.readlines( data )
    end

    total_terms = 0

    @data.each do |line|
      line_data = line.split("|")
      document_terms = term_frequency( line_data[1] )
      total_terms += document_terms.size

      @term_frequency_matrix[line_data[0]] = document_terms
      @total_document_count += 1
      
      document_terms.keys.each do |term|
        @inverse_document_frequency[term] ||= 0
        @inverse_document_frequency[term] += 1
      end
    end

    @inverse_document_frequency.keys.each do |term|
      quotient = @total_document_count.to_f / @inverse_document_frequency[term]
      @inverse_document_frequency[term] = Math.log( quotient )
    end

    @all_terms = @inverse_document_frequency.keys.sort

    @term_frequency_matrix.each do |document, vector|
      vector.each do |term, term_score|
        @document_index[document] ||= Hash.new(0)
        @document_index[document][term] = term_score * @inverse_document_frequency[term]
      end
    end
  end

  def search( text, top = 10 )
    search_terms = make_vector( text )
    scored_documents = @document_index.keys.inject({}) do |h, k|
      score = search_terms.cosine_score( IndexVector.new( @document_index[k] ) ) 
      h.merge( { k => score.nan? ? 0 : score } )
    end

    top_scored = scored_documents.sort_by { |_,score| -score }.take(top)
    top_scored.reject { |result| result[1] == 0 || result[1].nan? }
  end


  def write!( location )
    index_file = File.join(location, "index")
    idf_file = File.join(location, "idf")
    term_file = File.join(location, "terms")
    
    File.open(index_file, "wb") do |f|  
      @document_index.each do |doc,vector|
        doc.scan(/../).each do |byte|
          BinData::Uint8be.new(byte.hex).write(f)
        end
        
        BinData::Uint8be.new(vector.size).write(f)
        
        vector.to_a.each do |pair|
          BinData::Uint16be.new(@all_terms.index(pair[0])).write(f)
          BinData::Uint16be.new((pair[1]*SCALE).to_i).write(f)
        end
      end
    end 

    File.open(idf_file, "wb") do |f|  
      @all_terms.each do |term|
        v = (@inverse_document_frequency[term] * SCALE).to_i
        f.write( [v].pack("I") ) 
      end
    end 
    
    File.open(term_file, "wb") do |f| 
      @all_terms.each do |term|
        f.write( term )
        f.write( "\n" )
      end
    end 
  end


  private
  def to_terms( text )
    terms = text.downcase.split(/[\s+\-:]/)
    terms.reject! { |word| STOP_WORDS.include?(word) }
   
    terms.map! do |term|
      term.gsub(/[^a-z0-9]/, '')
    end

    terms.reject! do |term|
      term.length == 0 
    end
    
    bigrams = []
    terms.each_cons(2) do |bigram|
      bigrams << bigram.join(" ")
    end

    terms += bigrams
  end

  def term_frequency( text )
    terms = to_terms( text )
    results = Hash.new(0).tap do |vector|
      terms.each do |term|
        vector[term] ||= 0
        vector[term] += 1
      end
    end

    return results
  end

  def make_vector( text )
    IndexVector.new(
      {}.tap { |vector|
        term_frequency( text ).each { |term, freq|
          vector[term] = freq * @inverse_document_frequency[term] 
        }
      }
    )
  end


end

if __FILE__ == $0
  puts "Loading index..."

  movie_lookup = File.readlines(DATA_FILE).inject({}) do |h,line|
    data = line.split("|")
    h.merge( data[0] => data )
  end

  index = Index.new(File.dirname(__FILE__))
  #index.intitialize_from_csv( :file, DATA_FILE )
  #index.write!( File.dirname(__FILE__))

  puts "Ready for searches..."
  while line = gets
    results = index.search(line.strip)
    if results.empty?
      puts " ==> NO RESULTS"
    else
      puts results.map { |res| " ==> " + [movie_lookup[res[0]].map(&:strip)[1..3], res[1]].flatten.join(" - ") }.join("\n")
    end
    puts
  end


end
