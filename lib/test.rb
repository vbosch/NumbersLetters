require_relative '../lib/application_logger'

require 'observer'
require 'ruby-debug'

module LettersNumbers
  class Test
    include Observable
    attr_reader :problem , :best_ai_solution
    NUMBER_TEST_WINNER_POINTS = 8
    NUMBER_TEST_TIME=10
    
    def initialize(new_scores, id_turn)
      @test_id_owner = id_turn
      @scores = new_scores  
      @status = :paused
      @logger = Utils::ApplicationLogger.instance
      @logger.level = Logger::INFO
    end
    
    def test_time
      return self.class::NUMBER_TEST_TIME
    end
    
    def problem_completely_defined?
      return @problem.complete?
    end
    
    def start_test
      if problem_completely_defined?
        @status = :started
        fork { exec("sleep #{self.class::NUMBER_TEST_TIME}") }
        @solution_thread = Thread.new do
          @best_ai_solution = ai_resolver
          changed
        end
      end      
    end
    
    def ai_resolver
      raise "set_user_solution method must be implemented by child class"
    end
    
    def end_test
      @status = :ended
      update_scores
      notify_observers(self)
    end
    
    def started?
      return true if @status == :started
      return false
    end
    
    def ended?
      return true if @status == :ended
      return false
    end
    
    def set_user_solution(solution)
      
      raise ArgumentError "Invalid user id given" if solution.id < 0 or solution.id >= @scores.length
      
      if started?
        update_user_solution(solution)
      end
      
      @solution_thread.join
      @logger.info("AI finished waiting for test timer")
      Process.wait
      end_test
    end
    
    def update_user_solution(solution)
      raise "update_user_solution method must be implemented by child class"
    end
    
    def update_scores
      @logger.info("Updating solution scores")
      if ended?
        winner_id = winner
        @scores[winner_id].add_points(winner_points(winner_id)) if winner_id !=-1
      end
      return @scores
    end
    
    def winner_points(new_winner_id)
      return self.class::NUMBER_TEST_WINNER_POINTS
    end
    
    def solutions?
      return true if @user_answers.length > 0
      return false
    end
    
    def winner
      raise "winner method must be implemented by child class"      
    end 
      
  end
end