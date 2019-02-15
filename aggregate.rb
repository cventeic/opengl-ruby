require './mesh'
require 'geo3d'
require './util/geo3d_matrix.rb'
require 'ostruct'
require './cpu_graphic_object'

# Aggregate encapsulates the builder for an independent graphical object
#
# Aggregation differes from composition in that aggregation does not imply ownership of elements
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
  #
  # Element lambdas:
  #  element_ingress: lambda to extract element input hash from aggregate's intermediate hash
  #
  #  element_render:  lambda to render element to hash containing array of gpu_objects (vertex_array, color, etc)
  #
  #  element_egress:  lambda to add rendered output to the aggregate_intermediate hash
  #
  #  /todo clarify and document
  #
  def add_element(**args)
    defaults = {
      symbol: '',
      lambdas: {
        # Default ingress lambda extracts and exposes entire aggregate intermediate hash as element input
        element_ingress: ->(aggregate_intermediate_hash) { element_input_hash = aggregate_intermediate_hash},

        # Default render lambda returns hash containing empty array of gpu_objs
        element_render: ->(element_input_hash) {element_output_hash = {gpu_objs: []}},

        # Default egress lambda adds rendered :gpu_objs to :gpu_objs array in aggregate intermediate hash
        element_egress: ->(aggregate_intermediate_hash, element_output_hash) {
          aggregate_intermediate_hash = Aggregate.std_aggregate_ctx(aggregate_intermediate_hash, element_output_hash)
          return aggregate_intermediate_hash
        }
      }
    }

    args = defaults.merge(args)
    args[:lambdas] = defaults[:lambdas].merge(args.fetch(:lambdas, {})) # merge internal hash

    guid = [args[:symbol], @elements.size]

    @elements[guid] = args[:lambdas]
  end

  # Render aggregate object by rendering all elements of the object.
  #
  #  aggregate_input_hash is contains key,value pairs that may be relevant to elements
  #
  #  Render creates an aggregate_intermediate hash from the aggregate_input_hash
  #
  #  All elements can extract inputs from the aggregate_intermediate_hash and
  #  all elements add rendered output to the aggregate_intermediate_hash.
  #
  #  returns a hash of the form {xxx: yyy, gpu_objs: [aaa,bbb]}
  #  where gpu_objs contain all the meshes and surfaces needed to render the aggregate object
  #
  def render(**aggregate_input_hash)
    # Render meshes for each element
    #
    aggregate_output_hash = @elements.each_pair.inject(aggregate_input_hash) do |aggregate_intermediate_hash, element|
      element_symbol, lambdas = element

      # Compute the input sub context from the input super context
      #   The sub context knows what information it needs from the super
      #   context and extracts it here.
      #
      element_in  = lambdas[:element_ingress].call(aggregate_intermediate_hash) # element_ins extracted from a_state

      # Do the compute to render the meshes from the sub object
      element_out = lambdas[:element_render].call(element_in) # element_out rendered by lambda

      aggregate_intermediate_hash = lambdas[:element_egress].call(aggregate_intermediate_hash, element_out) # new a_state integrating b_ouput

      aggregate_intermediate_hash
    end

    # In the future we may to remove intermediate garbage from aggregate_output_hash

    aggregate_output_hash
  end
end

require 'minitest/autorun'

class BugTest < Minitest::Test
end
