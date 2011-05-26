require 'stomp'
require 'ap'
require 'ruby-debug'

module Messaging
  class Message
    attr_reader :type, :method_name, :parameters, :to
    def initialize(new_to,new_type,new_method_name,new_params)
      @to = new_to
      @type = new_type
      @method_name = new_method_name
      @parameters = new_params
    end
  end
  
  class MessageManager
    attr_accessor :object_queue_name, :address 
    def initialize(new_adress,new_host_name,new_port,new_object,new_queue=nil)
      @address = new_adress
      @host_name = new_host_name
      @port = new_port
      @client = Stomp::Client.new "system", "manager",@host_name, @port, true
      @managed_object = new_object
      @object_queue_name = "/queue/#{new_queue}"
    end
    
    def subscribe(new_queue)
      new_queue ="/queue/#{new_queue}"
      @client.subscribe new_queue do | msg |
        @curr_msg = msg
        process(Marshal.load(msg.body))
#        @client.acknowledge message # tell the server the message was handled and to dispose of it
      end
    end
    
    def unreceive
      @client.unreceive(@curr_msg)
    end
    
    def unsubscribe(old_queue)
      old_queue ="/queue/#{old_queue}"
      @client.unsubscribe old_queue
    end
    
    def freeze_subscriptions
      @client.join
    end
    
    def broadcast(address_list,type,method_name,*parameters)
      address_list.each do |to|
        publish(to,type,method_name,*parameters)
      end
    end

    def publish(to,type,method_name,*parameters)
      begin
#       debugger
        @client.publish(@object_queue_name,Marshal.dump(Messaging::Message.new(to,type,method_name,parameters)),{:persistent => true})
      rescue Exception=> error
        puts error
        return false
      end
      return true
    end
    
    def process(new_message)
        if new_message.to == @address and new_message.type == @managed_object.class and @managed_object.respond_to? new_message.method_name
          @managed_object.send(new_message.method_name,*new_message.parameters)
        else
          unreceive
        end
    end
    
    def end_messaging
      @client.close
    end
    
    private :process
  end
  
  
end