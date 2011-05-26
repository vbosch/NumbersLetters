require_relative '../lib/game'
require_relative '../lib/application_logger'
require_relative '../lib/numbers_solution'
require_relative '../lib/letters_solution'
require_relative '../lib/letter_problem_generator'
require_relative '../lib/number_problem_generator'

require 'drb'
require 'ruby-debug'
require 'ap'
require 'rgl/adjacency'
require 'rgl/dot'
#require 'rmagick'


module LettersNumbers
  class GameClient
    include DRbUndumped
    def initialize(new_user_name,new_server_ip,new_server_port)      
      DRb.start_service
      @server_port = new_server_port
      @server_ip = new_server_ip
      @user_name = new_user_name
      @logger = Utils::ApplicationLogger.instance
      @logger.level = Logger::INFO
      initialize_game_status            
      begin
        @game_server = DRbObject.new(nil, "druby://#{@server_ip}:#{@server_port}")
        @queue_game_port = @game_server.queue_game_port
        @server_status=:connected
        @logger.info("GAME CLIENT - Connected to game server")
      rescue Exception=> error
        @logger.error("GAME CLIENT - Could not connect to server")
        @logger.error(error)
        @server_status=:disconnected            
      end
    end
    
    def initialize_game_status
      @is_in_game = false
      @is_owner = false
      @game_port = nil
      @game_pid = nil
      @game_id = -1
    end
    
    def connected_to_server?
      return true if @server_status == :connected
      return false
    end
    
    def retrieve_games_list
      if connected_to_server?
        return @game_server.list_games
      end
    end
    
    def in_game?
      return @is_in_game
    end
    
    def leave_game
      if in_game? and not owner_of_game?
        @message_manager.publish(-1,Game,:kill_player,@game_id)
        initialize_game_status
      end
    end
    
    def owner_of_game?
      return @is_owner
    end
    
    def game_started?
      return @game.started? if in_game?
    end
    
    def list_users_of_game
      return @game.player_list
    end
    
    def create_game(new_pause_game_time)
      if connected_to_server? and not in_game?
        begin
          @logger.info("GAME CLIENT - Creating game")
          @game_pid=@game_server.create_game(new_pause_game_time,@user_name)
          @logger.info("GAME CLIENT - Getting game_queue")
          @game_id = 0
          @is_in_game = true
          @is_owner = true
          @logger.info("GAME CLIENT - Will publish messages in #{@game_pid}-#{@game_id}")
          @message_manager = Messaging::MessageManager.new(0,@server_ip,@queue_game_port,self,"#{@game_pid}-#{@game_id}")
          @logger.info("GAME CLIENT - Joining game queue #{@game_pid}")
          @message_manager.subscribe(@game_pid)
        rescue Exception=> error
          initialize_game_status
          @logger.error("GAME CLIENT - Could not connect to game")
          @logger.error(error)
        end
      end
    end
    
    def update(action,*object)
      case action
      when :start_test
        act_on_problem(object[0])
      when :end_test
        @logger.info("GAME CLIENT - Test has ended!!")
        print_scores(object[0])
        act_on_ai_solution(object[1]) 
      when :start_game
        @logger.info("GAME CLIENT - Game has started!!") 
        @message_manager.publish(-1,Game,:next_test) if owner_of_game?
      when :end_game
        @logger.info("GAME CLIENT - Game has ended!!")
        initialize_game_status
        print_scores(object[0])
        print_winner(object[0])
        @game_server.update_top_scores(object[0]) if owner_of_game?
        @message_manager.end_messaging 
      end    
    end
    
    def act_on_ai_solution(solution)
      puts "BEST AI SOLUTION:"
      if solution.class == Array
        ap solution
      else
        solution.write_to_graphic_file('png',"#{self.object_id}")
        #Magick::ImageList.new("./#{self.object_id}.png").display
        #File.delete("#{self.object_id}.png","#{self.object_id}.dot")
      end
    end
    
    def print_scores(scores)
      scores = scores.sort.reverse
      
      puts "GAME SCORE"
      scores.each_with_index do |score,index|
        puts "#{index}. #{score.name} #{score.points}"
      end
    end
    
    def print_winner(scores)
      winner_score = scores.sort.last
      puts "The winner is #{winner_score.name} with #{winner_score.points}"
      
    end
    
    def act_on_problem(problem)
      
      if problem.class == NumberProblemGenerator
        respond_to_numbers_test(problem)
      elsif problem.class == LetterProblemGenerator
        respond_to_letters_test(problem)
      else
        @logger.error("GAME CLIENT - Actions not defined for test!!")
      end
    
    end
    
    def respond_to_numbers_test(problem)
       
        puts "SELECTED NUMBERS"
        ap problem.selectedNumbers
        puts "TARGET"
        ap problem.target
        op_string = gets
        @message_manager.publish(-1,Game,:set_user_solution,NumbersSolution.new(0,op_string.chomp!,problem))
    end
    
    def respond_to_letters_test(problem)
      puts "Selected letters are:"
      ap problem.letters
      op_string = gets
      @message_manager.publish(-1,Game,:set_user_solution,LettersSolution.new(0,op_string.chomp!,problem))
    end
    
    def game_joined(new_user_name,new_id)
      @logger.info("GAME CLIENT - Joined game message reached")
      if @user_name == new_user_name 
        if new_id > 0
          @is_in_game = true
          @game_id = new_id
          @message_manager.object_queue_name = "#{@game_pid}-#{@game_id}"
          @message_manager.address = @game_id.to_i
        else
          @logger.info("GAME CLIENT - Could not join game, name is already in use!!")
        end
      else
        @message_manager.unreceive
      end
    end
    
    def start_game
      if in_game? and owner_of_game?
        @message_manager.publish(-1,Game,:start_game)
        @message_manager.freeze_subscriptions
      end
    end
    
    def join_game(new_game_pid)
      if connected_to_server? and not in_game?
        @game_pid = new_game_pid
        begin
         @logger.info("GAME CLIENT - Trying to join game #{@game_pid}")
         @message_manager = Messaging::MessageManager.new(0,@server_ip,@queue_game_port,self,"#{@game_pid}-0")
#         debugger
         @message_manager.subscribe(@game_pid)
         @message_manager.publish(-1,Game,:add_player,@user_name)
         @message_manager.freeze_subscriptions
        rescue Exception=> error
          initialize_game_status
          @logger.error("GAME CLIENT - Could not connect to game")
          @logger.error(error)
        end
      end
    end
    
    private :respond_to_letters_test , :respond_to_numbers_test, :act_on_problem, :print_scores, :print_winner ,:initialize_game_status
    
  end
end