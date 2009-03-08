require "rubygems"
require 'eventmachine'

module Micro

  # The world populates  
  # 
  class World
    attr_accessor :agents, :callback
  
    def initialize(cycle_delay_seconds, number_of_agents, percent_per_cycle = 1.0, callback = nil, &proc)
      @cycle_delay_seconds = cycle_delay_seconds
      @callback = callback
      @number_of_agents = number_of_agents
      @create_agent_proc = proc
      @percent_per_cycle = percent_per_cycle
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
        EventMachine::add_periodic_timer( @cycle_delay_seconds ) { step_agents }
      end
    end
  
    def step_agents
      @agents.each do |agent|
        next unless rand <= @percent_per_cycle
        agent.step
        @callback.call(agent) unless @callback.nil?
      end
    end
  
  end

  # An agent is a autonomous entity that interacts with the Micro::World. Each agent has a collection 
  # of properties that are updated over time (i.e. with each call to #step_agents in the #World).
  # 
  # Dependancy relationships can be setup between an agent's parameters. So that properties:
  #   a.depends_on b.depends_on c
  #   d.depends_on b.depends_on c
  #   b.depends_on c
  # This is useful where one parameter is required for calculation of another. For example, calculating a 
  # _speed_ parameter might require you to know the values of the _distance_ and _time_ parameters. #step_agents 
  # calculates dependancies in the correct order, making that a parameter's dependants are calculated first . 
  # Note however that cyclic depends_on relationships aren't supported.
  # 
  # The runtime complexity of processing dependacies is still O(n) (where n is the number of parameters) even with
  # complex dependency trees thanks to the niftyness of dynamic programming algorithms.
  # 
  class MarkovAgent
    attr_accessor :parameters
  
    def initialize(parameters)
      @parameters = parameters
      @already_done = Hash.new
    end

    # Updates the parameter value using the parameter's change function. Each parameter is updated with
    # probability equal to its probability value.
    # 
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
  
  # Represents an individual parameter of an agent. Parameters are updated with each call to #step_world.
  # See the attributes below for a description of the properties that are possible on each parameter. 
  # 
  class Parameter
    # The probility that this parameter is updated. Should be between 0.0 and 1.0.
    attr_accessor :probability
    
    # The starting value of this parameter
    attr_accessor :start_value
    
    # Takes a passed in block. The block is used to update this parameter's value. The block is passed the current
    # value of this parameter and then the value of any dependant parameter's values (in the order they are specified
    # in the depends_on property). This looks like:
    #   
    #   :speed => Micro::Parameter.new do |p|
    #     p.start_value = 0
    #     p.depends_on  = :distance, :time
    #     p.change_func = lambda { |value, distance, time| distance / time }
    #   end
    # 
    attr_accessor :change_func

    # Specifies which parameter's this parameter is dependent on for it's calculations. See #change_func 
    attr_accessor :depends_on

    # Specifies an upper and lower bound on this parameter's value.  
    attr_accessor :max, :min 
    
    attr_accessor :value, 

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