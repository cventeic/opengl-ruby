require './util/uniforms'
require './gl_ffi'
require './gpu_object.rb'
require './gpu_driver_buffers.rb'
require './util/geo3d_vector.rb'


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

    set_uniform_matrix(program_id, :view,         camera.view)
    set_uniform_matrix(program_id, :projection,   camera.perspective)
    set_uniform_vector(program_id, :vEyePosition, camera.camera_location_in_world_space)

    error = Gl.getError()
    puts "Error: update_camera_view,  glError = #{error}" unless error == 0
 
  end

  def update_lights(program_id)

    uniform_variables_hash = {
      'light.position' => {elements: 3, data: Geo3d::Vector.new(0.0, 0.0, 20.0)},    # in world space
      #'material.diffuse'  => 0,
      #'material.specular' => 1,
    }

    set_uniforms_in_bulk(program_id, uniform_variables_hash)
  end

  def render_object(gpu_object_id)
    vertex_array_obj_id = gpu_object_id
    
    gpu_graphic_object = @gpu_graphic_objects[gpu_object_id]

    # Bind VAO to gpu context
    Gl.glBindVertexArray(vertex_array_obj_id)

    # Set graphic object specific uniforms
    set_uniforms_in_bulk(gpu_graphic_object.program_id, gpu_graphic_object.uniform_variables)

    Gl.drawElements(Gl::GL_TRIANGLES, gpu_graphic_object.element_count, Gl::GL_UNSIGNED_INT, 0)
  end

end


