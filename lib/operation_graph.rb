require 'rgl/adjacency'
require 'rgl/dot'
require 'RMagick'
require 'ruby-debug'

module Enumerable
  def dups
    inject({}) {|h,v| h[v]=h[v].to_i+1; h}.reject{|k,v| v==1}.keys
  end
end


module GeneticAlgorithm
  class OperationGraph
    
    attr_reader  :consumedNumbers, :operatorNodes, :valueNodes, :level ,:type
    
    attr_accessor :operator, :parent, :root # :unconsumedNumbers
    
    def self.from_string(new_operation_string,problem)
      @consumedNumbers = Array.new
      @unconsumedNumbers = problem.selectedNumbers
      @availableOperators = problem.operators
      @stack = Array.new     
      @operation = new_operation_string.split.reverse
      @root = OperationGraph.new([],@availableOperators)
      @operation.each_with_index do |char,index|
         begin 
           update_operation_stack(type_to_node(char,index))
         rescue ArgumentError
           raise ArgumentError, "Operation specification is incorrect"
         end
      end
      
      return -1 if @stack.size > 1
      
      return @stack[0]
      
    end
    
    def self.update_operation_stack(node)
      node.setChildren(@stack.pop,@stack.pop,@unconsumedNumbers,node.operator) if node.type == :operator
      @stack.push(node)
    end
 
    def self.type_to_node(char,index)   
      numeric_form = char.to_i
      type = char_type?(char)
      #debugger    
      case type
        when :value then
          @unconsumedNumbers.delete_at(@unconsumedNumbers.find_index(numeric_form))
          return OperationGraph.new([numeric_form],@availableOperators, (index == @operation.length-1) ? 0 : 1,@root ,nil)   
        when :operator then
          if index == (@operation.size-1)
            @root.operator = char
            return @root
          else
            return OperationGraph.new([],[char],1,@root,nil)    
          end
        else    
           raise ArgumentError, "Operation string is invalid"   
      end
    end
  
    def self.char_type?(char)
      numeric_form = char.to_i
      if numeric_form != 0 and @unconsumedNumbers.include?(numeric_form)
        return :value 
      elsif @availableOperators.include?(char)  
        return :operator
      else  
        return :invalid
      end
    end
    
    def initialize(ex_numbers,ex_operators,ex_level=0,ex_root=nil,ex_parent=nil)
          @consumedNumbers = Array.new
          @availableOperators = ex_operators
          @level = ex_level
          @parent = ex_parent
          @root = ex_root

          if @level == 0

            @changed=true
            @operations = Array.new
            @total_num = ex_numbers.length
            @unconsumedNumbers = ex_numbers
            @operatorNodes = Array.new
            @valueNodes=Array.new
            @diagram=RGL::DirectedAdjacencyGraph.new
            @root = self

            if @unconsumedNumbers.length > 0
              numbers2Consume =  Random.new.rand(1..@unconsumedNumbers.length-1)
              #numbers2Consume =  1
              @consumedNumbers = @unconsumedNumbers.sample(numbers2Consume)
              @unconsumedNumbers -= @consumedNumbers
            else 
              @consumedNumbers = []
              @unconsumedNumbers -= []

            end

            #puts "INITIAL SELECTED NUMBERS"
            #ap @consumedNumbers

          else
            @consumedNumbers = ex_numbers
          end


          if @consumedNumbers.length == 0
            @type=:operator
            @value=0
            @leftChild=nil
            @rightChild=nil
            @operator= @availableOperators[Random.new.rand(0..@availableOperators.length-1)]


          elsif @consumedNumbers.length == 1

            transform2Child(@consumedNumbers[0])

          else

            transform2Op(@consumedNumbers)

          end
    end
 

    
    def level=(val)
      
      @level = val
      if @type == :operator
        @leftChild.update_level(val+1) unless @leftChild.nil?
        @rightChild.update_level(val+1) unless @rightChild.nil?
      end
      
    end
    
    def unconsumedNumbers
      return @root.unconsumedNumbers if @level > 0
      return @unconsumedNumbers
    end
    
    def diagram
      return @root.diagram if @level > 0
      return @diagram
    end
    
    def operatorNodes
      return @root.operatorNodes if @level > 0
      return @operatorNodes
    end
    
    def valueNodes
      return @root.valueNodes if @level > 0
      return @valueNodes
    end
    
    def value
      raise "Operator node has no value" if @type == :operator
      return @consumedNumbers[0]
    end
    
    def value=(val)
      raise "Operator node has no value" if @type == :operator
      
    #  puts "VALUE HAS CHANGED"
     # puts "Initiated in #{self.object_id} level #{@level}"
      #puts "my parent is #{@parent.object_id}"
      
      
      
      @parent.changeConsumedNumber(@consumedNumbers[0],val) if @parent != nil
      @consumedNumbers[0]=val
    end

 
    def result
      
      return @consumedNumbers[0] if @type==:value

      if @type == :operator  
        begin 
          leftVal=@leftChild.result
          rightVal=@rightChild.result
        rescue ArgumentError
          raise if @level > 0
          return -1 #dumb child
        end
        
        if @operator == "/" and rightVal == 0
          raise ArgumentError, "Division by 0 not allowed", caller if @level >0
          return -1
        end
      
        if @operator == "/" and (leftVal % rightVal > 0)
          raise ArgumentError, "Unexact division", caller if @level > 0
          return -1
        end
       
        return eval("#{leftVal}#{@operator}#{rightVal}")
      end 
    end
    
    def clone
      return Marshal::load(Marshal.dump(self))
    end

    def <=> (node)
      case
        when object_id > node.object_id 
          return 1
        when object_id == node.object_id
          return 0
        else 
          return -1
      end     
    end

    def transform2Child(val)
      @type=:value
      @leftChild = nil
      @rightChild=nil
      @consumedNumbers = [val]   
        valueNodes.push(self)
    end
     
    def transform2Op(values)
        
        @consumedNumbers = values
        @type=:operator
        @operator= @availableOperators[Random.new.rand(0..@availableOperators.length-1)]
        operatorNodes.push(self)
        
        splitIndex=Random.new.rand(0..@consumedNumbers.length-2)
        
        @leftChild = OperationGraph.new(@consumedNumbers[0..splitIndex],@availableOperators,@level+1,@root,self)
        @rightChild= OperationGraph.new(@consumedNumbers[splitIndex+1..@consumedNumbers.length-1],@availableOperators,@level+1,@root,self)
    end

    def changeConsumedNumber(oldVal,newVal)
      
      #puts "I am #{self.object_id} leve #{@level}"
      #ap @consumedNumbers
      #puts "Old Value: #{oldVal} New Value: #{newVal}"
      index=@consumedNumbers.find_index(oldVal)
      @consumedNumbers[index]=newVal
      
      #puts "my parent is #{@parent.object_id}"
      
      @parent.changeConsumedNumber(oldVal,newVal) if @parent != nil
    end
    
    def addConsumedNumber(val)      
      @consumedNumbers.push(val)
      @parent.addConsumedNumber(val) if @parent != nil
    end
  
    def deleteConsumedNumbers(array_val)
      
      dup_a = array_val.clone
      old = @consumedNumbers
      @consumedNumbers=Array.new
      old.each_with_index do |val,index|
          del_index = dup_a.find_index(val)
          if  del_index.nil?
            @consumedNumbers.push(val)
          else
            dup_a.delete_at(del_index)
          end 
      end
      @parent.deleteConsumedNumbers(array_val) if @parent !=nil
    end
    
    def score(target)
      
      return -1 if @total_num != @unconsumedNumbers.length + @consumedNumbers.length
      
      if @changed
        @last_result = result
        @changed=false
      end
      
      if @last_result !=-1
        return (target - @last_result).abs
      else 
        return -1
      end
    end
    
    def draw
      
      @diagram=RGL::DirectedAdjacencyGraph.new if @level == 0
      
      if @type == :value
        diagram.add_vertex(@consumedNumbers[0])
        diagram.add_edge("#{@parent.operator}  (#{@parent.object_id})",@consumedNumbers[0]) unless @parent == nil
        
      else
        diagram.add_vertex("#{@operator}  (#{self.object_id})")
        diagram.add_edge("#{@parent.operator}  (#{@parent.object_id})","#{@operator}  (#{self.object_id})") unless @parent == nil
        @leftChild.draw
        @rightChild.draw
      end
      
      if @level == 0
        diagram.write_to_graphic_file('png',"#{self.object_id}") 
        Magick::ImageList.new("#{self.object_id}.png").display
        File.delete("#{self.object_id}.png","#{self.object_id}.dot")
        @diagram=nil
      end
        
    end
    
    def graph
      
      @diagram=RGL::DirectedAdjacencyGraph.new if @level == 0
      
      if @type == :value
        diagram.add_vertex(@consumedNumbers[0])
        diagram.add_edge("#{@parent.operator}  (#{@parent.object_id})",@consumedNumbers[0]) unless @parent == nil
        
      else
        diagram.add_vertex("#{@operator}  (#{self.object_id})")
        diagram.add_edge("#{@parent.operator}  (#{@parent.object_id})","#{@operator}  (#{self.object_id})") unless @parent == nil
        @leftChild.draw
        @rightChild.draw
      end
      
      if @level == 0
        return @diagram
      end
        
    end
    
    
    

 
    def mutate!
      
      @changed=true
      #debugger if @valueNodes.length != @consumedNumbers.length

      executing = private_methods(false).grep(/Mutation\z/).sample
      #@operations.push(executing)
      #puts executing
      send(executing)
      return self
    end
    
    def cloneMutant
      clone.mutate!
    end
    
    def operatorSwitchMutation #changes the operator used at a node
      
      if operatorNodes.length > 0
        randOpIndex=Random.new.rand(0..operatorNodes.length-1)
        operatorNodes[randOpIndex].operator = @availableOperators[Random.new.rand(0..@availableOperators.length-1)]
      end
    
    end
    
    def numberSwitchMutation #changes location of two used numbers
      
      if @consumedNumbers.length > 1
        
        randUsedNumIndexFrom = Random.new.rand(0..@consumedNumbers.length-1)
        randUsedNumIndexTo = Random.new.rand(0..@consumedNumbers.length-1)
        
        if randUsedNumIndexFrom != randUsedNumIndexTo
          
          currUsedFrom = valueNodes[randUsedNumIndexFrom].value
          currUsedTo = valueNodes[randUsedNumIndexTo].value
          valueNodes[randUsedNumIndexFrom].value = currUsedTo
          valueNodes[randUsedNumIndexTo].value = currUsedFrom
        end
                
      end
    
    end
    
    def unusedNumberSwitchMutation #switches a used for an unused
      
      if unconsumedNumbers.length > 0
        randNumIndex=Random.new.rand(0..valueNodes.length-1)
        randUnusedNumIndex = Random.new.rand(0..unconsumedNumbers.length-1)
        currUsed = valueNodes[randNumIndex].value
        
        
        
        #puts "VALUE TO STOP USING #{currUsed}"
        valueNodes[randNumIndex].value= unconsumedNumbers[randUnusedNumIndex]
        unconsumedNumbers[randUnusedNumIndex] = currUsed

      end
      
    end
    
    def unusedNumberMutation #uses a currently unused number in combination of a used one (new operation node created)
      
      if unconsumedNumbers.length > 0
        randNumIndex=Random.new.rand(0..valueNodes.length-1)
        randUnusedNumIndex = Random.new.rand(0..unconsumedNumbers.length-1)
        newNumToUse= unconsumedNumbers[randUnusedNumIndex]
        unconsumedNumbers.delete_at(randUnusedNumIndex)
        currNode = valueNodes[randNumIndex]
        valueNodes.delete(currNode)
        
        #puts "ASKING MY PARENT TO UPDATE"
        
        #puts "My level is #{@level}"
        
        #puts "IS NIL #{@parent.nil?}"
        
        currNode.parent.addConsumedNumber(newNumToUse) if currNode.parent != nil     
        values = [currNode.value,newNumToUse]
        currNode.transform2Op(values)

        
        
      end  
    end

    def deleteOperationMutation #deletes a sub operation
           
      if operatorNodes.length > 0
        
        randOpIndex=Random.new.rand(0..operatorNodes.length-1)
        currNode = operatorNodes[randOpIndex]
        finalVal = currNode.consumedNumbers.sample
