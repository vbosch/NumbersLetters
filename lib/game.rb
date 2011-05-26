require_relative '../lib/score'
require_relative '../lib/numbers_test'
require_relative '../lib/letters_test'
require_relative '../lib/numbers_solution'
require_relative '../lib/application_logger'
require_relative '../lib/messaging'
require_relative '../lib/game_client'

require 'ap'
require 'stomp'

module LettersNumbers
  class Game
    attr_reader :port
    
    def initialize(new_port,new_owner_name,new_pause_game_time)
      @logger = Utils::ApplicationLogger.instance
      @logger.level = Logger::INFO
      @port = new_port
      @logger.info("GAME - Creating game ID: #{Process.pid.to_s}")
      @game_scores = Array.new
      @status = :preparing
      @pause_game_time = new_pause_game_time
      @tests = [:NumbersTest,:LettersTest,:LettersTest,:NumbersTest,:LettersTest,:LettersTest,:NumbersTest,:LettersTest,:LettersTest,:NumbersTest]      
      @user_names = Array.new
      @logger.info("GAME - Will send messages through #{Process.pid.to_s}")
      @message_manager = Messaging::MessageManager.new(-1,"localhost",@port,self,Process.pid.to_s)
      set_server_cleaner
      add_player(new_owner_name)
      @message_manager.freeze_subscriptions
    end
    
    def set_server_cleaner
      trap("EXIT") do
        @logger.info("GAME - Stopping game due to server signaling") 
        end_game
      end
    end
    
    def game_owner
      return @game_scores[0].name
    end
    
    def started?
     return true if  @status == :started
     return false
    end
    
    def in_preparation?
      return true if @status == :preparing
      return false
    end
    
    def players_in_game
      return @game_scores.length
    end
    
    def add_player(new_name)
      puts new_name
      if @status == :preparing and not @user_names.include?(new_name)
        @game_scores.push(Score.new(new_name))if @status == :preparing
        @user_names.push(new_name)
        @logger.info("GAME - New player has arrived #{new_name}")
        @message_manager.subscribe("#{Process.pid}-#{@game_scores.size-1}")
        @message_manager.publish(0,GameClient,:game_joined,new_name,@game_scores.size-1) if last_added_player_is_not_owner_player?
        return true
      end
      @message_manager.publish(0,GameClient,:game_joined,-1)
      return false
    end
    
    def last_added_player_is_not_owner_player?
      return  @game_scores.size > 1
    end
    
    def player_list
      return @user_names
    end
    
    def my_id(new_user_name)
      @game_scores.each_with_index do |score,index|
        return index if score.name == new_user_name 
      end      
      return -1
    end
    
    def start_game
      @logger.info("GAME - Started")
      @status = :started
      @player_status = Array.new(@game_scores.size,:ok)
      @current_test_index=-1
      @id_list = (0..@game_scores.size-1).to_a
      @message_manager.broadcast(@id_list,GameClient,:update,:start_game)
    end
        
    def tests_pending?
      return true if @current_test_index < @tests.length-1
      return false
    end
      
    def next_test
      @current_test_index+=1
      @current_test = Object.const_get(:LettersNumbers).const_get(@tests[@current_test_index]).new(@game_scores,@current_test_index) if can_proceed_to_next_test?
      @current_test.add_observer(self)
      @logger.info("GAME - Sending players test update")
      @message_manager.broadcast(@id_list,GameClient,:update,:start_test,@current_test.problem)
      @current_test.start_test
    end
    
    def set_user_solution(solution)
      @current_test.set_user_solution(solution) if started? and @current_test != nil
    end
    
    def update(test)
      if test.ended? and tests_pending?
        @message_manager.broadcast(@id_list,GameClient,:update,:end_test,@game_scores,@current_test.best_ai_solution)
        next_test
      else
        end_game
      end
    end
        
    def can_proceed_to_next_test?
      count = @player_status.count{|status| status == :ok}
      return true if count == @player_status.size
      return false
    end
    
    def pause_game(id)
      @player_status[id] = :pause if id < @player_status.size
    end
    
    def resume_game(id)
      @player_status[id] = :ok if id < @player_status.size
    end
     
    def kill_player(id)
      @game_score.delete_at(id)
      @message_manager.unsubscribe("#{Process.pid}-#{id}")
    end
    
    def end_game
      @status = :ended
      @message_manager.broadcast(@id_list,GameClient,:update,:end_game,@game_scores)
      @message_manager.end_messaging
    end
    
    def winner
      return @game_scores.sort.last
    end
    
    def classification
      return @game_score.sort.reverse
    end
    
    private :set_server_cleaner ,:end_game ,:last_added_player_is_not_owner_player?, :tests_pending?, :can_proceed_to_next_test?
    
  end
end
