#! /usr/bin/env ruby -Ku -riconv

require 'ap'
require 'trollop'
require_relative '../lib/game_client'

opts = Trollop::options do
  version "Remote game 0.0.1 (c) 2010 Vicente Bosch Campos"
  banner <<-EOS
Join game lets you join a created Cifras y Letras game.

Usage:
       join_game [options]
where [options] are:
EOS
  opt :game_server_host, "Host where the game server is held", :typ=>:string, :default => "localhost"
  opt :game_server_port, "Port where the remote game server is listening for incoming connections ", :type =>:int, :default => 9001
  opt :player_name, "Name of the player", :type =>:string, :default => "Anonymous"
  opt :game_id, "Id of the game we want to join", :type => :int
end



game_client = LettersNumbers::GameClient.new(opts[:player_name],opts[:game_server_host],opts[:game_server_port])

game_client.join_game(opts[:game_id])
