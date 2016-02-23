require "./gl_ffi"
require "geo3d"
require './util/geo3d_vector.rb'


class GPU_Graphic_Object
  attr_accessor :mesh, :vertex_array_obj_id, :element_count, :mesh_to_gpu_buffer_id_map, :program_id, :uniform_variables

  def initialize()
    @vertex_array_obj_id = Gl.genVertexArray

    # Retrieve or allocate gl bfr id for this data type
    @mesh_to_gpu_buffer_id_map = Hash.new(){ |hash,key| hash[key] = Gl.genBuffer() }

    @element_count  = 0  # number of elements (vertex) to render

    @program_id = 0

    @uniform_variables = Hash.new(){|hash,key| hash[key] = {} }
  end


  def model_matrix_for_normals=(_matrix = Geo3d::Matrix.identity)
    @uniform_variables[:model_matrix_for_normals] = {data: _matrix}
  end

  def model_matrix_for_normals
    @uniform_variables[:model_matrix_for_normals][:data]
  end


  def model_matrix=(_matrix = Geo3d::Matrix.identity)
    @uniform_variables[:model] = {data: _matrix}
  end

  def model_matrix
    @uniform_variables[:model][:data]
  end

  def color=(_color = Geo3d::Vector.new(0.0, 0.0, 0.0, 1.0))
    @uniform_variables[:surface_color] = {data: _color}
  end

  def color
    @uniform_variables[:model][:surface_color]
  end
end
