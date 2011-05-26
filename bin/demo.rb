#! /usr/bin/env ruby -Ku -riconv

require 'ap'

require_relative '../lib/game'

require_relative '../lib/spanish_dictionary'

dict = LettersNumbers::Dictionary.new("../resources/test.txt")

puts dict.word_exists?("abajeño")

ap dict.longest_valid_words(["a","a","r","o","n","i","c","o","a"])

#game = LettersNumbers::Game.new(30)

#game.add_player("V. Bosch")

#game.start_game

#x.draw