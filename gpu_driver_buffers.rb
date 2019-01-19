require './util/uniforms'
require './util/Assert'
require './util/debug'
require './gl_ffi'
require './gpu_object'
require './cpu_graphic_object'

class Gpu
  def initialize_buffer_mapping
    # fixed parameters for each mesh data set
    @gpu_param_mapping_info = {
      # variable name: {}
      position: { vao_key: Gl::GL_ARRAY_BUFFER, indicies: 3 },
      normal: { vao_key: Gl::GL_ARRAY_BUFFER, indicies: 3 },
      texcoord: { vao_key: Gl::GL_ARRAY_BUFFER,         indicies: 2 },
      index: { vao_key: Gl::GL_ELEMENT_ARRAY_BUFFER, indicies: 1 }
    }
  end

  def bind_buffer_to_vao(gpu_mesh_job, content_type)
    # GL_ARRAY_BUFFER, GL_ELEMENT_ARRAY_BUFFER, etc.
    vao_key = @gpu_param_mapping_info[content_type][:vao_key]
    gl_bfr_id = gpu_mesh_job.mesh_to_gpu_buffer_id_map[content_type]

    assert { gl_bfr_id > 0 }

    Gl.glBindBuffer(vao_key, gl_bfr_id)
  end

  def unbind_buffer_to_vao(gpu_mesh_job, content_type)
    # GL_ARRAY_BUFFER, GL_ELEMENT_ARRAY_BUFFER, etc.

    gpu_mapping_info = @gpu_param_mapping_info[content_type]
    vao_key = gpu_mapping_info[:vao_key]

    gl_bfr_id = gpu_mesh_job.mesh_to_gpu_buffer_id_map[content_type]
    assert { gl_bfr_id > 0 }

    Gl.glBindBuffer(vao_key, 0)
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
  def scatter_triangles_into_packed_subcomponent_buffers(triangles)
    vertex_array = []
    subcomponents    = Hash.new { |hash, key| hash[key] = [] }
    gl_ready_buffers = Hash.new { |hash, key| hash[key] = [] }

    # create single array of vertex from triangles
    #
    triangles.each do |triangle|
      triangle.vertex_array.each do |vertex|
        vertex_array << vertex
      end
    end

    # scatter the vertex into arrays for each vertex sub component
    #
    vertex_array.each_with_index do |vertex, _index|
      subcomponents[:position] << vertex.position
      subcomponents[:normal]   << vertex.normal
      subcomponents[:texcoord] << vertex.texcoord
    end

    # subcomponent = content_type = vertex, normal, texcoord, index

    # pack data for each subcomponent to be ready for gpu
    #
    subcomponents.each_pair do |subcomponent, vector_array|
      content_config = @gpu_param_mapping_info[subcomponent]

      vao_key  = content_config[:vao_key] # GL_ARRAY_BUFFER, GL_ELEMENT_ARRAY_BUFFER, etc.
      indicies = content_config[:indicies]

      # make sure we don't get x,y,z,a if we only want x,y,z
      array_array = vector_array.map { |vec| vec.to_a.first(indicies) }

      # convert [[x,y,z], ..., [x,y,z]] into [x,y,z,x,y,z]
      element_array = array_array.flatten

      gl_ready_buffers[subcomponent] = element_array.pack('f*')
    end

    # create index buffer of form [0,1,2, ...]    (one entry per vertex)
    element_array = subcomponents[:position].each_index.map { |index| index }
    gl_ready_buffers[:index] = element_array.pack('L*')

    gl_ready_buffers
  end

  # Push set of buffers out to the GPU
  #
  def write_mesh_data_to_gpu(gpu_mesh_job, gl_ready_buffers)
    assert { gpu_mesh_job.vertex_array_obj_id > 0 }

    # Vertex Array instance has pointers to the buffers were loading
    # Bind opengl context / gl functions to the vertex array instance
    Gl.glBindVertexArray(gpu_mesh_job.vertex_array_obj_id)

    check_for_gl_error

    gl_ready_buffers.each_pair do |subcomponent, packed_buffer|
      bind_buffer_to_vao(gpu_mesh_job, subcomponent)

      gl_bfr_id = gpu_mesh_job.mesh_to_gpu_buffer_id_map[subcomponent]

      check_for_gl_error

      vao_key = @gpu_param_mapping_info[subcomponent][:vao_key]

      # Gl::glBufferData(vao_key, packed_buffer.size, packed_buffer, Gl::GL_DYNAMIC_DRAW) # Gl::GL_STATIC_DRAW

      Gl.bufferData(vao_key, packed_buffer.size, packed_buffer, Gl::GL_STATIC_DRAW) # Gl::GL_STATIC_DRAW

      check_for_gl_error

      # TODO: why does following cause nothing to be displayed?
      # unbind_buffer_to_vao(gpu_mesh_job, subcomponent)

      check_for_gl_error
    end
  end

  ############### Routines to Map per vertex inputs to shader (attributes) to gpu buffers
  #
  def map_attribute_to_buffer(gpu_mesh_job, attr_name, element_size = 3)
    assert { gpu_mesh_job.vertex_array_obj_id > 0 }

    # Bind VAO to gpu context
    # /todo don't do this if already done
    Gl.glBindVertexArray(gpu_mesh_job.vertex_array_obj_id)

    # Bind the buffer with the vertex locations (x,y,z) to the VAO
    # and map attribute to the buffer
    bind_buffer_to_vao(gpu_mesh_job, attr_name)

    # attr_location = Gl.getAttribLocation(gpu_mesh_job.gl_program_id, attr_name.to_s)
    attr_location = get_attribute_location(gpu_mesh_job.gl_program_id, attr_name)

    if attr_location >= 0
      # Note: Attribute --actually used-- in shader code if attr_location >= 0
      #
      Gl.vertexAttribPointer(attr_location, element_size, GL_FLOAT, 0, 0, 0)
      Gl.enableVertexAttribArray(attr_location)
    end

    unbind_buffer_to_vao(gpu_mesh_job, attr_name)
  end

  ###############
  # Main routine in this file
  # Turn the cpu graphic object into gpu data
  #

  def push_mesh_job_to_gpu(gpu_mesh_job)
    # Setup a matrix to rotate normals from object space to world space
    # gpu_mesh_job.model_matrix_for_normals = gpu_mesh_job.model_matrix.remove_translation_component

    matrix            = gpu_mesh_job.model_matrix.dup
    inverse           = matrix.inverse
    inverse_transpose = inverse.transpose
    gpu_mesh_job.model_matrix_for_normals = inverse_transpose

    # Establish set of buffers that are ready to go into GPU
    gl_ready_buffers = scatter_triangles_into_packed_subcomponent_buffers(gpu_mesh_job.mesh.triangles)

    check_for_gl_error

    # Push the data buffers to the GPU
    write_mesh_data_to_gpu(gpu_mesh_job, gl_ready_buffers)

    check_for_gl_error

    # Map per vertex inputs to shader (attributes) to gpu buffers
    map_attribute_to_buffer(gpu_mesh_job, :position)
    map_attribute_to_buffer(gpu_mesh_job, :normal)
    map_attribute_to_buffer(gpu_mesh_job, :texcoord, 2)

    check_for_gl_error

    # map_attribute_to_buffer(gpu_mesh_job, gl_program_id, :index, 1)

    # Number of elements to render
    # So far, each index is unique so #elements = #index
    # /todo reuse index if position, normal and texcoord are the same
    gpu_mesh_job.element_count = gl_ready_buffers[:index].size

    gpu_mesh_job
  end
end
