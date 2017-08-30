require './util/debug'

# Uniforms:
#   Data (variables) that are not vertex specific for a model.
#

# Uniforms
#   have a variable name inside the shader code (gpu)
#   have a location id in cpu space
#
# Looking up the location id from the variable name is expensive.
# So this class caches the location id after the first lookup.
#
class Uniforms_Location_Cache
  def initialize
    @uniform_locations = {}
  end

  # to do cache on program_id too
  def uniform_location(program_id, name)
    uniform_sym = name.to_sym
    locations = @uniform_locations
    locations[uniform_sym] ||= Gl.getUniformLocation(program_id, name.to_s)
  end

  alias_method :[], :uniform_location
end


class Gpu

  def set_uniform_matrix(program_id, uniform_name, data)

    location = @uniformsLocationCache.uniform_location(program_id, uniform_name)
    d = data.to_a.flatten.pack("f*")
    Gl.uniformMatrix4fv(location, 1, Gl::GL_FALSE, d)

    check_for_gl_error(uniform_name: uniform_name)
  end

  def set_uniform_vector(program_id, uniform_name, data, element_count=4)
    location = @uniformsLocationCache.uniform_location(program_id, uniform_name)
    data_array = data.to_a.first(element_count)
    d = data_array.pack("f*")

    Gl.uniform3f(location, *data_array) if element_count == 3
    Gl.uniform4fv(location, 1, d) if element_count == 4

    check_for_gl_error(uniform_name: uniform_name)
  end

  # Set uniforms in bulk from data structure of form
  #
  # uniform_variables_hash = {
  #   var_name: = {container: {:vector, :matrix}, data: actual_data},
  #   model:    = {container: :matrix, data: _matrix},
  #   color:    = {container: :vector, data: _color},
  # }
  #
  def set_uniforms_in_bulk(program_id, uniform_variables_hash)

    uniform_variables_hash.each_pair do |parameter, config_and_data|

      elements  = config_and_data.fetch(:elements, 4)
      #container = config_and_data[:container]
      data      = config_and_data[:data]
      location = @uniformsLocationCache.uniform_location(program_id, parameter)

      #set_uniform_matrix(program_id, parameter, data ) if container == :matrix

      set_uniform_vector(program_id, parameter, data, elements ) if data.is_a? Geo3d::Vector
      set_uniform_matrix(program_id, parameter, data ) if data.is_a? Geo3d::Matrix

      Gl.uniform1f(location, data) if data.is_a? Float
      Gl.uniform1i(location, data) if data.is_a? Integer

    end
  end

end


