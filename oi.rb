require './mesh'
require 'geo3d'
require './util/geo3d_matrix.rb'
require 'ostruct'
require './cpu_graphic_object'


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

  def to_cpu_graphic_objects()
  end

  def to_cpu_graphic_object()
    # puts "\n #{__method__.to_s} enter"

    cpu_graphic_object = Cpu_Graphic_Object.new(
      internal_proc: lambda { |named_arguments|
        render_state = self.render
        mesh = render_state[:mesh]
        named_arguments[:mesh] = mesh
      },
      external_proc: lambda { |named_arguments| },
      model_matrix: (Geo3d::Matrix.identity()),
      color: Geo3d::Vector.new( 0.0, 0.0, 1.0, 1.0)
    )

    # puts "\n #{__method__.to_s} exit"

    return cpu_graphic_object
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
    def add( symbol: "",
             computes: {
               sub_ctx_ingress: lambda {|sup_ctx_in|               sub_ctx_in = sup_ctx_in}, # Default: pass untransformed super context to sub context
               sub_ctx_render:  lambda {|sub_ctx_in|              sub_ctx_out = sub_ctx_in}, # Default:
               sub_ctx_egress:  lambda {|sup_ctx_in, sub_ctx_out| sup_ctx_out = sup_ctx_in}  # Default: don't transform super context
             }
         )

    guid = [symbol,@joins.size]

    @joins[guid] = computes
  end

  # Render modified parent state (sup_ctx)
  #  by rendering and aggregating all child lambda (sub_ctx) into parent domain.
  #
  def render(**sup_ctx_initial)

    # puts "render sup_ctx_in = #{sup_ctx_in}"

    sup_ctx_final = @joins.each_pair.inject(sup_ctx_initial) do |sup_ctx_in, join|

      join_symbol, join_computes = join

      sub_ctx_in  = join_computes[:sub_ctx_ingress].call(sup_ctx_in)            # sub_ctx_ins extracted from a_state
      sub_ctx_out = join_computes[:sub_ctx_render].call(sub_ctx_in)          # sub_ctx_out rendered by lambda
      sup_ctx_out = join_computes[:sub_ctx_egress].call(sup_ctx_in, sub_ctx_out)  # new a_state integrating b_ouput

      # Return super context
      sup_ctx_out
    end

   sup_ctx_final
  end
end


require 'minitest/autorun'

class BugTest < Minitest::Test
end

