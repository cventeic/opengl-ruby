
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
    #error = Gl.getError()
    #puts "error before call to set_uniform_matrix"

    location = @uniformsLocationCache.uniform_location(program_id, uniform_name)
    d = data.to_a.flatten.pack("f*")
    Gl.uniformMatrix4fv(location, 1, Gl::GL_FALSE, d)
    error = Gl.getError()
    puts "set_uniform_matrix uniform_name = #{uniform_name}, glError = #{error}" unless error == 0
  end

  def set_uniform_vector(program_id, uniform_name, data)
    location = @uniformsLocationCache.uniform_location(program_id, uniform_name)
    d = data.to_a.pack("f*")
    Gl.uniform4fv(location, 1, d)
    error = Gl.getError()
    puts "set_uniform_vector uniform_name = #{uniform_name}, glError = #{error}" unless error == 0
  end

  def set_uniforms_vec3(program_id, variable_value_hash)

    variable_value_hash.each_pair do |variable, value|
      location = @uniformsLocationCache.uniform_location(program_id, variable)
      if value[0].is_a? Float
        d = value.pack("f*")
        #Gl.uniform3fv(location, 1, d)
        Gl.uniform3f(location, value[0], value[1], value[2])
        #puts "set uniform_vec3 #{variable}, #{value}"
        error = Gl.getError()
        puts "C glError = #{error}" unless error == 0
      else
        puts error
      end
    end
  end

  def set_uniforms_1(program_id, variable_value_hash)

    variable_value_hash.each_pair do |variable, value|
      location = @uniformsLocationCache.uniform_location(program_id, variable)
      if value.is_a? Float
        Gl.uniform1f(location, value)

        error = Gl.getError()
        puts "A glError = #{error}" unless error == 0

      elsif value.is_a? Integer
        Gl.uniform1i(location, value)
        error = Gl.getError()
        puts "B glError = #{error}" unless error == 0

      else
        puts "error"
      end
    end
  end


end


