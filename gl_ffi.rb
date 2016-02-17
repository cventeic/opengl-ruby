require 'fiddle'
require 'fiddle/import'
require 'ap'


module Gl 
  extend Fiddle::Importer
  dlload 'libGL.so.1'

  typealias 'GLsizei', 'int' 
  #typealias 'GLuint*', 'unsigned int*'
  typealias 'GLuint', 'unsigned int'
  typealias 'GLint', 'int'
  typealias 'GLenum', 'unsigned int'
  typealias 'GLboolean', 'int'
  typealias 'GLbitfield', 'int'
  typealias 'GLvoid', 'void' 
  typealias 'GLfloat', 'float' 
  typealias 'GLdouble', 'float' 

  GL_FALSE                                                      = 0

=begin
  GL_FALSE                                                      = 0
  GL_TRUE                                                       = 1
 
  GL_TRIANGLES                                                  = 0x0004

  GL_CULL_FACE                                                  = 0x0B44

  GL_COLOR_BUFFER_BIT                                           = 0x00004000
  GL_DEPTH_BUFFER_BIT                                           = 0x00000100
  GL_STENCIL_BUFFER_BIT                                         = 0x00000400

  GL_UNSIGNED_INT                                               = 0x1405
  GL_FLOAT                                                      = 0x1406

  GL_VERTEX_SHADER                                              = 0x8B31
  GL_FRAGMENT_SHADER                                            = 0x8B30

  GL_ARRAY_BUFFER                                               = 0x8892
  GL_ELEMENT_ARRAY_BUFFER                                       = 0x8893
 
  GL_STATIC_DRAW                                                = 0x88E4
  GL_DYNAMIC_DRAW                                               = 0x88E8

  GL_INFO_LOG_LENGTH                                            = 0x8B84

  # Depth buffer
  GL_NEVER				= 0x0200
  GL_LESS					= 0x0201
  GL_EQUAL				= 0x0202
  GL_LEQUAL				= 0x0203
  GL_GREATER				= 0x0204
  GL_NOTEQUAL				= 0x0205
  GL_GEQUAL				= 0x0206
  GL_ALWAYS				= 0x0207
  GL_DEPTH_TEST				= 0x0B71
  GL_DEPTH_BITS				= 0x0D56
  GL_DEPTH_CLEAR_VALUE			= 0x0B73
  GL_DEPTH_FUNC				= 0x0B74
  GL_DEPTH_RANGE				= 0x0B70
  GL_DEPTH_WRITEMASK			= 0x0B72
  GL_DEPTH_COMPONENT			= 0x1902

  GL_FRAMEBUFFER                    = 0x8D40
  GL_RENDERBUFFER                   = 0x8D41
  GL_DEPTH_COMPONENT16              = 0x81A5
  GL_DEPTH_COMPONENT24              = 0x81A6
  GL_DEPTH_COMPONENT32              = 0x81A7

  GL_DRAW_FRAMEBUFFER               = 0x8CA9
  GL_DEPTH_ATTACHMENT               = 0x8D00
