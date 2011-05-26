require_relative '../lib/operation_graph'
require_relative '../lib/genetic_population'
require_relative '../lib/number_problem_generator'
require_relative '../lib/application_logger'
require_relative '../lib/test'

require 'observer'
require 'drb'
require 'ruby-debug'

module LettersNumbers
  include DRbUndumped
  class NumbersTest < Test
    include Observable
    NUMBER_TEST_WINNER_POINTS = 8
    NUMBER_TEST_TIME=45
    
    def initialize(new_scores, id_turn)
      super(new_scores, id_turn)
      @problem = LettersNumbers::NumberProblemGenerator.new(:random)
      @user_answers= Hash.new
      @exact_answers= Hash.new
    end
    
    def ai_resolver
      @gen_population=GeneticAlgorithm::GeneticPopulation.new(100,200,problem.selectedNumbers,problem.operators,problem.target)
      return @gen_population.evolve(NUMBER_TEST_TIME).graph
    end
    
    def update_user_solution(solution)
      @user_answers[solution.id]=solution
      @exact_answers[solution.id]=solution if solution.exact?
    end
    
    def exact_solutions?
      return true if @exact_answers.length > 0
      return false
    end
    
    def best_exact_solution
      return @exact_answers.keys[0] if @exact_answers.keys == 1
      return @test_id_owner if @exact_answers.keys.include?(@test_id_owner)
      return @exact_answers.keys[0]
    end
    
    def winner
      
      best_score=-1
      best = []
      
      if exact_solutions?
        return best_exact_solution
      elsif solutions?
        @user_answers.each do |key,solution|
          if best_score == -1 or (solution.distance.is_valid? and solution.distance < best_score)
            best_score=solution.distance
            best = [solution.id]
          elsif solution.distance.is_valid? and solution.distance == best_score
            best.push(solution.id)
          end
        end
        return @test_id_owner if best.include?(@test_id_owner)    
        return best[0]
      else
        return -1 
      end
    end 
      
  end
end