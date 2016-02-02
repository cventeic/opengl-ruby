require "./gl_ffi"
require "./gl_buffer"

#######################################################
class GPU_Graphic_Object
  attr_accessor :mesh, :vertex_array_obj_id, :vertex_vbo, :normal_vbo, :texcoord_vbo, :index_vbo, :track_mouse, :index_count

  def initialize(mesh=nil)
    @mesh = mesh
    @vertex_array_obj_id = Gl.genVertexArray

    @vertex_vbo   = GPU_Buffer.new(Gl::GL_ARRAY_BUFFER)
    @normal_vbo   = GPU_Buffer.new(Gl::GL_ARRAY_BUFFER)
    @texcoord_vbo = GPU_Buffer.new(Gl::GL_ARRAY_BUFFER)
    @index_vbo    = GPU_Buffer.new(Gl::GL_ELEMENT_ARRAY_BUFFER)
    @index_count  = 0
  end

  def mesh_data_to_gpu()
    #puts "push_to_hardware updated? #{@old_position == @position} count #{@cc}"

    # Vertex Array instance has pointers to the buffers were loading
    # Bind opengl context / gl functions to the vertex array instance
    Gl.glBindVertexArray(@vertex_array_obj_id)

    @vertex_vbo.data_to_gpu(@mesh.position, 3)
    @normal_vbo.data_to_gpu(@mesh.normal, 3)
    @texcoord_vbo.data_to_gpu(@mesh.tex, 2)
    @index_vbo.data_to_gpu(@mesh.index, 1)

    @index_count= mesh.index.size
  end

  def draw
    Gl.glBindVertexArray(@vertex_array_obj_id)

    Gl.drawElements(Gl::GL_TRIANGLES, @index_count, Gl::GL_UNSIGNED_INT, 0)
  end
end


