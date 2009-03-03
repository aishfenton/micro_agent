require 'eventmachine'

module Micro

  # The world populates  
  # 
  class World
    attr_accessor :agents, :callback
  
    def initialize(cycle_delay_seconds, number_of_agents, callback = nil, &proc)
      @cycle_delay_seconds = cycle_delay_seconds
      @callback = callback
      @number_of_agents = number_of_agents
      @create_agent_proc = proc
      create_agents
    end
  
    def create_agents
      @agents = []
      @number_of_agents.times do |i|
        @agents << @create_agent_proc.call(i)
      end
    end
  
    def start
      EM.run do
        EventMachine::add_periodic_timer( @cycle_delay_seconds ) { tick }
      end
    end
  
    def tick
      step_agents
    end

  private
  
    def step_agents
      @agents.each do |agent| 
        agent.step
        @callback.call(agent) unless @callback.nil?
      end
    end
  
  end

  # Doesn't support cyclic depends.
  class MarkovAgent
    attr_accessor :parameters
  
    def initialize(parameters)
      @parameters = parameters
      @already_done = Hash.new
    end

    # Updates the parameter value using the parameter's change 
    # function. Each parameter is updated with probability equal
    # to its probability value.
    # 
    # This method also takes care of dependencies between 
    # parameters. So that.. 
    #   a.depends_on b.depends_on c
    #   d.depends_on b.depends_on c
    #   b.depends_on c
    # is calculated in the correct order taking all dependencies 
    # into account.
    # Note: Runtime complexity is still O(n) even with complex dependency
    # trees thanks to a nifty dynamic programming algorithm.
    def step(number = 1)
      number.times do
        @already_done.clear
        @parameters.each_value do |parameter|
          process(parameter)
        end
      end
    end
  
    def [](parameter_name)
      @parameters[parameter_name].value
    end
    
    def values
      value_hash = {}
      @parameters.each_pair { |key, parameter| value_hash[key.to_s] = parameter.value }
      value_hash
    end

  private

    def process(parameter)
      return parameter.value if @already_done[parameter] || parameter.change_func.nil?

      values = [parameter.value]
      parameter.depends_on.each do |p_name|
        raise Exception.new("Can't 'depend_on' parameter #{p_name}. It doesn't exist") unless @parameters.has_key?(p_name)
        values << process(@parameters[p_name])
      end

      if rand() <= parameter.probability
        parameter.value = parameter.change_func.call(*values)
        parameter.value = limit_between(parameter.value, parameter.min, parameter.max)
      end
      @already_done[parameter] = true
      parameter.value
    end
    
    def limit_between(value, min, max)
      raise Exception.new("Max can't be less than Min") if min && max && (max < min)
      value = [value, min].max if min
      value = [value, max].min if max
      value
    end
    
  end
  
  class Parameter
    attr_accessor :probability, :start_value, :value, :change_func, :depends_on, :max, :min 

    def initialize
      @depends_on = []
      @probability = 1.0
      yield self
      @value = @start_value
    end
    
    def depends_on=(p_names)
      p_names = [p_names] unless p_names.instance_of? Array
      @depends_on = p_names
    end
    
  end
    
end