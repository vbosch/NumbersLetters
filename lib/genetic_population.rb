require_relative '../lib/operation_graph'
require_relative '../lib/application_logger'
require 'timeout'
require 'gnuplot'
require 'ap'


module GeneticAlgorithm
  class GeneticPopulation
    
    attr_reader :cycle, :abrupt_termination
    
    def initialize(exMinPopulation,exMaxPopulation,exSelectedNumbers,exOperators,exTarget)
      @minPopulation = exMinPopulation
      @maxPopulation = exMaxPopulation
      @selectedNumbers = exSelectedNumbers
      @operators = exOperators
      @target = exTarget
      @numGenerations=0
      @population = Array.new(Random.new.rand(@minPopulation..@maxPopulation)){OperationGraph.new(@selectedNumbers,@operators)}
      @logger = Utils::ApplicationLogger.instance
      @logger.level = Logger::INFO
      @logger.debug("LOGGER CREATED")
      @cycle=0
      @bestHistory=Hash.new
      @populationHistory=Hash.new
      @avgHistory = Hash.new
      @best = nil
      @best_score = @target
      #draw
    end
    
    def reducePopulation
      
      if @population.size > @maxPopulation
        trees2delete= @maxPopulation-@population.size
        score_buckets=@results_by_score.keys.sort
        while trees2delete>0
          score_buckets.reverse_each do |val|
            if results_by_score[val].size <= trees2delete
              results_by_score[val].clear
              results_by_score[val]=nil
              trees2delete -= results_by_score[val].size
            else
              results_by_score[val].shuffle!
              results_by_score[val]=results_by_score[val].first(results_by_score[val].size-trees2delete)
              trees2delete=0
            end
          end
        end
        @population = results_by_score.values.flatten
      end
    end
    
    def updateAverage
      
      val = 0
      count = 0
      
      @results_by_score.each do |key,trees|
        
        val += key * trees.length
        count += trees.length
        
        #draw_scores if key > @target 
        
      end
      
      val/=count
      
      @avgHistory[@cycle]=val
    
    end
    
    def evaluatePopulation
      results_by_score=Hash.new
      
      results_by_score.default_proc = lambda do |hash,key|
        hash[key]=Array.new
      end

      oldPopulation=@population
      @population = Array.new
      
      oldPopulation.each_with_index do |tree,i|
        score = tree.score(@target)
        
        if score != -1 and score < @best_score
          @best = tree.clone
          @best_score = score
          @bestHistory[@cycle]=score
        end
        
        if score != -1
          @population.push(tree) 
          results_by_score[score].push(tree)
        end
        
      end
      
      return results_by_score
    end
     
    def recoverPopulation
      if  @population.length < @minPopulation
        currPopNum = @population.length
        (@minPopulation - currPopNum).times{@population.push(OperationGraph.new(@selectedNumbers,@operators))} if currPopNum < @minPopulation      
      end
    end
    
    def draw
      @population.each{|tree| tree.draw}
    end
    
    def scores
      score_list = Hash.new
      score_list.default = 0
      @population.each do |tree|
       score_list[tree.score(@target)]+=1
     end
     return score_list  
    end
    
    def draw_best_history
      
      Gnuplot.open do |gp|
        Gnuplot::Plot.new( gp ) do |plot|

          plot.title  "Best Evolution"
          plot.ylabel "Score"
          plot.xlabel "Cycle"
          plot.boxwidth 1

          plot.data << Gnuplot::DataSet.new([@bestHistory.keys,@bestHistory.values]) do |ds|
            ds.with = "linespoints"
            ds.notitle
          end
        end
      end
      
    end
    
    def draw_avg_history
      
      Gnuplot.open do |gp|
        Gnuplot::Plot.new( gp ) do |plot|

          plot.title  "Average Score"
          plot.ylabel "Score"
          plot.xlabel "Cycle"
          plot.boxwidth 1

          plot.data << Gnuplot::DataSet.new([@avgHistory.keys,@avgHistory.values]) do |ds|
            ds.with = "lines"
            ds.notitle
          end
        end
      end
    
    end
    
    def draw_population_history
      
      Gnuplot.open do |gp|
        Gnuplot::Plot.new( gp ) do |plot|

          plot.title  "Population Count"
          plot.ylabel "Count"
          plot.xlabel "Cycle"
          plot.boxwidth 1

          plot.data << Gnuplot::DataSet.new([@populationHistory.keys,@populationHistory.values]) do |ds|
            ds.with = "lines"
            ds.notitle
          end
        end
      end
    
    end
    
    def draw_scores
      
      score_list = scores
      
      Gnuplot.open do |gp|
        Gnuplot::Plot.new( gp ) do |plot|

          plot.title  "Polulation Scores #{@cycle}"
          plot.ylabel "Population Count"
          plot.xlabel "Score"
          plot.boxwidth 1

          plot.data << Gnuplot::DataSet.new([score_list.keys,score_list.values]) do |ds|
            ds.with = "boxes"
            ds.notitle
          end
        end
      end
    end
    
    def actOnIndividual(tree,breeding_pair)
      
      operation = [:mutate!,:cloneMutant,:clone,:breed].sample
      case
      when [:mutate!,:cloneMutant,:clone].include?(operation)
        @population.push(tree.send(operation))
      when operation == :breed
        @population.push(tree.send(operation,breeding_pair))
      
      end
      
    end
    
    def selectIndividuals
      
      a = 0
      poolSelection = Array.new
      
      poolSelection.push(@best.clone)
      
      num2Select = Random.new.rand(@population.size/2..@population.size)
      
      while poolSelection.size < num2Select
        
        currSelected = -1
        
        ind = Random.new.rand(0..@population.size-1)
        
        currCutVal =  @best_score + (Random.new.rand(0.2..0.5)*@target)
        currScore= @population[ind].score(@target)
        
        #puts "CUT VALUE #{currCutVal}"
        
        if  currScore !=-1 and currScore < currCutVal 
           
        #  puts "ALLOWED #{currScore}" 
          currSelected = ind
          
        else 
         # puts "DISCARDED #{currScore} "
         
         a = a+1
        end
        
        poolSelection.push(@population[currSelected]) if currSelected !=-1
      
      end

      return poolSelection
      
    end
    
    def evolve(seconds=1000)
      
      @abrupt_termination=false
      
      begin 
        status = Timeout::timeout(seconds){
                  
        while true
            
          @cycle +=1
          
          @logger.debug("EVALUATION 1")
          @results_by_score = evaluatePopulation
          
          updateAverage
          
          break if @best_score == 0
            
          @logger.debug("RECOVERING POPULATION")                      
          recoverPopulation
          
          @logger.debug("SELECTING INDIVIDUALS")                    
          oldPopulation=selectIndividuals
          @population=Array.new
          
          @logger.debug("ACTING ON INDIVIDUALS")          
                    
          oldPopulation.each{|tree| actOnIndividual(tree,oldPopulation.sample)}
          
          @logger.debug("EVALUATION 2")
          @results_by_score = evaluatePopulation
        
          break if @best_score == 0
          
          @populationHistory[@cycle]=@population.size
      
          
          @logger.debug("REDUCING")
          reducePopulation
          
        end   
        }
      
      rescue Timeout::Error
        @abrupt_termination=true
        @logger.info("Termination due to time constraint")
         
      rescue Exception=> error
        @logger.error(error)      
      
      end
      
      
      return @best
    end
  end
end