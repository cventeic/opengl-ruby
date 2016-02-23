require "./gl_ffi"


class GPU_Graphic_Object
  attr_accessor :mesh, :vertex_array_obj_id, :element_count, :mesh_to_gpu_buffer_id_map, :program_id, :model_matrix, :color

  def initialize()
    @vertex_array_obj_id = Gl.genVertexArray

    # Retrieve or allocate gl bfr id for this data type
    @mesh_to_gpu_buffer_id_map = Hash.new(){ |hash,key| hash[key] = Gl.genBuffer() }

    @element_count  = 0  # number of elements (vertex) to render

    @program_id = 0

    @model_matrix = nil

    @color = nil

  end
end
