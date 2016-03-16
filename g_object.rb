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

class Object_Indirection
  attr_reader :computes

  def initialize(name: "")
    @name = name
    @generated_id_last = 0
    @aggregations = Hash.new(){ |hash,key| hash[key] = {} }
    @computes = Hash.new(){ |hash,key| hash[key] = {} }
  end

  def generate_id(name)
    id = @generated_id_last
    @generated_id_last += 1

    name + id.to_s
  end

  def add_compute(name: "", compute: lambda {}, inputs: {} )
    @computes[generate_id(name)] = {compute: compute, inputs: inputs}
  end


  def Object_Indirection.add_computed_sub_object
    lambda {|input|

      oi = input.fetch(:object_indirection, nil)

      # Render sub object 
      computed_sub_object = oi.nil? ? nil : oi.render_object(inputs: input[:inputs])

      trs_matrix_array = input.fetch(:trs_matrixes, [])

      # Apply trs_matrixes to translate vertexes from sub-component space to super-component (this) space
      trs_matrix_array.each {|matrix| 
        puts "matrix = #{matrix.to_s}"
        computed_sub_object.applyMatrix!(matrix) 
      }


      computed_sub_object
    }
  end


  def Object_Indirection.add_component_lambda
    lambda {|input|

      oi = input.fetch(:object_indirection, nil)

      # Generate output from sub-component
      #
      vertex_array_in_sub_space = oi.render(inputs: input[:inputs]) unless oi.nil?

      # Apply trs_matrixes to translate vertexes from sub-component space to super-component (this) space
      #
      trs_matrix_array = input.fetch(:trs_matrixes, [])

      vertex_array_in_super_space = 
        trs_matrix_array.inject(vertex_array_in_sub_space) do |vertex_array, trs_matrix|

        # translate, rotate, scale vertex into new "space"
        vertex_array = vertex_array.map do |vertex|
          vertex.position.w = 1.0
          vertex.position = trs_matrix * vertex.position
          vertex
        end

        vertex_array
        end

      vertex_array_in_super_space
    }
  end

  def add_component(name: "", object_indirection: nil, trs_matrixes: [], inputs: {})

    lambda_inputs = {
      object_indirection: object_indirection,
      trs_matrixes: trs_matrixes,
      inputs: inputs
    }
    
    add_compute(name: name, compute: Object_Indirection.add_component_lambda, inputs: lambda_inputs)
  end



  def render_object(inputs: [])

    # Gather output from this object that can't be produced by agregating
    #   sub-component output
    computed_sub_objects = @computes.map do |name, l|
      l[:compute].call(l[:inputs])
    end

    merge_graphic_objects(computed_sub_objects)
  end


  def render(inputs: [])

    # Gather output from this object that can't be produced by agregating
    #   sub-component output
    computed_mesh_array = @computes.map do |name, l|
      l[:compute].call(l[:inputs])
    end

    #puts "render #{@name}"
    #puts "sub_component_output_array = #{sub_component_output_array}"
    #puts "lambda_output_array        = #{lambda_output_array}"

    (computed_mesh_array).flatten
  end

end

require 'minitest/autorun'

class BugTest < Minitest::Test
  def test_single_object
  end

  def test_layered_object_with_trs_matrix
    oi_1 = Object_Indirection.new(name: "oi_1")

    oi_1_1 = Object_Indirection.new(name: "oi_1_1")
    oi_1_2 = Object_Indirection.new(name: "oi_1_2")

    # Directly generate vertex for this object
    oi_1_1.add_compute(name: "o_1_1", compute: lambda{|input| 
                                                     Vertex.new(Geo3d::Vector.new(0,1,2))})

    # Directly generate vertex for this object
    oi_1_2.add_compute(name: "o_1_2", compute: lambda{|input| 
                                                      Vertex.new(Geo3d::Vector.new(3,4,5))})


    # Composite sub-components
    oi_1.add_compute(name: "sub1", 
                     compute: Object_Indirection.add_component_lambda, 
                     inputs: {trs_matrixes: [Geo3d::Matrix.translation(1,2,3)], object_indirection: oi_1_1}
                    )

    # Composite sub-components
    oi_1.add_component(name: "sub2", object_indirection: oi_1_2)


    out = oi_1.render()

    expected = [
      Vertex.new(Geo3d::Vector.new(1,3,5, 1.0)),  # w set at end
      Vertex.new(Geo3d::Vector.new(3,4,5))        # we don't translate this one
    ]

    assert_equal expected.map{|a| a.to_hash}, out.map{|a| a.to_hash}
  end


  def test_layered_object
    oi_1 = Object_Indirection.new(name: "oi_1")

    oi_1_1 = Object_Indirection.new(name: "oi_1_1")
    oi_1_1.add_compute(name: "o_1_1", compute: lambda{|input| 
                                                     Vertex.new(Geo3d::Vector.new(0,1,2))})

    oi_1_2 = Object_Indirection.new(name: "oi_1_2")
    oi_1_2.add_compute(name: "o_1_2", compute: lambda{|input| 
                                                      Vertex.new(Geo3d::Vector.new(3,4,5))})

    oi_1.add_component(name: "sub1", object_indirection: oi_1_1)
    oi_1.add_component(name: "sub2", object_indirection: oi_1_2)

    out = oi_1.render()

    expected = [
      Vertex.new(Geo3d::Vector.new(0,1,2)),
      Vertex.new(Geo3d::Vector.new(3,4,5))
    ]

    assert_equal expected.map{|a| a.to_hash}, out.map{|a| a.to_hash}
  end
end


