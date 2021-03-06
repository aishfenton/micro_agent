# Micro Agent

## Overview:
  
A simple simulator. This simulates changes to a collection of agents over a period
of time.

Setup the world. Each world is populated with a number of agents. Each agent has a collection
of properties that change over time. Properties change based on the rules you provide. Properties
can also depend on each other (as long as you don't create a cycle!).
   
    update = lambda { |agent| self.update(agent) }
    @world = Micro::World.new(1, 1, 1.0) do |i|
      Micro::MarkovAgent.new(
        :speed => Agent::Parameter.new do |p|
          p.start_value = (0..100).to_a.rand
          p.probability = 0.3
          p.max = 100
          p.min = 0
          p.change_func = lambda { |value| (value + (-10..10).to_a.rand) }
        end,
   
        :distance => Agent::Parameter.new do |p|
          p.start_value = 0
          p.depends_on :speed
          p.change_func = lambda do |distance, speed| 
            distance + (speed / 1.hour)
          end
        end
      )
    end

Set the world in motion.  

    @world.start

Get a callback on each change

    def change
      @world.agents.each do |agent|
        pp agent
      end
    end

## Install:

  sudo gem install visfleet-micro_agent

### Dependancies

- eventmachine (http://rubyeventmachine.com/)

## LICENSE:

(The MIT License)

Copyright (c) 2008 FIX

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
