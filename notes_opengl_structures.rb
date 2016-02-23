# This file is just notes.... 

# To Render a 3D scene... The GPU must be given the following data.
#
# - A set of graphic objects to render
#     Each object has:
#       * A set of triangles... 3 3D points... (x,y,z,color) for each point.
#       * A matrix to position the object in world space (rotate, translate, scale) 
#
# - A set of lights to render
#     Each light has:
#       * Parameters defining the light
#       * A matrix to position the object in world space (rotate, translate, scale) 
#
# - A camera to render
#     Each camera has:
#       * Parameters ???
#       * A matrix to position the camera in world space (rotate, translate, scale) 
#
# - The command to render a 2D image of the world as viewed from the camera
#
#

# The OpenGL API is a not easy to use... It's a backward compatible kludge...
#
# OpenGL started when graphics hardware was a rigid fixed pipeline where object
# meshes were re-sent to the hardware every time the object was rendered.
#
# The OpenGL API was written against the single object at a time model.
#
# Modern GPU's are full flexible compute platforms.
# Graphic object meshes and position matrixes remain in GPU memory
# The GPU can (re) render scenes from internal data stores.
# 
# In my current code, 
#   The main CPU has to initiate a re-draw of each object on a scene change
#   The main CPU does not need to re-transfer the mesh data for each object.
#
# My hope is the code and shaders can be re-written so
#   the main CPU does not need to re-draw each object independently...
#

# The OpenGL API is a not easy to use... It's a backward compatible kludge...
#
# Kronos needed to get the data for multiple graphical objects into the GPU but
# did not want to break the existing functions that assumed a single object in
# the GPU at a time.
#
# The kludge was ...
#
# API to create a Vertex Array Object for each graphical object.
# API to select the currently active VAO / graphical object.
# Existing functions then work on the current VAO without breaking backward
#   compatiblity by adding a VAO selection parameter to the original functions.
#
# Along with this buffers are allocated independently and when needed but the
# core API functions weren't changed by adding buffer id's to the legacy
# functions. 
# An API function exists to map a buffer id to the role of the buffer in
# interactions with the legacy API.  (GL_ARRAY_BUFFER, etc)
#
# Open GL functions don't accept arbitrary buffer id's as input.
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

# Note: it is reasonable to give each graphical object it's own vao (vertex array object) 
#
#       then you can configure all the buffers,
#       variable to buffer mappings,
#       and uniforms
#       for that graphical object within the vao.
#
#       At render time you just switch the vao to match the graphical object and draw.
#
#  ToDo:
#  - Would be perhapse good to write wrappers for the original GL functions that
#  break the backward compatiblity such that it's more obvious what is
#  happening.
#
#    For example:
#      glDraw(object_id)
#

# Definitions:

## Vertex
#    One of 3 locations in a triangle
#

## Vertex Attribute
#    Data stored for each vertex
#    Example: Position, Normal, Color, Texture Coords are all vertex attributes
#

## Vertex Array Object
#    A open GL object agregating and encapsulating a large set of vertexes
#    
#    VAO interface facilitates the rapid (re)selection of a graphical object, in
#    terms of it's vertexes, to be rendered.


## Uniform
#    A uniform is a global GL Shader Language variable declared with the "uniform" storage qualifier. 
#    These act as parameters that the user of a shader program can pass to that program. 
#    Uniforms are stored in a program object.
#
#    Uniforms are stored with a program instance not with a vertex array object instance
#
#    Uniforms are so named because they do not change from one execution of a shader program to the next
#      within a particular rendering call. 
#    This makes uniforms unlike shader stage inputs and outputs, 
#      which are often different for each invocation of a program stage.

## Buffer Objects
#    Buffer Objects are an array of unformatted memory allocated in the GPU (w/in the OpenGL context)
#    Buffer Objects can store vertex data, pixel data retrieved from images or the framebuffer, etc.
#    
#    Create with glGenBuffers()
#       void glGenBuffers(GLsizei n, GLuint * buffers);
#         n       - Specifies the number of buffer object names to be generated.
#         buffers - Specifies an array in which the generated buffer object names (numbers) are stored.


=begin

# Data Flow Through Shaders
#

==== CPU ====

Input buffer:
  Object:
    Triangle:
      Vertex:
        Model Space:
          Position: (x,y,z)
          Normal Vector: (x, y, z)

==== Vertex Shader ====

Intermediate:
  Object:
    Triangle:
      Vertex:
        Model Space:
          Position: (x,y,z)
          Normal Vector: (x, y, z)

        World Space:
          Position: (x,y,z)
          Normal Vector: (x, y, z)

        Clip Space:
          Position: (x,y,z)

========
==== Fixed Function ====
==== Output a Window Pixel Fragement for each pixel covered by a triangle ===
==== All vertex values are interpolated to the pixel vertex from the 3 input vertex in triangle ===
========

Intermediate:
  Object:
    Triangle:
      Window Pixel:
        Window Position: (x, y, z)

        Vertex @ Pixel:
          Model Space:
            Position: (x,y,z)
            Normal Vector: (x, y, z)

          World Space:
            Position: (x,y,z)
            Normal Vector: (x, y, z)

          Clip Space:
            Position: (x,y,z)