#        puts "on current node"
#        ap currNode.consumedNumbers
#        puts "on whole graph"
#        ap @consumedNumbers
        childvalueNodes = Array.new
        childvalueNodes = currNode.getTypeNodes(:value,childvalueNodes)
#        debugger if childvalueNodes.length != currNode.consumedNumbers.length
#        debugger if @valueNodes.length != @consumedNumbers.length
        valueNodes.delete_if{|node| childvalueNodes.include?(node)}
#        debugger if @valueNodes.length != @consumedNumbers.length
        count_final = currNode.consumedNumbers.count(finalVal)
        deleteList = currNode.consumedNumbers.delete_if{|val| val == finalVal}
        deleteList.concat([finalVal]*(count_final-1)) if count_final > 1
        
#        debugger if @valueNodes.length != @consumedNumbers.length
        
#        debugger if @valueNodes.length != @consumedNumbers.length
        @unconsumedNumbers.concat(deleteList)
#        debugger if @valueNodes.length != @consumedNumbers.length
        currNode.deleteConsumedNumbers(deleteList)
        currNode.transform2Child(finalVal)
        debugger if @valueNodes.length != @consumedNumbers.length
        
        currNode.deleteSubTreeOperators
        
      end


    end
    
    def deleteSubTreeOperators() #deletes all operation nodes beneath the selected
      
      operatorDeleteList=[self]
      operatorNodes.delete_if{|node| node.object_id == object_id}
      lastLength = 0
      
      while operatorDeleteList.length > lastLength
        lastLength = operatorDeleteList.length
        operatorNodes.each_with_index do |node,index|

          if operatorDeleteList.include?(node.parent)

            operatorDeleteList.push(node)
            operatorNodes.delete_at(index)
          end
        end
      end
    end

    def breed (father) #Hence the breeding happens on the mother :-)
      
      mother_breed_point = nil
      father_breed_point = nil 
      
      if consumedNumbers - father.consumedNumbers == consumedNumbers.size
        #Numbers used are not the same.. we can go wild on the choosing
          
        mother_breed_point = @operatorNodes.sample.clone  
        father_breed_point = father.operatorNodes.sample.clone
      
      else
        
        good_matches = Array.new
        
        @operatorNodes.each do |mother_subtree|
          father.operatorNodes do |father_subtree|
            if mother_subtree.consumedNumbers - father_subtree.consumedNumbers == mother_subtree.consumedNumbers.length
              good_matches.push([mother_subtree,father_subtree])
            end
            
          end
        end
      
      #select a breeding point from the good matches
      return cloneMutant if good_matches.size == 0
      
      selection = good_matches.sample
      
      mother_breed_point=selection[0].clone
      father_breed_point=selection[1].clone
        
      end
      #create baby
      
      mother_breed_point.level=1
      father_breed_point.level=1
      
      iniNumbers = @consumedNumbers + @unconsumedNumbers
      newConsumedNumbers = mother_breed_point.consumedNumbers + father_breed_point.consumedNumbers
      newUnconsumedNumbers = iniNumbers- newConsumedNumbers
      
      child = OperationGraph.new([],@availableOperators)
      child.setChildren(mother_breed_point,father_breed_point,newUnconsumedNumbers) 
      puts "GIVING BIRTH"
      return child
      
    end

    def setChildren(left,right,unconsumed,new_op = nil)
            
      @type= :operator
      if new_op.nil?
        @operator= @availableOperators[Random.new.rand(0..@availableOperators.length-1)]
      else
        @operator=new_op
      end
      @consumedNumbers = left.consumedNumbers + right.consumedNumbers
      left.parent = self
      right.parent = self
      @leftChild= left
      @rightChild= right
      
      if @level == 0
        @unconsumedNumbers = unconsumed
        @total_num = @consumedNumbers.length + @unconsumedNumbers.length
        leftOpNodes = @leftChild.getTypeNodes(:operator,[])
        rightOpNodes = @rightChild.getTypeNodes(:operator,[])
        @operatorNodes = leftOpNodes + rightOpNodes
        @operatorNodes.push(self)
        
        leftValNodes = @leftChild.getTypeNodes(:value,[])
        rightValNodes = @rightChild.getTypeNodes(:value,[])
        @valNodes = leftValNodes + rightValNodes
        
        @operatorNodes.each{|node| node.root = self}
        @valNodes.each{|node| node.root = self}
        
      end  
    end
      
    def getTypeNodes(type,list)
      if @type == :operator
        list = @leftChild.getTypeNodes(type,list)
        list = @rightChild.getTypeNodes(type,list)
      end
      list.push(self) if @type == type    
      return list
    end
  

    private :operatorSwitchMutation, :numberSwitchMutation ,:unusedNumberSwitchMutation ,:unusedNumberMutation, :deleteOperationMutation
       
  end
end