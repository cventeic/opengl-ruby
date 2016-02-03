
class Gpu
  def initialize
    @gpu_graphic_objects = Hash.new
  end

  def render_object(gpu_object_id)
    vertex_array_obj_id = gpu_object_id
    
    gpu_graphic_object = @gpu_graphic_objects[gpu_object_id]

    # Bind VAO to gpu context
    Gl.glBindVertexArray(vertex_array_obj_id)

    Gl.drawElements(Gl::GL_TRIANGLES, gpu_graphic_object.index_count, Gl::GL_UNSIGNED_INT, 0)
  end

  def map_attribute_to_buffer(program_id, _attr_name, element_size=3)
    attr_name = _attr_name.to_s

    attr_location = Gl.getAttribLocation(program_id, attr_name)

    if attr_location >= 0 then
      Gl.vertexAttribPointer(attr_location, element_size, Gl::GL_FLOAT, Gl::GL_FALSE, 0, 0)
      Gl.enableVertexAttribArray(attr_location)
    end
  end


  def map_attributes_to_buffers(go, program_id)

    # Bind VAO to gpu context
    Gl.glBindVertexArray(go.vertex_array_obj_id)

    # Bind the buffer with the vertex locations (x,y,z) to the VAO
    # and map attribute to the buffer
    #go.vertex_vbo.bind_buffer_to_vao
    go.bind_buffer_to_vao(:vertex)
    map_attribute_to_buffer(program_id, :vertexPosition_modelspace)

    # Bind the buffer with the normal vectors to the VAO
    # and map attribute to the buffer
    #go.normal_vbo.bind_buffer_to_vao
    go.bind_buffer_to_vao(:normal)
    map_attribute_to_buffer(program_id, :vertexNormal_modelspace)

    # Bind the buffer with the texture coordinates to the VAO
    # and map attribute to the buffer
    #go.texcoord_vbo.bind_buffer_to_vao
    go.bind_buffer_to_vao(:texcoord)
    map_attribute_to_buffer(program_id,  :vertexUV)

    #go.index_vbo.bind_buffer_to_vao
    go.bind_buffer_to_vao(:index)
  end
  
  def push_cpu_graphic_object(program_id, cpu_graphic_object, gpu_object_id = -1)
    # vertex_array_obj_id = gpu_object_id

    if gpu_object_id < 0
      gpu_graphic_object = GPU_Graphic_Object.new()
      gpu_object_id = gpu_graphic_object.vertex_array_obj_id
      @gpu_graphic_objects[gpu_object_id] = gpu_graphic_object
    end

    gpu_graphic_object = @gpu_graphic_objects[gpu_object_id]

    gpu_graphic_object.mesh = cpu_graphic_object.mesh

    gpu_graphic_object.write_mesh_data_to_gpu()

    # Create a VAO instance if one does not already exist for this cpu_graphic_object

    self.map_attributes_to_buffers(gpu_graphic_object, program_id)

    gpu_object_id
  end
end


