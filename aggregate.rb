require './mesh'
require 'geo3d'
require './util/geo3d_matrix.rb'
require 'ostruct'
require './cpu_graphic_object'

# Aggregate encapsulates the builder for an independent object
#
# Aggregation differes from composition in that aggregation does not imply ownership
#
# Aggregate.render outputs a vertex array of vertexes in that object's 3D space
#
# Aggregate.render
#   renders elements to produce element vertex arrays
#   translate, rotate and scales element vertexes to the correct placement in aggregate's 3D space
#   returns collection of vertex arrays required to render aggregate graphical object
#

class Aggregate
  attr_reader :elements

  def initialize(symbol: '')
    @symbol = symbol

    @elements = Hash.new { |hash, key| hash[key] = {} }
  end

  # Add element to the aggregate
  #
  # elements can be aggregates or actual meshes
  #
  # Element lambdas:
  #  element_ingress:   lambda to extract element input from aggregate's common data structure
  #
  #  element_render:    lambda to render element to array of gpu_objects (vertex_array, color, etc)
  #
  #  element_egress:    lambda to modify aggregate's common data structure to store result of rendering element
  #
  #  /todo clarify and document
  #
  def add_element(**args)
    defaults = {
      symbol: '',
      computes: {
        element_ingress: ->(aggregate_data_in) { element_in = aggregate_data_in }, # Default: pass untransformed super context to sub context
        element_render: ->(element_in) { element_out = element_in }, # Default:
        element_egress: ->(aggregate_data_in, element_out) {
          # Output aggregates input gpu_objs (super context) with rendered gpu_objects (sub_context)
          aggregate_data_out = Aggregate.std_aggregate_ctx(aggregate_data_in, element_out)
          return aggregate_data_out
        }
      }
    }

    args = defaults.merge(args)
    args[:computes] = defaults[:computes].merge(args.fetch(:computes, {})) # merge internal hash

    guid = [args[:symbol], @elements.size]

    @elements[guid] = args[:computes]
  end

  # Render modified parent state (sup_ctx)
  #  by rendering and aggregating all child lambda (sub_ctx) into parent domain.
  #
  def render(**aggregate_data_initial)
    # puts "render aggregate_data_in = #{aggregate_data_in}"

    # Render meshes for each sub object
    #
    aggregate_data_final = @elements.each_pair.inject(aggregate_data_initial) do |aggregate_data_in, element|
      element_symbol, sub_computes = element

      # Compute the input sub context from the input super context
      #   The sub context knows what information it needs from the super
      #   context and extracts it here.
      #
      element_in  = sub_computes[:element_ingress].call(aggregate_data_in) # element_ins extracted from a_state

      # Do the compute to render the meshes from the sub object
      element_out = sub_computes[:element_render].call(element_in) # element_out rendered by lambda
      aggregate_data_out = sub_computes[:element_egress].call(aggregate_data_in, element_out) # new a_state integrating b_ouput

      # Return super context
      aggregate_data_out
    end

    # We have an array with one element per sub context we rendered.
    aggregate_data_final
  end
end

require 'minitest/autorun'

class BugTest < Minitest::Test
end
