require_relative '../lib/solution'
require_relative '../lib/application_configuration'


module LettersNumbers
  class LettersSolution < Solution
    
    def initialize(new_id,new_word,new_problem)
    
      super(new_id,new_word,new_problem)
      @word=new_word
      @dictionary=Utils::ApplicationConfiguration.instance.dictionary
      @type = (@dictionary.word_exists? @word )? :valid : :invalid 
      @dictionary = nil
    end
    
    def points
      return @word.length
    end
    
    def distance
      return @problem.letters.length-@word.length if is_valid?
      return -1
    end
        
  end
end