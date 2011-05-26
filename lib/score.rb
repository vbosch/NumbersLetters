module LettersNumbers
  class Score
    
    attr_reader :name, :points
    
    def initialize(new_name)
      @name = new_name
      @points = 0
    end
    
    def add_points(new_test_points)
      raise "Points can not be negative" if new_test_points < 0
      @points += new_test_points
    end
    
    def <=> (other_score)
      case
        when @points > other_score.points 
          return 1
        when @points == other_score.points 
          return 0
        else 
          return -1
      end
    end
    
    
  end
  
end