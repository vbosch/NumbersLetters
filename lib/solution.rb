require_relative '../lib/operation_graph'

module LettersNumbers
  class Solution
    attr_reader :id , :type
    
    def initialize(new_id,solution_specification,new_problem)
      @id = new_id
      @problem = new_problem 
    end
    
    def is_valid?
      return true if @type == :valid
      return false
    end
    
    def exact?
      return true if @type==:valid and distance.zero?
      return false
    end
    
    def distance
      raise "Method distance is to be implemented by the child class"
    end
    
    def <=> (other_solution)
      
      my_dist = distance
      other_dist = other_solution.distance
      
      case
        when ((my_dist !=-1 and other_dist == -1) or (my_dist !=-1 and other_dist != -1 and @points > other_solution.points))
          return 1
        when ((my_dist ==-1 and other_dist == -1) or (my_dist !=-1 and other_dist != -1 and @points == other_solution.points)) 
          return 0
        else 
          return -1
      end
    end
    
    
  end
end