require './mesh'
require 'geo3d'
require './util/geo3d_matrix.rb'
require 'ostruct'


# Object_Indirection encapsulates the builder for an independent object
#
# Object_Indirection.render outputs a vertex array of vertexes in that object's 3D space
#
# Object_Indirection.render aggregates sub-components
#   renders sub-components to generate sub-component vertex arrays
#   translate, rotate and scales sub components vertexes to the correct place in super-component's 3D space
#
# Object_Indirection.render adds content
#   renders vertexes that can't be produced by aggregating sub-components
#

class OI
  attr_reader :joins

  def initialize(symbol: "")
    @symbol = symbol

    @joins = Hash.new(){ |hash,key| hash[key] = {} }
   end


  # Add a sub-component to to this super-component
  #
  #  a_to_b:   compute sub-component inputs from super-component state / inputs
  #  b_render: compute/render sub-component content
  #  b_to_a:   compute super-component additions/modifications from sub-component content
  def add(symbol: "",
          computes: {
            a_to_b:   lambda {|a_input| b_input = a_input},
            b_render: lambda {|b_input| b_output = b_input},
            b_to_a:   lambda {|a_input, b_output| a_output = a_input}
          }
         )

    guid = [symbol,@joins.size]

    @joins[guid] = computes
  end

  # Render modified parent state (a)
  #  by rendering and aggregating all child lambda (b) into parent domain.
  #
  def render(**a_state_initial)

    # puts "render a_state_initial = #{a_state_initial}"

    new_a_state_final = @joins.each_pair.inject(a_state_initial) do |a_state_intermediate, join|
      join_symbol, join_computes = join

      a_input  = a_state_intermediate                            # a_state when we start this join

      # puts "render a_state_intermediate= #{a_state_intermediate}"
      # puts "render a_input             = #{a_input}"

      b_input  = join_computes[:a_to_b].call(a_input)            # b_inputs extracted from a_state
      b_output = join_computes[:b_render].call(b_input)          # b_output rendered by lambda
      a_state  = join_computes[:b_to_a].call(a_input, b_output)  # new a_state integrating b_ouput

      a_state
    end

    new_a_state_final
  end
end


require 'minitest/autorun'

class BugTest < Minitest::Test
end

