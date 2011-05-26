require_relative '../lib/application_logger'
require_relative '../lib/application_configuration'
require_relative '../lib/letter_problem_generator'
require 'observer'
require 'ruby-debug'

module LettersNumbers
  
  class LettersTest < Test
    include Observable
    NUMBER_TEST_WINNER_POINTS = 1
    NUMBER_TEST_TIME= 1
    def initialize(new_scores, id_turn)
      super(new_scores, id_turn)
      @problem = LettersNumbers::LetterProblemGenerator.new
      @user_answers= Hash.new
      @dictionary=Utils::ApplicationConfiguration.instance.dictionary
    end
    
    def ai_resolver
      return @dictionary.longest_valid_words(@problem.letters)
    end
    
    def update_user_solution(solution)
      @user_answers[solution.id]=solution
    end
    
    def winner_points(new_winner_id)
      return @user_answers[new_winner_id].points
    end
    
    def winner
      best_score=-1
      best = []      
      if solutions?
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