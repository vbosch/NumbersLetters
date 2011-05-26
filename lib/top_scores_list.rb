require 'zlib'

module LettersNumbers
  class TopScoreList
    
    attr_reader :max_num_scores
    
    def initialize(new_max_num_scores)
      
      @max_num_scores = new_max_num_scores
      @scores = Array.new
      
    end
    
    def has_scores?
      return true if @scores.size > 0
      return false
    end
    
    def best_score
      return @scores.first
    end
    
    def worst_score
      return @scores.last
    end
    
    def can_add_score?(new_score)
      
      return true if @scores.size == 0 or  @scores.size < @max_num_scores or new_score.points > @scores.last.points
  
      return false
    end
    
    def add_scores(scores)
      scores.each{|score| add_score(score)}
      return @scores.size
    end
    
    def add_score(new_score)
      if can_add_score? new_score
        @scores.push(new_score)
        @scores.sort.reverse!
        @scores.pop if @scores.size > @max_num_scores
      end
      return @scores.size      
    end
  
    def save(file_name)
      marshal_dump = Marshal.dump(self)
      file = File.new(file_name,'w')
      file = Zlib::GzipWriter.new(file)
      file.write marshal_dump
      file.close
    end
    
    def self.load(file_name)
      begin
        file = Zlib::GzipReader.open(file_name)
      rescue Zlib::GzipFile::Error
        file = File.open(file_name, 'r')
      ensure
        obj = Marshal.load file.read
        file.close
        return obj
      end
    end
    
    private :can_add_score?
  end
  
end