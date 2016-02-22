require './util/uniforms'
require './gl_ffi'
require './gpu_object.rb'

module Geo3d
  class Matrix
    def remove_translation_component()
      m = self.dup
      m._41 = m._42 = m._43 = 0.0
      m 
    end

    def to_s_round(digits=2)
      (0..3).to_a.map { |i| 
        row(i).to_s_round(digits)
      }.join "\n"
    end
  end

  class Vector
    def to_s_round(digits=2)
      to_a.compact.map{|i| i.round(digits)}.map {|v| sprintf("% #.2f", v)}.join(' ')
    end
  end

end
 

class Gpu
  def initialize
    @uniformsLocationCache = Uniforms_Location_Cache.new()

    @gpu_graphic_objects = Hash.new

    # fixed parameters for each mesh data set
    @mesh_to_gpu_mapping_info = {
      position: {vao_key: Gl::GL_ARRAY_BUFFER,         indicies: 3},
      normal:   {vao_key: Gl::GL_ARRAY_BUFFER,         indicies: 3},
      texcoord: {vao_key: Gl::GL_ARRAY_BUFFER,         indicies: 2},
      index:    {vao_key: Gl::GL_ELEMENT_ARRAY_BUFFER, indicies: 1},
    }

  end


  # compile and push shader to gpu
  #
  # todo raise info if compile fails
  #
  def push_shader(shader_type, shader_source_code)
    shader_id = Gl.glCreateShader(shader_type)

    sources = [shader_source_code] unless sources.kind_of?(Array)
    source_lengths = sources.map { |s| s.bytesize }.pack('i*')
    source_pointers = sources.pack('p')

    Gl.shaderSource(shader_id, sources.length, source_pointers, source_lengths)

    Gl.compileShader(shader_id)

    shader_id
  end

  def update_camera_view(program_id, camera)

    set_uniform_matrix(program_id, :view, camera.view)

    set_uniform_matrix(program_id, :projection, camera.perspective)


    vec_camera_location_camera_space = Geo3d::Vector.new(0.0, 0.0, 0.0, 1.0)

    matrix_view_inverse = camera.view.inverse

    vec_camera_location_in_world_space = matrix_view_inverse * vec_camera_location_camera_space

=begin
    puts
    puts
    puts "camera_view = "
    puts camera.view.to_s_round
    puts
    puts "camera_view.inverse = "
    puts matrix_view_inverse.to_s_round

    # puts "camera_location_world = #{camera_location_world.to_s}"
    puts "camera location world = #{vec_camera_location_in_world_space.to_s_round}"
=end

    #set_uniform_vector(program_id, :vEyePosition, camera_location_world)
    set_uniform_vector(program_id, :vEyePosition, vec_camera_location_in_world_space)

    error = Gl.getError()
    puts "Error: update_camera_view,  glError = #{error}" unless error == 0
 
  end

  def update_lights(program_id)

    uniforms_vec3 = {
#      'viewPos'           => [0.0, 0.0, 0.0],
       'light.position'    => [0.0, 0.0, 10.0],    # in world space
#      'light.direction'   => [0.0, 0.0, -1.0],    # spotlight
#      'light.ambient'     => [0.4, 0.4, 0.4],
#      'light.diffuse'     => [0.8, 0.8, 0.8],
#      'light.specular'    => [1.0, 1.0, 1.0]
    }

    uniforms_1 = {
      #'material.diffuse'  => 0,
      #'material.specular' => 1,

      #'material.shininess'=> 32.0,

      #'light.cutOff'      => Math.cos(radians(12.5)), # spotlight
      #'light.outerCutOff' => Math.cos(radians(17.5)), # spotlight

      #'light.constant'    => 1.0,
      #'light.constant'    => 0.0,
      #'light.linear'      => 0.09,
      #'light.quadratic'   => 0.032,
    }

      
    set_uniforms_vec3(program_id, uniforms_vec3)
    set_uniforms_1(program_id, uniforms_1)
  end


  # /todo don't due these time intensive yet static things every render
  #   - compute and set mNormal
  #   - set model_matrix
  #   - set color

  def set_object_uniforms(gpu_graphic_object)

    # Setup a matrix to rotate normals from object space to world space 
    model_matrix_for_normals = gpu_graphic_object.model_matrix.remove_translation_component

=begin
    puts
    puts
    puts "model_matrix = "
    puts gpu_graphic_object.model_matrix.to_s_round
    puts
    puts "model_matrix_for_normals = "
    puts model_matrix_for_normals.to_s_round
