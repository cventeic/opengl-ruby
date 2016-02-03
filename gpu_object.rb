require "./gl_ffi"


class GPU_Graphic_Object
  attr_accessor :mesh, :vertex_array_obj_id, :index_count

  def initialize()
    @vertex_array_obj_id = Gl.genVertexArray

    # fixed parameters for each mesh data set
    @mesh_to_gpu_mapping_info = {
      vertex:   {vao_key: Gl::GL_ARRAY_BUFFER,         indicies: 3},
      normal:   {vao_key: Gl::GL_ARRAY_BUFFER,         indicies: 3},
      texcoord: {vao_key: Gl::GL_ARRAY_BUFFER,         indicies: 2},
      index:    {vao_key: Gl::GL_ELEMENT_ARRAY_BUFFER, indicies: 1},
    }

    # Retrieve or allocate gl bfr id for this data type
    @mesh_to_gpu_buffer_id_map = Hash.new(){ |hash,key| hash[key] = Gl.genBuffer() }

    @index_count  = 0

  end

  # /todo we shouldn't need to pass vao_key
  def format_data_for_gl(arrays, indicies, vao_key)
    floats = Array.new

    arrays.each do |a|
      next if a.nil?
      next if a.size < indicies
      a.to_a.first(indicies).each do |aa|
        floats << aa
      end
    end

    #format = self.target == Gl::GL_ELEMENT_ARRAY_BUFFER ? "L*" : "f*"
    format = vao_key == Gl::GL_ELEMENT_ARRAY_BUFFER ? "L*" : "f*"

    return if floats.nil? || floats.size == 0
    data = floats.pack(format)
  end


  def bind_buffer_to_vao(content_type)
    # GL_ARRAY_BUFFER, GL_ELEMENT_ARRAY_BUFFER, etc.
    vao_key  = @mesh_to_gpu_mapping_info[content_type][:vao_key]
    gl_bfr_id = @mesh_to_gpu_buffer_id_map[content_type] 

    Gl.glBindBuffer(vao_key, gl_bfr_id) 
  end

  def write_mesh_data_to_gpu()

    # Vertex Array instance has pointers to the buffers were loading
    # Bind opengl context / gl functions to the vertex array instance
    Gl.glBindVertexArray(@vertex_array_obj_id)

    # content_type = vertex, normal, texcoord, index
    @mesh_to_gpu_mapping_info.each_pair do |content_type, content_config|

      vao_key  = content_config[:vao_key] # GL_ARRAY_BUFFER, GL_ELEMENT_ARRAY_BUFFER, etc.
      indicies = content_config[:indicies]

      gl_bfr_id = @mesh_to_gpu_buffer_id_map[content_type] 
      
      mesh_data_set = @mesh.data_sets[content_type]

      Gl.glBindBuffer(vao_key, gl_bfr_id)

      gl_data_set = format_data_for_gl(mesh_data_set, indicies, vao_key)

      Gl::glBufferData(vao_key, gl_data_set.size, gl_data_set, Gl::GL_DYNAMIC_DRAW) # Gl::GL_STATIC_DRAW
    end

    @index_count= @mesh.data_sets[:index].size
  end
end
