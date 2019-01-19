require './util/uniforms'
require './gl_ffi'
require './gpu_object'
require './gpu_driver_buffers'
require './util/geo3d_vector'
require './util/debug'

class Gpu
  def initialize
    @uniformsLocationCache = Uniforms_Location_Cache.new

    @shader_attribute_location_cache = Hash.new do |hash, tag|
      gl_program_id, attr_name = tag
      hash[tag] = Gl.getAttribLocation(gl_program_id, attr_name.to_s)
    end

    initialize_buffer_mapping
  end

  def get_attribute_location(gl_program_id, attribute_name)
    attr_location = @shader_attribute_location_cache[[gl_program_id, attribute_name]]
  end

  # compile and push shader to gpu
  #
  # todo raise info if compile fails
  #
  def push_shader(shader_type, shader_source_code)
    shader_id = Gl.glCreateShader(shader_type)

    sources = [shader_source_code] unless sources.is_a?(Array)
    source_lengths = sources.map(&:bytesize).pack('i*')
    source_pointers = sources.pack('p')

    Gl.shaderSource(shader_id, sources.length, source_pointers, source_lengths)

    Gl.compileShader(shader_id)

    shader_id
  end

  def update_camera_view(gl_program_id, camera)
    # set_uniform_matrix(gl_program_id, :view,         camera.view)
    set_uniform_matrix(gl_program_id, :view,         camera.world_to_camera_space)
    set_uniform_matrix(gl_program_id, :projection,   camera.perspective)
    set_uniform_vector(gl_program_id, :vEyePosition, camera.camera_location_in_world_space)

    check_for_gl_error
  end

  def update_lights(gl_program_id)
    uniform_variables_hash = {
      'light.position' => { elements: 3, data: Geo3d::Vector.new(0.0, 0.0, 20.0) }, # in world space
      # 'material.diffuse'  => 0,
      # 'material.specular' => 1,
    }

    set_uniforms_in_bulk(gl_program_id, uniform_variables_hash)
  end

  def render_object(gpu_graphic_object)
    vertex_array_obj_id = gpu_graphic_object.vertex_array_obj_id

    # puts "render_object vertex_array_obj_id = #{vertex_array_obj_id}"

    # Bind VAO to gpu context
    Gl.glBindVertexArray(vertex_array_obj_id)

    # Set graphic object specific uniforms
    set_uniforms_in_bulk(gpu_graphic_object.gl_program_id, gpu_graphic_object.uniform_variables)

    Gl.drawElements(Gl::GL_TRIANGLES, gpu_graphic_object.element_count, Gl::GL_UNSIGNED_INT, 0)
  end
end