=end

    
    set_uniform_matrix(gpu_graphic_object.program_id, "model_matrix_for_normals", model_matrix_for_normals)

    set_uniform_matrix(gpu_graphic_object.program_id, :model, gpu_graphic_object.model_matrix)

    set_uniform_vector(gpu_graphic_object.program_id, :surface_color, gpu_graphic_object.color)
  end


  def render_object(gpu_object_id)
    vertex_array_obj_id = gpu_object_id
    
    gpu_graphic_object = @gpu_graphic_objects[gpu_object_id]

    # Bind VAO to gpu context
    Gl.glBindVertexArray(vertex_array_obj_id)

    # todo dont do this unless something changed
    set_object_uniforms(gpu_graphic_object)

    Gl.drawElements(Gl::GL_TRIANGLES, gpu_graphic_object.index_count, Gl::GL_UNSIGNED_INT, 0)
  end

  def map_attribute_to_buffer(program_id, _attr_name, element_size=3)
    attr_name = _attr_name.to_s

    attr_location = Gl.getAttribLocation(program_id, attr_name)

    if attr_location >= 0 then
      Gl.vertexAttribPointer(attr_location, element_size, GL_FLOAT, 0, 0, 0)
      Gl.enableVertexAttribArray(attr_location)
    end
  end

  def bind_buffer_to_vao(gpu_graphic_object, content_type)

    # GL_ARRAY_BUFFER, GL_ELEMENT_ARRAY_BUFFER, etc.
    vao_key  = @mesh_to_gpu_mapping_info[content_type][:vao_key]
    gl_bfr_id = gpu_graphic_object.mesh_to_gpu_buffer_id_map[content_type] 

    Gl.glBindBuffer(vao_key, gl_bfr_id) 
  end

  def map_attributes_to_buffers(go, program_id)

    # Bind VAO to gpu context
    Gl.glBindVertexArray(go.vertex_array_obj_id)

    # Bind the buffer with the vertex locations (x,y,z) to the VAO
    # and map attribute to the buffer
    bind_buffer_to_vao(go, :position)
    map_attribute_to_buffer(program_id, :position)

    #vNorms = compute_vertex_normals(verts) if vNorms.nil?
    # Bind the buffer with the normal vectors to the VAO
    # and map attribute to the buffer
    bind_buffer_to_vao(go, :normal)
    map_attribute_to_buffer(program_id, :normal)

    # Bind the buffer with the texture coordinates to the VAO
    # and map attribute to the buffer
    bind_buffer_to_vao(go, :texcoord)
    map_attribute_to_buffer(program_id,  :texCoords)

    bind_buffer_to_vao(go, :index)
  end
 


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

    gpu_graphic_object.model_matrix = cpu_graphic_object.model_matrix
    gpu_graphic_object.color        = cpu_graphic_object.color

    gpu_graphic_object.mesh = cpu_graphic_object.mesh

    #gpu_graphic_object.write_mesh_data_to_gpu()
    write_mesh_data_to_gpu(gpu_graphic_object)

    # Create a VAO instance if one does not already exist for this cpu_graphic_object

    self.map_attributes_to_buffers(gpu_graphic_object, program_id)

    gpu_object_id
  end

  def write_mesh_data_to_gpu(gpu_graphic_object)

    gl_ready_buffers = pack_triangles_into_gpu_buffer_format(gpu_graphic_object.mesh.triangles)


    # Vertex Array instance has pointers to the buffers were loading
    # Bind opengl context / gl functions to the vertex array instance
    Gl.glBindVertexArray(gpu_graphic_object.vertex_array_obj_id)

    gl_ready_buffers.each_pair do |subcomponent, packed_buffer|

      content_config = @mesh_to_gpu_mapping_info[subcomponent]

      vao_key  = content_config[:vao_key] # GL_ARRAY_BUFFER, GL_ELEMENT_ARRAY_BUFFER, etc.

      gl_bfr_id = gpu_graphic_object.mesh_to_gpu_buffer_id_map[subcomponent] 

      Gl.glBindBuffer(vao_key, gl_bfr_id)
      Gl::glBufferData(vao_key, packed_buffer.size, packed_buffer, Gl::GL_DYNAMIC_DRAW) # Gl::GL_STATIC_DRAW
    end

    @index_count= gl_ready_buffers[:index].size
    gpu_graphic_object.index_count = @index_count
  end

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

end


