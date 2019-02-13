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

######################################################################
#### Prep OpenGL
######################################################################
def prep_opengl(args)
  defaults = {x: 0, y:0, w: 1920, h: 1080}
  args = OpenStruct.new(defaults.merge(args))

  printf("OpenGL version %d.%d\n",
         SDL2::GL.get_attribute(SDL2::GL::CONTEXT_MAJOR_VERSION),
         SDL2::GL.get_attribute(SDL2::GL::CONTEXT_MINOR_VERSION))

  Gl.viewport(0, 0, args.w, args.h)

  Gl.matrixMode(GL_PROJECTION)
  Gl.loadIdentity

  Gl.matrixMode(GL_MODELVIEW)
  Gl.loadIdentity

  Gl.enable(Gl::GL_DEPTH_TEST)
  Gl.depthFunc(Gl::GL_LESS)
  Gl.shadeModel(Gl::GL_SMOOTH)
end


def key_to_camera_translation(ev)
  puts
  puts "scancode: #{ev.scancode}(#{SDL2::Key::Scan.name_of(ev.scancode)})"
  puts "keycode: #{ev.sym}(#{SDL2::Key.name_of(ev.sym)})"
  puts "mod: #{ev.mod}"
  puts "mod(SDL2::Key::Mod.state): #{SDL2::Key::Mod.state}"

  camera_translation = Geo3d::Matrix.identity

  case ev.mod
  when SDL2::Key::Mod::NONE, 4096
    case ev.sym
    when SDL2::Key::LEFT
      puts "L"
      camera_translation = Geo3d::Matrix.translation(-5.0, 0.0, 0.0)
    when SDL2::Key::RIGHT
      puts "R"
      camera_translation = Geo3d::Matrix.translation(+5.0, 0.0, 0.0)
    when SDL2::Key::UP
      puts "U"
      camera_translation = Geo3d::Matrix.translation(0.0, 5.0, 0.0)
    when SDL2::Key::DOWN
      puts "D"
      camera_translation = Geo3d::Matrix.translation(0.0, -5.0, 0.0)
    end

  when 64,4160 # L control
    case ev.sym
    when SDL2::Key::UP
      puts "Ctrl U"
      camera_translation = Geo3d::Matrix.translation(0.0, 0.0, 5.0)
    when SDL2::Key::DOWN
      puts "Ctrl D"
      camera_translation = Geo3d::Matrix.translation(0.0, 0.0, -5.0)
    end

  when 256,4352 # L Alt
    case ev.sym
    when SDL2::Key::LEFT
      puts "Alt L"
      camera_translation = Geo3d::Matrix.translation(-5.0, 0.0, 0.0)
    when SDL2::Key::RIGHT
      puts "Alt R"
      camera_translation = Geo3d::Matrix.translation(+5.0, 0.0, 0.0)
    when SDL2::Key::UP
      puts "Alt U"
      camera_translation = Geo3d::Matrix.translation(0.0, 5.0, 0.0)
    when SDL2::Key::DOWN
      puts "Alt D"
      camera_translation = Geo3d::Matrix.translation(0.0, -5.0, 0.0)
    end
  end

  return camera_translation
end



