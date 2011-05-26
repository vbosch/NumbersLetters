require 'singleton'
require_relative '../lib/dictionary.rb'
require_relative '../lib/top_scores_list.rb'

module Utils
  class ApplicationConfiguration
    include Singleton
    DICT_FILE_PATH = "../resources/dicc.obj"
    WORD_LIST_PATH_FILE = "../resources/palabra.txt"
    SCORES_FILE_PATH = "../resources/scores.obj"
    attr_reader :dictionary, :top_scores
    
    def initialize    
      initialize_dictionary
      initialize_top_scores
    end
    
    def initialize_dictionary
      if File.exists? DICT_FILE_PATH
        @dictionary = LettersNumbers::Dictionary.load(DICT_FILE_PATH)
      else
        @dictionary = LettersNumbers::Dictionary.new(WORD_LIST_PATH_FILE)
      end
    end
    
    def initialize_top_scores
      if File.exists? SCORES_FILE_PATH
        @top_scores = LettersNumbers::TopScoreList.load(SCORES_FILE_PATH)
      else
        @top_scores = LettersNumbers::TopScoreList.new(10)
      end
    end
    
    def save_application_status
      @dictionary.save(DICT_FILE_PATH)
      @top_scores.save(SCORES_FILE_PATH)
    end
    
    private :initialize_top_scores , :initialize_dictionary 
  end
end