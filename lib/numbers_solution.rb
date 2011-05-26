require_relative '../lib/solution'
require_relative '../lib/operation_graph'

module LettersNumbers
  class NumbersSolution < Solution
    
    def initialize(new_id,new_operation_string,new_problem)
    
      super(new_id,new_operation_string,new_problem)
      @type = :valid
      begin
        @operation_graph = GeneticAlgorithm::OperationGraph.from_string(new_operation_string,@problem)
      rescue ArgumentError
        @type =:invalid
      end
    
    end
    
    def distance
      return @operation_graph.score(@problem.target) if type == :valid
      return -1
    end
    
  end
end