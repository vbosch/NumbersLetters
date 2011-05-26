
module LettersNumbers
  class LetterProblemGenerator
    attr_reader :letters
    LETTER_PROBLEM_LENGTH = 9
    
    def initialize
      @letters = Array.new
      @vowels = ["a","e","i","o","u"]
      @consonants = (("a".."z").to_a - @vowels).push("ñ")
      random_selection
    end
    
    def complete?
      return true if @letters.length == LETTER_PROBLEM_LENGTH
      return false
    end
    
    def add_consonant
      @letters.push(@consonants.sample) unless complete?
      return @letters.last
    end
    
    def add_vowel
      @letters.push(@vowels.sample) unless complete?
      return @letters.last
    end
    
    def random_selection
      ops = [:add_consonant,:add_vowel]
      LETTER_PROBLEM_LENGTH.times{send(ops.sample)}
    end
    
  end
end