=end


  #extern 'void glViewport(	GLint , GLint , GLsizei , GLsizei )'

  #def Gl.viewport(x, y, width, height)
  #  glViewport(	x, y, width, height)
  #end


  extern 'void glGetBooleanv(	GLenum , GLboolean * )'

  def Gl.getBooleanv(	pname )
    free = Fiddle::Function.new(Fiddle::RUBY_FREE, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
    p = Fiddle::Pointer.malloc(Fiddle::SIZEOF_BOOLEAN*1, free)
    p[0] = 0

    # Note there needs to be a window context before this is called or garbage
    # is returned
    glGetBooleanv(1, p) 
    p[0] 
  end


  extern 'void glGetFloatv(	GLenum , GLfloat * )'
  def Gl.getFloatv(	pname )
    free = Fiddle::Function.new(Fiddle::RUBY_FREE, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
    p = Fiddle::Pointer.malloc(Fiddle::SIZEOF_FLOAT*1, free)
    p[0] = 0

    # Note there needs to be a window context before this is called or garbage
    # is returned
    glGetFloatv(1, p) 
    p[0] 
  end


  extern 'void glGetIntegerv(	GLenum , GLint * )'
  def Gl.getIntegerv(	pname )
    free = Fiddle::Function.new(Fiddle::RUBY_FREE, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
    p = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT*1, free)
    p[0] = 0

    # Note there needs to be a window context before this is called or garbage
    # is returned
    glGetIntegerv(1, p) 
    p[0] 
  end




  extern 'void glGenRenderbuffers(	GLsizei, GLuint * )'
  def Gl.genRenderbuffer

    free = Fiddle::Function.new(Fiddle::RUBY_FREE, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
    p = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT*1, free)
    p[0] = 0

    # Note there needs to be a window context before this is called or garbage
    # is returned
    glGenRenderbuffers(1, p) 
    p[0] 
  end


  extern 'void glBindRenderbuffer(GLenum, GLuint)'

  def Gl.bindRenderbuffer(target_id, buffer_id)
    glBindRenderbuffer(target_id, buffer_id)
  end

  extern 'void glRenderbufferStorage( GLenum , GLenum , GLsizei , GLsizei)'
  def Gl.renderbufferStorage( target, internalformat, width, height)
    glRenderbufferStorage( target, internalformat, width, height)
  end

  extern 'void glGenFramebuffers(	GLsizei , GLuint * )'

  def Gl.genFramebuffer

    free = Fiddle::Function.new(Fiddle::RUBY_FREE, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
    p = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT*1, free)
    p[0] = 0

    # Note there needs to be a window context before this is called or garbage
    # is returned
    glGenFramebuffers(1, p) 
    p[0] 
  end



  extern 'void glBindFramebuffer(	GLenum , GLuint )'

  def Gl.bindFramebuffer(target_id, buffer_id)
    glBindFramebuffer(target_id, buffer_id)
  end

  extern 'void glFramebufferRenderbuffer( GLenum , GLenum , GLenum , GLuint )'

  def Gl.framebufferRenderbuffer( target, attachment, renderbuffertarget, renderbuffer)
    glFramebufferRenderbuffer( target, attachment, renderbuffertarget, renderbuffer)
  end



  extern 'void glDepthRange( GLdouble , GLdouble )'

  def Gl.depthRange( nearVal, farVal)
    glDepthRange( nearVal, farVal)
  end

=begin

  extern 'void glDepthFunc(	GLenum )'

  def Gl.depthFunc(	func)
    glDepthFunc(func)
  end

  extern 'void glDepthMask(	GLboolean )'
  def Gl.depthMask(	flag )
    glDepthMask(flag)
  end
=end

  #extern 'void glGetShaderInfoLog(GLuint shader, GLsizei maxLength, GLsizei * length, GLchar * infoLog)'
  extern 'void glGetShaderInfoLog(GLuint, GLsizei, GLsizei *, GLchar *)'
  def Gl.getShaderInfoLog(shader_id)

    log_len = Gl.getShaderiv(shader_id, Gl::GL_INFO_LOG_LENGTH )

    log = ""
    log = log.rjust(log_len, '.')

    out_len_bits = [0].pack('i*')

    log_ptr = Fiddle::Pointer[log]

    if log_len > 0 then
      glGetShaderInfoLog( shader_id, log_len, out_len_bits, log_ptr)
    end

    log_ptr.to_s 
  end

  # Returns a parameter from a shader object
  extern 'void glGetShaderiv(	GLuint , GLenum , GLint *)'

  def Gl.getShaderiv(	shader, pname )

    value_bits = [0].pack('i*')
    glGetShaderiv( shader, pname, value_bits)
    value = value_bits.unpack('i*')

    value[0]
  end


  # glGetProgramInfoLog — return the information log for a program object
  extern 'void glGetProgramInfoLog(	GLuint, GLsizei, GLsizei *, GLchar *)'

  def Gl.getProgramInfoLog(program_id)
    # Fiddle will pack and unpack strings automatically
    # Might work on structs too...
    # Anything else you need to manually pack and unpack
    
    log_len = Gl.getProgramiv(program_id, Gl::GL_INFO_LOG_LENGTH )
    log = ""
    log = log.rjust(log_len, '.')

    out_len_bits = [0].pack('i*')

    if log_len > 0 then
      glGetProgramInfoLog( program_id, log_len, out_len_bits, log)
    end

    log.to_s 
  end


  # Returns a parameter from a program object
  extern 'void glGetProgramiv(	GLuint , GLenum , GLint *)'

  def Gl.getProgramiv(	program, pname )

    value_bits = [0].pack('i*')
    glGetProgramiv( program, pname, value_bits)
    value = value_bits.unpack('i*')

    value[0]
  end

  extern 'GLenum glGetError()'
  def Gl.getError()
    glGetError()
  end
  
=begin
  extern 'void glEnable(GLenum)'
  def Gl.enable(cap)
    glEnable(cap)
  end

  extern 'void glDisable(GLenum)'
  def Gl.enable(cap)
    glDisable(cap)
  end
=end

  # extern 'void glUniform3f(	GLint location, GLfloat v0, GLfloat v1, GLfloat v2)'
  extern 'void glUniform3f(	GLint , GLfloat, GLfloat, GLfloat )'
  def Gl.uniform3f(	location, v0, v1, v2)
    glUniform3f(location, v0, v1, v2)
  end

  # extern 'void glUniform1f(	GLint location, GLfloat v0)'
  extern 'void glUniform1f(	GLint , GLfloat )'
  def Gl.uniform1f(	location, v0)
    glUniform1f(location, v0)
  end

  # extern 'void glUniform1i(	GLint location, GLint v0)'
  extern 'void glUniform1i(	GLint , GLint )'
  def Gl.uniform1i(	location, v0)
    glUniform1i(location, v0)
  end

  extern 'void glUniform3fv(GLint, GLsizei, const GLfloat *)'
  def Gl.uniform3fv(	location, count, value)
    glUniform4fv(	location, count, value)
  end

  extern 'void glUniform4fv(GLint, GLsizei, const GLfloat *)'
  def Gl.uniform4fv(	location, count, value)
    glUniform4fv(	location, count, value)
  end

  extern 'void glUniformMatrix4fv(GLint, GLsizei, GLboolean, const GLfloat *)'

  def Gl.uniformMatrix4fv(location, count, transpose, value)
    glUniformMatrix4fv(location, count, transpose, value)
  end


  extern 'GLint glGetUniformLocation(	GLuint , const GLchar *)'

  def Gl.getUniformLocation(program, name)
    glGetUniformLocation(program, name)
  end

  extern 'void glDrawElements(	GLenum, GLsizei, GLenum, const GLvoid *)' 

  def Gl.drawElements(mode, count, type, indices)
    glDrawElements(mode, count, type, indices)
  end

=begin
  extern 'void glClear(GLbitfield)'

  def Gl.clear(mask)
    glClear(mask)
  end
=end


  extern 'void glEnableVertexAttribArray(	GLuint )'

  def Gl.enableVertexAttribArray(	attr_index )
    glEnableVertexAttribArray(attr_index)
  end


  #extern 'GLint glGetAttribLocation(  GLuint program, const GLchar *name)'
  extern 'GLint glGetAttribLocation(GLuint, const GLchar *)'

  def Gl.getAttribLocation(program_id, attr_name)
    glGetAttribLocation(program_id, attr_name)
  end


  extern 'void glVertexAttribPointer(	GLuint, GLint, GLenum, GLboolean, GLsizei, const GLvoid *)'

  def Gl.vertexAttribPointer(index, size, type, normalized, stride, pointer)
    glVertexAttribPointer(index, size, type, normalized, stride, pointer)
  end



  extern 'void glBindBuffer(GLenum, GLuint)'

  def Gl.bindBuffer(target_id, buffer_id)
    glBindBuffer(target_id, buffer_id)
  end

  # void glBufferData(
  #   GLenum target, GLsizeiptr size, const GLvoid * data, GLenum usage);
  #
  extern 'void glBufferData(GLenum, GLsizei, const GLvoid *, GLenum)'

  def Gl.bufferData(target, size, data, usage)
    glBufferData(target, size, data, usage)
  end


  extern 'void glBindVertexArray(GLuint)'

  def Gl.bindVertexArray(vertex_array_id)
    glBindVertexArray(vertex_array_id)
  end


  extern 'void glUseProgram(GLuint)'

  def Gl.useProgram(program_id)
    glUseProgram(program_id)
  end

  extern 'void glLinkProgram(GLuint)'

  def Gl.linkProgram(program_id)
    glLinkProgram(program_id)
  end

  extern 'void glAttachShader(GLuint,GLuint)'

  def Gl.attachShader(program_id, shader_id)
    glAttachShader(program_id, shader_id)
  end

  extern 'void glCompileShader(GLuint)'

  def Gl.compileShader(vertex_shader_id)
    glCompileShader(vertex_shader_id)
  end

  #extern 'void glShaderSource(GLuint shader, GLsizei count, const GLchar **string, const GLint *length)'
  extern 'void glShaderSource(GLuint, GLsizei, const GLchar **, const GLint *)'

  def Gl.shaderSource(shader, count, pointers, lengths)
    glShaderSource(shader, count, pointers, lengths);
  end


  extern 'GLuint glCreateShader(GLenum)'

  def Gl.createShader(shaderType)
    glCreateShader(shaderType)
  end

  
  extern 'GLuint glCreateProgram()'

  def Gl.createProgram
    glCreateProgram()
  end

  extern 'void glGenBuffers(int, unsigned *)'

  def Gl.genBuffer

    free = Fiddle::Function.new(Fiddle::RUBY_FREE, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
    p = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT*1, free)
    p[0] = 0

    # Note there needs to be a window context before this is called or garbage
    # is returned
    glGenBuffers(1, p) 
    p[0] 
  end



  # glGenVertexArrays - generate vertex array object names
  # void glGenVertexArrays(GLsizei n, GLuint *arrays);
  #
  #   n      - Specifies the number of vertex array object names to generate.
  #   arrays - Specifies an array in which the generated vertex array object names are stored.
  #
  # glGenVertexArrays returns n vertex array object names in arrays. 
  extern 'void glGenVertexArrays(int, unsigned *)'

  def Gl.genVertexArray
    free = Fiddle::Function.new(Fiddle::RUBY_FREE, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
    p = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT*1, free)
    p[0] = 0

    # Note there needs to be a window context before this is called or garbage
    # is returned
    glGenVertexArrays(1, p) 
    p[0] 
  end

end

require 'minitest/autorun'

class BugTest < Minitest::Test
  def _test_genBuffer
    id = Gl.genBuffer()
    assert(id > 0)
  end
  def _test_genVertexArray
    id = Gl.genVertexArray()
    assert(id > 0)
  end
end


