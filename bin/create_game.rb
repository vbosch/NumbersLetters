#! /usr/bin/env ruby -Ku -riconv

require 'ap'
require 'trollop'
require_relative '../lib/game_client'

opts = Trollop::options do
  version "create game 0.0.1 (c) 2010 Vicente Bosch Campos"
  banner <<-EOS
Create game lets you create Cifras y Letras game.

Usage:
       create_game [options]
where [options] are:
EOS
  opt :game_server_host, "Host where the game server is held", :typ=>:string, :default => "localhost"
  opt :game_server_port, "Port where the remote game server is listening for incoming connections ", :type =>:int, :default => 9001
  opt :player_name, "Name of the player", :type =>:string, :default => "Creator"
  opt :game_id, "Id of the game we want to join", :type => :int
  opt :wait_time, "Time to wait for player that has paused the game", :type => :int,:default => 30
end

game_client = LettersNumbers::GameClient.new(opts[:player_name],opts[:game_server_host],opts[:game_server_port])

game_client.create_game(opts[:wait_time])

puts "PRESS ENTER TO START GAME"
gets

game_client.start_game