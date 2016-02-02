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

  GL_FALSE                                                      = 0
  GL_TRUE                                                       = 1
 
  GL_TRIANGLES                                                  = 0x0004

  GL_UNSIGNED_INT                                               = 0x1405
  GL_FLOAT                                                      = 0x1406

  GL_COLOR_BUFFER_BIT                                           = 0x00004000
  GL_DEPTH_BUFFER_BIT                                           = 0x00000100
  GL_STENCIL_BUFFER_BIT                                         = 0x00000400

  GL_VERTEX_SHADER                                              = 0x8B31
  GL_FRAGMENT_SHADER                                            = 0x8B30

  GL_ARRAY_BUFFER                                               = 0x8892
  GL_ELEMENT_ARRAY_BUFFER                                       = 0x8893
 
  GL_STATIC_DRAW                                                = 0x88E4
  GL_DYNAMIC_DRAW                                               = 0x88E8


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

  extern 'void glClear(GLbitfield)'

  def Gl.clear(mask)
    glClear(mask)
  end


  extern 'void glVertexAttribPointer(	GLuint, GLint, GLenum, GLboolean, GLsizei, const GLvoid *)'

  def Gl.vertexAttribPointer(index, size, type, normalized, stride, pointer)
    glVertexAttribPointer(index, size, type, normalized, stride, pointer)
  end

  extern 'void glEnableVertexAttribArray(	GLuint )'

  def Gl.enableVertexAttribArray(	attr_index )
    glEnableVertexAttribArray(attr_index)
  end


  #extern 'GLint glGetAttribLocation(  GLuint program, const GLchar *name)'
  extern 'GLint glGetAttribLocation(GLuint, const GLchar *)'

  def Gl.getAttribLocation(program_id, attr_name)
    glGetAttribLocation(program_id, attr_name)
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
    puts "--- glGenBuffers buffer_id = #{p[0]}"
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
    puts "--- glGenVertexArrays buffer_id = #{p[0]}"
    p[0] 
  end

end

require 'minitest/autorun'

class BugTest < Minitest::Test
  def test_genBuffer
    id = Gl.genBuffer()
    assert(id > 0)
  end
  def test_genVertexArray
    id = Gl.genVertexArray()
    assert(id > 0)
  end
end


