require './util/uniforms'
require './gl_ffi'
require './gpu_object.rb'


class Gpu

  def initialize_buffer_mapping

    # fixed parameters for each mesh data set
    @mesh_to_gpu_mapping_info = {
     # variable name: {}
      position: {vao_key: Gl::GL_ARRAY_BUFFER,         indicies: 3},
      normal:   {vao_key: Gl::GL_ARRAY_BUFFER,         indicies: 3},
      texcoord: {vao_key: Gl::GL_ARRAY_BUFFER,         indicies: 2},
      index:    {vao_key: Gl::GL_ELEMENT_ARRAY_BUFFER, indicies: 1},
    }
  end

  def bind_buffer_to_vao(gpu_graphic_object, content_type)
    # GL_ARRAY_BUFFER, GL_ELEMENT_ARRAY_BUFFER, etc.
    vao_key  = @mesh_to_gpu_mapping_info[content_type][:vao_key]
    gl_bfr_id = gpu_graphic_object.mesh_to_gpu_buffer_id_map[content_type] 

    Gl.glBindBuffer(vao_key, gl_bfr_id) 
  end

  ############### Routines to push buffers to GPU
  #

  # Input is triangle array = 
  # [
  #   [vertex0, vertex1, vertex2],
  #   [vertex0, vertex1, vertex2],
  # ]
  #
  # Output is packed data buffer for each vertex subcomponent =
  # {
  #   position: [x,y,z,x,y,z,...,x,y,z],
  #   normal:   [x,y,z,x,y,z,...,x,y,z],
  #   texcoord: [x,y,x,y,x,y...],
  #   index:    [0,1,2,3...]
  # }
  #
  def pack_triangles_into_gpu_buffer_format(triangles)

    vertex_array = []
    subcomponents    = Hash.new {|hash,key| hash[key] = Array.new}
    gl_ready_buffers = Hash.new {|hash,key| hash[key] = Array.new}

    # create single array of vertex from triangles
    #
    triangles.each do |triangle|
      triangle.vertex_array.each do |vertex|
        vertex_array << vertex
      end
    end

    # scatter the vertex into arrays for each vertex sub component
    #
    vertex_array.each_with_index do |vertex, index|
      subcomponents[:position] << vertex.position
      subcomponents[:normal]   << vertex.normal
      subcomponents[:texcoord] << vertex.texcoord
    end

    # subcomponent = content_type = vertex, normal, texcoord, index

    # pack data for each subcomponent to be ready for gpu
    #
    subcomponents.each_pair do |subcomponent, vector_array|
      content_config = @mesh_to_gpu_mapping_info[subcomponent]

      vao_key  = content_config[:vao_key] # GL_ARRAY_BUFFER, GL_ELEMENT_ARRAY_BUFFER, etc.
      indicies = content_config[:indicies]

      # make sure we don't get x,y,z,a if we only want x,y,z
      array_array = vector_array.map {|vec| vec.to_a.first(indicies)}

      # convert [[x,y,z], ..., [x,y,z]] into [x,y,z,x,y,z]
      element_array = array_array.flatten

      gl_ready_buffers[subcomponent] = element_array.pack("f*")
    end

    # create index buffer of form [0,1,2, ...]    (one entry per vertex)
    element_array = subcomponents[:position].each_index.map {|index| index}
    gl_ready_buffers[:index] = element_array.pack("L*")

    gl_ready_buffers 
  end

  # Push set of buffers out to the GPU
  #
  def write_mesh_data_to_gpu(gpu_graphic_object, gl_ready_buffers)

    # Vertex Array instance has pointers to the buffers were loading
    # Bind opengl context / gl functions to the vertex array instance
    Gl.glBindVertexArray(gpu_graphic_object.vertex_array_obj_id)

    gl_ready_buffers.each_pair do |subcomponent, packed_buffer|

      bind_buffer_to_vao(gpu_graphic_object, subcomponent)

      vao_key  = @mesh_to_gpu_mapping_info[subcomponent][:vao_key]

      Gl::glBufferData(vao_key, packed_buffer.size, packed_buffer, Gl::GL_DYNAMIC_DRAW) # Gl::GL_STATIC_DRAW
    end
  end

  ############### Routines to Map per vertex inputs to shader (attributes) to gpu buffers
  #
  def configure_enable_attribute(program_id, _attr_name, element_size=3)
    attr_name = _attr_name.to_s

    attr_location = Gl.getAttribLocation(program_id, attr_name)

    if attr_location >= 0 then
      Gl.vertexAttribPointer(attr_location, element_size, GL_FLOAT, 0, 0, 0)
      Gl.enableVertexAttribArray(attr_location)
    end
  end

  def map_attribute_to_buffer(go, program_id, attr_name, element_size=3)

    # Bind VAO to gpu context
    # /todo don't do this if already done
    Gl.glBindVertexArray(go.vertex_array_obj_id)

    # Bind the buffer with the vertex locations (x,y,z) to the VAO
    # and map attribute to the buffer
    bind_buffer_to_vao(go, attr_name)

    configure_enable_attribute(program_id, attr_name, element_size)
  end


  ############### 
  # Main routine in this file
  # Turn the cpu graphic object into gpu data
  #

  def push_cpu_graphic_object(program_id, cpu_graphic_object, gpu_object_id = -1)
    # vertex_array_obj_id = gpu_object_id

    if gpu_object_id < 0
      gpu_graphic_object = GPU_Graphic_Object.new()
      gpu_object_id = gpu_graphic_object.vertex_array_obj_id
      @gpu_graphic_objects[gpu_object_id] = gpu_graphic_object
    end

    gpu_graphic_object = @gpu_graphic_objects[gpu_object_id]
    gpu_graphic_object.program_id = program_id

    # Render the object in object space
    cpu_graphic_object.internal()

    # Position the object in world space
    #cpu_graphic_object.external()
    
    ##### Uniforms
    #
    gpu_graphic_object.model_matrix = cpu_graphic_object.model_matrix
    gpu_graphic_object.color        = cpu_graphic_object.color

    # Setup a matrix to rotate normals from object space to world space 
    # gpu_graphic_object.model_matrix_for_normals = gpu_graphic_object.model_matrix.remove_translation_component
    
    matrix            = gpu_graphic_object.model_matrix.dup
    inverse           = matrix.inverse
    inverse_transpose = inverse.transpose
    gpu_graphic_object.model_matrix_for_normals = inverse_transpose


    gpu_graphic_object.mesh         = cpu_graphic_object.mesh

    # Establish set of buffers that are ready to go into GPU
    gl_ready_buffers = pack_triangles_into_gpu_buffer_format(gpu_graphic_object.mesh.triangles)

    # Push the data buffers to the GPU
    write_mesh_data_to_gpu(gpu_graphic_object, gl_ready_buffers)

    # Map per vertex inputs to shader (attributes) to gpu buffers
    map_attribute_to_buffer(gpu_graphic_object, program_id, :position)
    map_attribute_to_buffer(gpu_graphic_object, program_id, :normal)
    map_attribute_to_buffer(gpu_graphic_object, program_id, :texcoord, 2)

    #map_attribute_to_buffer(gpu_graphic_object, program_id, :index, 1)
    
    # Number of elements to render 
    # So far, each index is unique so #elements = #index
    # /todo reuse index if position, normal and texcoord are the same
    gpu_graphic_object.element_count = gl_ready_buffers[:index].size

    gpu_object_id
  end



end
 
