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
# Aggregate.render aggregates sub-components
#   renders sub-components to generate sub-component vertex arrays
#   translate, rotate and scales sub components vertexes to the correct place in super-component's 3D space
#
# Aggregate.render adds content
#   renders vertexes that can't be produced by aggregating sub-components
#

class Aggregate
  attr_reader :joins

  def initialize(symbol: '')
    @symbol = symbol

    @joins = Hash.new { |hash, key| hash[key] = {} }
  end

  # Add a sub-component to to this super-component
  #
  # Embedded Subcomponent(s)
  #
  #  sub_ctx_ingress:   lambda to compute embedded sub-component inputs from super-component state / inputs
  #                       (lambda returns inputs to be used when rendering recursive sub-component(s) / layer(s) )
  #
  #  sub_ctx_render:    lambda to render sub-component content
  #                       (lambda returns outputs from rendering recursive sub-component(s) / layer(s))
  #
  #  sub_ctx_egress:    lambda to compute super-component additions/modifications from sub-component content
  #
  #  /todo clarify and document
  #
  def add(**args)
    defaults = {
      symbol: '',
      computes: {
        sub_ctx_ingress: ->(sup_ctx_in) { sub_ctx_in = sup_ctx_in }, # Default: pass untransformed super context to sub context
        sub_ctx_render: ->(sub_ctx_in) { sub_ctx_out = sub_ctx_in }, # Default:
        sub_ctx_egress: ->(sup_ctx_in, sub_ctx_out) {
          # Output joins input gpu_objs (super context) with rendered gpu_objects (sub_context)
          sup_ctx_out = Aggregate.std_join_ctx(sup_ctx_in, sub_ctx_out)
          return sup_ctx_out
        }
      }
    }

    args = defaults.merge(args)
    args[:computes] = defaults[:computes].merge(args.fetch(:computes, {})) # merge internal hash

    guid = [args[:symbol], @joins.size]

    @joins[guid] = args[:computes]
  end

  # Render modified parent state (sup_ctx)
  #  by rendering and aggregating all child lambda (sub_ctx) into parent domain.
  #
  def render(**sup_ctx_initial)
    # puts "render sup_ctx_in = #{sup_ctx_in}"

    # Render meshes for each sub object
    #
    sup_ctx_final = @joins.each_pair.inject(sup_ctx_initial) do |sup_ctx_in, join|
      join_symbol, sub_computes = join

      # Compute the input sub context from the input super context
      #   The sub context knows what information it needs from the super
      #   context and extracts it here.
      #
      sub_ctx_in  = sub_computes[:sub_ctx_ingress].call(sup_ctx_in) # sub_ctx_ins extracted from a_state

      # Do the compute to render the meshes from the sub object
      sub_ctx_out = sub_computes[:sub_ctx_render].call(sub_ctx_in) # sub_ctx_out rendered by lambda
      sup_ctx_out = sub_computes[:sub_ctx_egress].call(sup_ctx_in, sub_ctx_out) # new a_state integrating b_ouput

      # Return super context
      sup_ctx_out
    end

    # We have an array with one element per sub context we rendered.
    sup_ctx_final
  end
end

require 'minitest/autorun'

class BugTest < Minitest::Test
end
