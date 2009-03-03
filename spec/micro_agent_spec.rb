$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'micro_agent'
require 'active_support'

describe Micro::World, "with a single agent" do
  
  before(:each) do
    @world = Micro::World.new(1, 1) do |i|
      Micro::MarkovAgent.new(
        :speed => Micro::Parameter.new do |p|
          p.start_value = (0..100).to_a.rand
          p.probability = 0.3
          p.max = 100
          p.min = 0
          p.change_func = lambda { |value| (value + (-10..10).to_a.rand) }
        end,
        :distance => Micro::Parameter.new do |p|
          p.start_value = 0
          p.depends_on = :speed
          p.change_func = lambda do |distance, speed|
            distance + (speed / 1.hour)
          end
        end
      )
    end
  end

  it "should update it's parameters" 

  it "should pass in dependant parameters t"

  it "should call its callback" do
    obj = mock("obj")
    @world.callback = lambda { |agent| obj.callback }

    obj.should_receive(:callback).once
    @world.tick
  end
  
end

describe Micro::World, "with many agents" do
  
  before(:each) do
    @world = Micro::World.new(1, 10) do |i|
      Micro::MarkovAgent.new(
        :speed => Micro::Parameter.new do |p|
          p.start_value = (0..100).to_a.rand
          p.probability = 0.3
          p.max = 100
          p.min = 0
          p.change_func = lambda { |value| (value + (-10..10).to_a.rand) }
        end
      )
    end
  end

  it "should call its callback for each agend update" do
    obj = mock("obj")
    @world.callback = lambda { |agent| obj.callback }

    obj.should_receive(:callback).exactly(10)
    @world.tick
  end
  
end