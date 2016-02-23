require './util/uniforms'
require './gl_ffi'
require './gpu_object.rb'
require './gpu_driver_buffers.rb'


class Gpu
  def initialize
    @uniformsLocationCache = Uniforms_Location_Cache.new()

    @gpu_graphic_objects = Hash.new

    self.initialize_buffer_mapping()
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

    set_uniform_vector(program_id, :vEyePosition, vec_camera_location_in_world_space)

    error = Gl.getError()
    puts "Error: update_camera_view,  glError = #{error}" unless error == 0
 
  end

  def update_lights(program_id)
    uniforms_vec3 = {
#      'viewPos'           => [0.0, 0.0, 0.0],
       'light.position'    => [0.0, 0.0, 10.0],    # in world space
#      'light.direction'   => [0.0, 0.0, -1.0],    # spotlight
    }

    uniforms_1 = {
      #'material.diffuse'  => 0,
      #'material.specular' => 1,
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

    Gl.drawElements(Gl::GL_TRIANGLES, gpu_graphic_object.element_count, Gl::GL_UNSIGNED_INT, 0)
  end

end


