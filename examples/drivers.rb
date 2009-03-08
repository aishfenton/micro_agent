#!/usr/bin/ruby

$:.unshift(File.dirname(__FILE__) + '/../lib')

require "micro_agent"
require "active_support"
require "pp"

class Drivers
      
  def initialize
    setup_world
    @inner_kml = ""
  end
  
  def setup_world
    update = lambda { |agent| self.populate_inner_kml(agent) }
    @world = Micro::World.new(nil, 1, 1.0, update) do |i|
      Micro::MarkovAgent.new(
        :name => Micro::Parameter.new do |p|
          p.start_value = "sim_#{i.to_s}"
        end,

        :heading => Micro::Parameter.new do |p|
          p.start_value = (0..359).to_a.rand
          p.probability = 0.1
          p.change_func = lambda { |value| (value + (0..120).to_a.rand) % 360 }
        end,
            
        :ignition => Micro::Parameter.new do |p|
          p.start_value = true
          p.probability = 0.001
          p.change_func = lambda { |value| !value}
        end,
      
        :speed => Micro::Parameter.new do |p|
          p.start_value = (1..130).to_a.rand
          p.depends_on  = :ignition
          p.probability = 0.2
          p.change_func = lambda { |value, ignition| ignition ? value + (-30..30).to_a.rand : 0 }
          p.max = 135
          p.min = 0
        end,

        :seconds_delta => Micro::Parameter.new do |p|
          p.start_value = 0
          p.change_func = lambda { |value| (1..5).to_a.rand }
        end,
      
        :distance_delta => Micro::Parameter.new do |p|
          p.start_value = 0
          p.depends_on  = :speed, :seconds_delta
          p.change_func = lambda do |distance_delta, speed, seconds_delta|
            # assume speed in kmph
            distance_delta = (speed.to_f / 1.hour) * seconds_delta
          end
        end,
      
        :y => Micro::Parameter.new do |p|
          p.start_value = -39.0
          p.depends_on  = :heading, :distance_delta
          p.change_func = lambda do |y, heading, distance_delta|
            # assume heading in degress
            y_km = Math.cos(heading / (180/Math::PI)) * distance_delta
            # assume 111 km per 1 degree
            y + (y_km / 111.0)
          end
        end,
      
        :x => Micro::Parameter.new do |p|
          p.start_value = 176.0
          p.depends_on  = :heading, :distance_delta, :y
          p.change_func = lambda do |x, heading, distance_delta, y|
            x_km = Math.sin(heading / (180/Math::PI)) * distance_delta
            # assume spheriod earth
            x + x_km / (Math.cos(y / (180/Math::PI)) * 111.0)
          end
        end
      ) 
    end
  end

  def step(number)
    number.times { @world.step_agents }
  end

  def populate_inner_kml(agent)
    @inner_kml << <<-EOS
    <Placemark>
      <name>#{agent[:name]}</name>
      <Point>
        <coordinates>#{agent[:x]}, #{agent[:y]}</coordinates>
      </Point>
    </Placemark>
EOS
  end
  
  def to_kml
    <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    #{@inner_kml}
  </Document>
</kml>
EOS
  end
  
end

d = Drivers.new
d.step(100)
puts d.to_kml

