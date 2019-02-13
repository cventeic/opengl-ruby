require 'sdl2'
require 'ostruct'

######################################################################
#### Load Vertex and Fragment shaders from files and compile them ####
######################################################################
def compile_link_shaders(params = {})
  vertex_shader_path = params.fetch(:vertex_shader, '')
  fragment_shader_path = params.fetch(:fragment_shader, '')
  gpu = params.fetch(:gpu, nil)
  gl_program_id = params.fetch(:gl_program_id, -1)

  shdr_vertex   = File.read(vertex_shader_path)
  shdr_fragment = File.read(fragment_shader_path)

  vertex_shader_id   = gpu.push_shader(Gl::GL_VERTEX_SHADER, shdr_vertex)
  fragment_shader_id = gpu.push_shader(Gl::GL_FRAGMENT_SHADER, shdr_fragment)

  Gl.glAttachShader(gl_program_id, vertex_shader_id)
  Gl.glAttachShader(gl_program_id, fragment_shader_id)

  Gl.glLinkProgram(gl_program_id)

  puts "vertex shader_log   = #{Gl.getShaderInfoLog(vertex_shader_id)}"
  puts "fragment shader_log = #{Gl.getShaderInfoLog(fragment_shader_id)}"
  puts "program_log         = #{Gl.getProgramInfoLog(gl_program_id)}"
end

######################################################################
#### Prep X Window
######################################################################
def sdl_context(args)
  defaults = {x: 0, y: 0, w: 1920, h: 1080}
  args = OpenStruct.new(defaults.merge(args))

  SDL2.init(SDL2::INIT_EVERYTHING)
  SDL2::GL.set_attribute(SDL2::GL::RED_SIZE, 8)
  SDL2::GL.set_attribute(SDL2::GL::GREEN_SIZE, 8)
  SDL2::GL.set_attribute(SDL2::GL::BLUE_SIZE, 8)
  SDL2::GL.set_attribute(SDL2::GL::ALPHA_SIZE, 8)
  SDL2::GL.set_attribute(SDL2::GL::DOUBLEBUFFER, 1)

  # For Antialiasing
  SDL2::GL.set_attribute(SDL2::GL::MULTISAMPLEBUFFERS, 1)
  SDL2::GL.set_attribute(SDL2::GL::MULTISAMPLESAMPLES, 2)

  gl_window = SDL2::Window.create(
    'testgl',
    args.x, args.y, args.w, args.h,
    SDL2::Window::Flags::OPENGL
  )

  SDL2::GL::Context.create(gl_window)

  return gl_window
end


