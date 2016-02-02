#require 'opengl-core'
require './gl_ffi'


# Remove the GL:: references in this file and we can completely decouple from
# opengl-core

# Buffers
#   Buffers are allocated in the GPU

# Open GL functions don't accept arbitrary buffer id's as input.
# 
# Instead a context must be established.
#   The GL function then accesses buffers mapped within the context.
#
#             vao:1 --> 
#             vao:2 --> 
# Current --> vao:3 --> binding:<some target id>  --> buffer_id:<some bfr id>  --> buffer: ...
# Context           --> binding:GL_ARRAY_BUFFER   --> buffer_id:5              --> buffer: ...
#                   --> binding:GL_UNIFORM_BUFFER --> buffer_id:6              --> buffer: ... 
#             vao:4 --> 
#
#

# VAO binding target id's
#
# GL_ARRAY_BUFFER	            Vertex attributes
# GL_ATOMIC_COUNTER_BUFFER	  Atomic counter storage
# GL_COPY_READ_BUFFER	        Buffer copy source
# GL_COPY_WRITE_BUFFER	      Buffer copy destination
# GL_DISPATCH_INDIRECT_BUFFER	Indirect compute dispatch commands
# GL_DRAW_INDIRECT_BUFFER	    Indirect command arguments
# GL_ELEMENT_ARRAY_BUFFER	    Vertex array indices
# GL_PIXEL_PACK_BUFFER	      Pixel read target
# GL_PIXEL_UNPACK_BUFFER	    Texture data source
# GL_QUERY_BUFFER	            Query result buffer
# GL_SHADER_STORAGE_BUFFER	  Read-write storage for shaders
# GL_TEXTURE_BUFFER	          Texture data buffer
# GL_TRANSFORM_FEEDBACK_BUFFER	Transform feedback buffer
# GL_UNIFORM_BUFFER	          Uniform block storage
# Class representing a GPU Buffer instance
# Cooresponds to a numeric buffer id in buffer id space
#
# /todo make this class about the buffer instance and another class about buffer
#       actions like binding and setting values
#
# /todo see opengl-aux/lib/opengl-aux/buffer.rb for a better more complete example
 
class GPU_Buffer
  attr_accessor :vao_target_id, :gpu_buffer_id
  def initialize(vao_target_id)
    @vao_target_id = vao_target_id
    @gpu_buffer_id = 0 # initially unbound 
    @gpu_buffer_id = Gl.genBuffer()
  end

  def establish_buffer_id()
    # Allocate the buffer if it does not already exist
    if @gpu_buffer_id == 0
      @gpu_buffer_id = Gl.genBuffer()
    end
  end

  def bind_buffer_to_vao()
    puts " bind_buffer_to_vao() vao_target_id = #{vao_target_id}, gpu_buffer_id = #{gpu_buffer_id}"
    # bind buffer to vao binding target
    Gl.glBindBuffer(@vao_target_id, @gpu_buffer_id)
  end
 
  def bind()
    bind_buffer_to_vao()
  end

  def unbind()
    Gl.glBindBuffer(@vao_target_id, 0)
  end

  # Writes data to buffer in gpu
  #
  # Assumes current configuration points to correct vao
  #
  # /todo fix name
  #
  def data_to_gpu(arrays, indicies)
    floats = Array.new

    arrays.each do |a|
      next if a.nil?
      next if a.size < indicies
      a.to_a.first(indicies).each do |aa|
        floats << aa
      end
    end

    #format = self.target == Gl::GL_ELEMENT_ARRAY_BUFFER ? "L*" : "f*"
    format = @vao_target_id == Gl::GL_ELEMENT_ARRAY_BUFFER ? "L*" : "f*"

    return if floats.nil? || floats.size == 0
    data = floats.pack(format)

    self.bind

    #GL::glBufferData(vbo.target, data.size, data, Gl::GL_STATIC_DRAW);
    Gl::glBufferData(@vao_target_id, data.size, data, Gl::GL_DYNAMIC_DRAW);

    self.unbind
  end
end


