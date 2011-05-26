require_relative '../lib/game'
require_relative '../lib/application_logger'
require_relative '../lib/application_configuration'
require 'drb'

module LettersNumbers
  class GameServer
    
    def initialize(new_port,new_message_queue_port)
      @logger = Utils::ApplicationLogger.instance
      @logger.level = Logger::INFO
      @logger.info("GAME SERVER - Starting game server")
      @port = new_port
      @message_queue_port = new_message_queue_port
      @queue_server_pid=nil
      @games=Array.new
      @last_port_used = @port
      
      set_child_cleaner
      set_server_cleaner
      start_queue_server
      publish_game_server
    end
    
    def set_child_cleaner
      trap("CLD") do 
        pid = Process.wait
        @logger.info("GAME SERVER - Game #{pid} has finished") 
        clean_game(pid)
      end
    end
    
    def set_server_cleaner
      trap("EXIT") do
        @logger.info("GAME SERVER - Stopping game server") 
        kill_games
        stop_queue_server
      end
    end
    
    def clean_game(pid)
      @games.each do |game|
        if game[:id] == pid
          @games.delete(game)
          return true
        end
      end
      return false
    end
    
    def start_queue_server
      @queue_server_pid = fork{ exec("../resources/apache-activemq-5.5.0/bin/macosx/activemq start")}
    end
    
    def stop_queue_server
      fork{ exec("../resources/apache-activemq-5.5.0/bin/macosx/activemq stop")}
      @queue_server_pid=nil
    end
    
    def queue_game_port
      return @message_queue_port
    end
    
    def update_top_scores(scores)
      top_scores = Utils::ApplicationConfiguration.instance.top_scores
      top_scores.add_scores(scores)
      Utils::ApplicationConfiguration.instance.save_application_status
    end
    
    def get_top_scores
      return Utils::ApplicationConfiguration.instance.top_scores
    end
    
    def publish_game_server
      DRb.start_service("druby://localhost:#{@port}", self)
      @logger.info("GAME SERVER - Game server running and published in #{@port}") 
      DRb.thread.join
    end
    
    def create_game(new_pause_game_time,new_owner_name)
      if @queue_server_pid != nil
        @logger.info("GAME SERVER - Creating game...")
        pid=fork { exec("./remote_game.rb -p #{@message_queue_port} -u #{new_owner_name} -w #{new_pause_game_time}") }
        @games.push({:id => pid, :owner_name => new_owner_name, :wait_time => new_pause_game_time})
        return pid
      end
      return nil
    end
    
    def kill_games
      @games.each do |game|
        Process.kill("HUP", game[:id])
      end
    end
    
    def list_games
      return @games
    end
    
    private :set_child_cleaner, :set_server_cleaner, :clean_game, :start_queue_server, :stop_queue_server, :publish_game_server, :kill_games
    
  end
end