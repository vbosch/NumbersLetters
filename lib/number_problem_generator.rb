require 'ap'

module LettersNumbers
  class NumberProblemGenerator
  
    attr_reader :target , :selectedNumbers, :operators
  
    def initialize(mode=:random, *args)
      @operators = ["-","+","*","/"]
      @filePath=args[0]
      
      case mode
      when :random
        randomStart
      when :file
        fileStart
      end
    end
    
    def complete?
      return true if @selectedNumbers.length == 6 and @target > 101 and @target < 999
      return false
    end

    def randomStart
      
      @target = Random.new.rand(101..999)
      
      numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 25, 50, 75,100]
      
      @selectedNumbers = Array.new

      numbers.shuffle.each do |value|
        selectedNumbers.push(value) #unless selectedNumbers.include?(value)
        break if selectedNumbers.length == 6
      end
    end
    
    def fileStart()
      
      numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 25, 50, 75,100]
      
      File.open(@filePath) do |file|
        while line = file.gets
          values = line.split.collect!{|i| i.to_i}
          raise "Wrong number of values in file" if values.size !=7          
          @target = values[0]
          raise "Target must be between 101 and 999" if @target < 101 or @target > 999
          @selectedNumbers = values[1..6]
          
          raise "Resolution numbers not correct" if (@selectedNumbers - numbers).length != 0
          
        end
      end
    end
    
  end
end

