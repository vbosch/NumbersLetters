#! /usr/bin/env ruby -Ku -riconv

require 'trollop'
require 'drb'
require_relative '../lib/game'

opts = Trollop::options do
  version "Remote game 0.0.1 (c) 2010 Vicente Bosch Campos"
  banner <<-EOS
remote_game creates a stand alone process for a Numbers and Letters game so that it can be consumed remotely.

Usage:
       remote_game [options]
where [options] are:
EOS

  opt :port, "Port where the remote game server must listen for incoming connections ", :type =>:int, :default => 9002
  opt :user_name, "User name of the game owner", :type => :strings
  opt :wait_time, "Wait time for a user that pauses the game", :type => :int, :default => 30


end
#Defining special considerations for the entry data

Trollop::die :user_name, "User name must be given" if opts[:user_name].nil?

composed_name = opts[:user_name].inject(""){|result,string| result += string+" "}.strip

LettersNumbers::Game.new(opts[:port],composed_name,opts[:wait_time])
