#! /usr/bin/env ruby -Ku -riconv

require_relative '../lib/game_server'
require 'trollop'

opts = Trollop::options do
  version "Remote game 0.0.1 (c) 2010 Vicente Bosch Campos"
  banner <<-EOS
numbers_letters_server creates a game server that creates and mananges Numbers and Letters games.

Usage:
       numbers_letters_server [options]
where [options] are:
EOS

  opt :game_server_port, "Port where the remote game server must listen for incoming connections ", :type =>:int, :default => 9001
  opt :game_queue_port, "Port where the queue server will be listening", :type => :int, :default => 61613
end

LettersNumbers::GameServer.new(opts[:game_server_port],opts[:game_queue_port])