==== Fragment Shader ====

Intermediate:
  Object:
    Triangle:
      Window Pixel:
        Window Position: (x, y, z)
        Color: (r, g, b, a)



=end






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


# What follows is pseudo code for the opengl data structures and functions
#

class program
  attr_accessor :vertex_shader_id, :fragment_shader_id, :attr_name_to_attr_index

  def initialize
    # map attribute / variable names in shader code to attr index
    @attr_name_to_attr_index[] = hash.new
    @attribute_to_vertex_sub_structure[] = hash.new
  end
end

class vao 
  def initialize
    @map_buffer_purpose_to_buffer_id = {
      # binding point used to set vertex array data pointers using glvertexattribpointer(). 
      # this is the target that you will likely use most often.
      'gl_array_buffer' => 0,


      # binding point for buffers that will be used as uniform buffer objects
      'gl_uniform_buffer' => 0,

      # buffers bound to this target can contain vertex indices 
      # which are used by indexed draw commands such as gldrawelements().
      'gl_element_array_buffer' => 0 
    }
  end
end

require 'ostruct'

ctx = openstruct.new

# buffers exist within an independent  "buffer space"
# buffers are accessed by a buffer_id
ctx.next_buffer_id = 0
cxt.buffer_map = {}

# vertex array objects encapsulate a set of paramters
# vao exist within an independent "vao space"
# vao instances are specified by a vao_id
ctx.next_vao_id = 0
ctx.current_vao_id = 0
cxt.vao_map = {}

#
#
#
ctx.next_program_id = 0
ctx.current_program_id = 0
cxt.program_map = {}

####

# glGenBuffers just allocates buffer id numbers (refered to as names by opengl)
#
def glGenBuffer(ctx)
  ctx.next_buffer_id += 1
  ctx.buffer_map[ctx.next_buffer_id] = array.new
  return ctx.next_buffer_id
end

# glBindBuffer binds the buffer specified by bufer_id to a binding point
# (GL_ARRAY_BUFFER, etc) in the VAO so subsequent function calls can access the
# buffer.
#
# Remember, GL is a kludge...
#  Many functions were written on the assumption only one GL_ARRAY_BUFFER (etc.)
#   would be supported by the hardware.
#  Ability to allocate and manage buffers was added later.
#  GL couldnt change existing function prototypes so instead you do this
# 
def glBindBuffer(ctx, vao_buffer_purpose, gl_buffer_id)
  current_vao = ctx.vao_map[ctx.current_vao_id]
  current_vao.map_buffer_purpose_to_buffer_id[vao_buffer_purpose] = gl_buffer_id
end

def glbufferdata(ctx, vao_paramter_id, data, extra)
  current_vao  = ctx.vao_map[ctx.current_vao_id]
  gl_buffer_id = current_vao.map_buffer_purpose_to_buffer_id[vao_buffer_purpose]
  ctx.buffer_map[gl_buffer_id] = data
  # not sure where extra goes
end

####

def glgenvertexarray(ctx)
  ctx.next_vao_id += 1
  ctx.vao_map[ctx.next_vao_id] = vao.new
  return ctx.next_vao_id
end

def glbindvertexarray(ctx, vao_id)
  ctx.current_vao_id = vao_id
end

######################################################################

def glcreateprogram(ctx)
  ctx.next_progam_id += 1
  ctx.program_map[ctx.next_program_id] = program.new
  return ctx.next_program_id
end

def glattachshader(ctx, program_id, shader_id)
end

def gllinkprogram(ctx, program_id)
end

def gluseprogram(ctx, program_id)
end

######################################################################
# attribute interface configures the transform or map from
#   shader program variable name <---> specific section in specific buffer 
#
# note: specific buffer is the buffer currently mapped to gl_array_buffer in
# current vao
#

# used to associate variables in shader to indexes
def glbindattrlocation(ctx, program_id, attr_index, attr_name)
  program = ctx.program_map[program_id]
  program.attr_name_to_attr_index[attr_name] = index
end

def glgetattrlocation(ctx, program_id, attr_name)
  program = ctx.program_map[program_id]
  index = program.attr_name_to_attr_index[attr_name]
  return index
end

def glvertexattribpointer(ctx, attr_index, num_components, data_type, stride=1, pointer=0)

  current_program = ctx.program_map[ctx.current_program_id]
  a_to_v = current_program.attribute_to_vertex_sub_structure[attr_index] = openstruct.new

  a_to_v.enabled        = false  # start with the parameter disabled

  a_to_v.num_components = num_components # (x,y,z = 3)
  a_to_v.data_type      = data_type      # (gl_unsigned_byte)
  a_to_v.stride         = stride         # 1
  a_to_v.pointer        = pointer        # 0


  current_vao  = ctx.vao_map[ctx.current_vao_id]
  current_array_buffer_id = current_vao.map_buffer_purpose_to_buffer_id['gl_array_buffer'];

  a_to_v.buffer_id      = current_array_buffer_id
end

def glenablevertexattribarray(attr_index)
  current_program = ctx.program_map[ctx.current_program_id]
  a_to_v = current_program.attribute_to_vertex_sub_structure[attr_index]
  a_to_v.enabled = true
end

