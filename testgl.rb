require 'sdl2'
#require 'gl'

require 'ostruct'

require "./util/Assert"
require "./util/debug"
require './util/gl_math_util'

require './shapes'
require './gl_input_tracker'
require './mesh'
require './gl_ffi'

require './gpu_driver'
require './cpu_graphic_object'

require 'stackprof'

require 'json'

require './oi_shapes'


include Gl

#StackProf.start(mode: :cpu, interval:100, raw: true)

SDL2.init(SDL2::INIT_EVERYTHING)
SDL2::GL.set_attribute(SDL2::GL::RED_SIZE, 8)
SDL2::GL.set_attribute(SDL2::GL::GREEN_SIZE, 8)
SDL2::GL.set_attribute(SDL2::GL::BLUE_SIZE, 8)
SDL2::GL.set_attribute(SDL2::GL::ALPHA_SIZE, 8)
SDL2::GL.set_attribute(SDL2::GL::DOUBLEBUFFER, 1)

# For Antialiasing
SDL2::GL.set_attribute(SDL2::GL::MULTISAMPLEBUFFERS, 1)
SDL2::GL.set_attribute(SDL2::GL::MULTISAMPLESAMPLES, 2)


ctx = OpenStruct.new

ctx.window = OpenStruct.new
ctx.window.aspect_ratio = 1920.0 / 1080.0
ctx.window.width = 1900
ctx.window.height= (ctx.window.width / ctx.window.aspect_ratio).to_i
ctx.window.x     = 0
ctx.window.y     = 1080 

puts "ctx = #{ctx}"

window  = SDL2::Window.create("testgl", ctx.window.x, ctx.window.y, ctx.window.width, ctx.window.height, SDL2::Window::Flags::OPENGL)

context = SDL2::GL::Context.create(window)

printf("OpenGL version %d.%d\n",
       SDL2::GL.get_attribute(SDL2::GL::CONTEXT_MAJOR_VERSION),
       SDL2::GL.get_attribute(SDL2::GL::CONTEXT_MINOR_VERSION))

Gl.viewport( 0, 0, ctx.window.width, ctx.window.height)

Gl.matrixMode( GL_PROJECTION )
Gl.loadIdentity( )

Gl.matrixMode( GL_MODELVIEW )
Gl.loadIdentity( )

#glEnable(GL_DEPTH_TEST)
Gl.enable(Gl::GL_DEPTH_TEST)

#glDepthFunc(GL_LESS)
Gl.depthFunc(Gl::GL_LESS)

Gl.shadeModel(Gl::GL_SMOOTH)
#Gl.shadeModel(Gl::GL_FLAT)



ctx.camera = Camera.new(aspect_ratio: ctx.window.aspect_ratio)

input_tracker = InputTracker.new(ctx.camera, ctx.window.width, ctx.window.height)

gpu = Gpu.new()

##################################################################
##### Load Vertex and Fragment shaders from files and compile them
#
ctx.program_id      = Gl.glCreateProgram()

shdr_vertex   = File.read("./shdr_vertex_basic.c")
shdr_fragment = File.read("./shdr_frag_ads_sh.c")

ctx.vertex_shader_id   = gpu.push_shader(Gl::GL_VERTEX_SHADER, shdr_vertex)
ctx.fragment_shader_id = gpu.push_shader(Gl::GL_FRAGMENT_SHADER, shdr_fragment)


Gl.glAttachShader(ctx.program_id, ctx.vertex_shader_id)
Gl.glAttachShader(ctx.program_id, ctx.fragment_shader_id)

Gl.glLinkProgram(ctx.program_id)
Gl.glUseProgram(ctx.program_id)


puts "vertex shader_log   = #{Gl.getShaderInfoLog(ctx.vertex_shader_id)}"
puts "fragment shader_log = #{Gl.getShaderInfoLog(ctx.fragment_shader_id)}"
puts "program_log         = #{Gl.getProgramInfoLog(ctx.program_id)}"


##################################################################
###### Load objects
#
cpu_graphic_objects = []


#cpu_graphic_objects << GL_Shapes.file("/home/cventeic/teapot.obj")

#10.times do 
5.times do 
  length = rand(1.0..7.0)
  base_radius = rand(0.1..2.0)
  top_radius = rand(0.1..2.0)

  vec = rand_vector_in_box()


  cpu_graphic_objects <<  Cpu_Graphic_Object.new(
    internal_proc: lambda { |named_arguments| named_arguments[:mesh] = GL_Shapes.cylinder(f_length: length, base_radius: base_radius, top_radius: top_radius) },
    external_proc: lambda { |named_arguments| },
    model_matrix: Geo3d::Matrix.translation(vec.x, vec.y, vec.z),
    color: Geo3d::Vector.new( 1.0, 0.1, 0.1, 1.0)
  )
end

5.times do 
  radius = rand(0.5..2.0)

  vec = rand_vector_in_box()

  cpu_graphic_objects <<  Cpu_Graphic_Object.new(
    internal_proc: lambda { |named_arguments| named_arguments[:mesh] = GL_Shapes.sphere(radius) },
    external_proc: lambda { |named_arguments| },
    model_matrix: Geo3d::Matrix.translation(vec.x, vec.y, vec.z),
    #color: Geo3d::Vector.new( 1.0, 1.0, 1.0, 1.0)
    color: Geo3d::Vector.new( ((vec.x+10.0)/40.0)+0.5, ((vec.y+10.0)/40.0)+0.5, ((vec.z+10.0)/40.0)+0.5, 1.0)
  )
end

if false 
  # wire_box
  cpu_graphic_objects <<  Cpu_Graphic_Object.new(
    internal_proc: lambda { |named_arguments| named_arguments[:mesh] = GL_Shapes.box_wire() },
    external_proc: lambda { |named_arguments| },
    model_matrix: Geo3d::Matrix.translation(0.0, 0.0, 0.0),
    color: Geo3d::Vector.new( 0.8, 0.0, 0.0, 1.0)
  )
end


if true 
  #/todo make this match actual light position
  # show light 
  cpu_graphic_objects <<  Cpu_Graphic_Object.new(
    internal_proc: lambda { |named_arguments| named_arguments[:mesh] = GL_Shapes.cylinder(f_length: 3.0, base_radius: 3.0) },
    external_proc: lambda { |named_arguments| },
    # model_matrix: (Geo3d::Matrix.rotation_y(radians(180.0)) * Geo3d::Matrix.translation(0.0, 0.0, 20.0)),
    model_matrix: (Geo3d::Matrix.translation(0.0, 0.0, 20.0)),
    color: Geo3d::Vector.new( 1.0, 1.0, 1.0, 1.0) 
  )
end

if false 
  # show arrow 
  cpu_graphic_objects <<  Cpu_Graphic_Object.new(
    internal_proc: lambda { |named_arguments| named_arguments[:mesh] = GL_Shapes.arrow(
      Geo3d::Vector.new(0.0, 0.0, 0.0), 
      Geo3d::Vector.new(-5.0, 5.0, 0.0),
      0.1) },
      external_proc: lambda { |named_arguments| },
      model_matrix: (Geo3d::Matrix.identity()),
      color: Geo3d::Vector.new( 0.0, 0.0, 1.0, 1.0) 
  )
end

if false 
  # show line
  cpu_graphic_objects <<  Cpu_Graphic_Object.new(
    internal_proc: lambda { |named_arguments| named_arguments[:mesh] = GL_Shapes.line(
      Geo3d::Vector.new(0.0, 0.0, 0.0), 
      Geo3d::Vector.new(5.0, 5.0, 0.0),
      3.1) },
      external_proc: lambda { |named_arguments| },
      model_matrix: (Geo3d::Matrix.identity()),
      color: Geo3d::Vector.new( 0.0, 1.0, 0.0, 1.0) 
  )
end

cpu_graphic_objects += (GL_Shapes.axis_arrows)

if true 
  # Draw 5 connected line segments to random locations in box

  points = 10.times.map {rand_vector_in_box()}

  points.each_cons(2) do |p0,p1|

    # show line
    cpu_graphic_objects <<  Cpu_Graphic_Object.new(
      #internal_proc: lambda { |named_arguments| named_arguments[:mesh] = GL_Shapes.directional_cylinder( p0, p1)},
      internal_proc: lambda { |named_arguments| named_arguments[:mesh] = GL_Shapes.arrow( p0, p1, 0.05)},
      external_proc: lambda { |named_arguments| },
      model_matrix: (Geo3d::Matrix.identity()),
      color: Geo3d::Vector.new( 0.0, 1.0, 0.0, 1.0) 
    )
  end
end

if true 
  # Draw 5 connected line segments to random locations in box

  #points = 71.times.map {rand_vector_in_box()}
  #points = 10.times.map {rand_vector_in_box()}
  points = 200.times.map {rand_vector_in_box()}

  points.each_cons(2) do |p0,p1|

    # show line
    cpu_graphic_objects <<  Cpu_Graphic_Object.new(
      internal_proc: lambda { |named_arguments| 
        oi = OI.directional_cylinder(start: p0, stop: p1)
        state = oi.render
        mesh = state[:mesh]
        named_arguments[:mesh] = mesh 
      },
      external_proc: lambda { |named_arguments| },
      model_matrix: (Geo3d::Matrix.identity()),
      color: Geo3d::Vector.new( 0.0, 1.0, 0.0, 1.0) 
    )
  end
end


cpu_graphic_objects <<  Cpu_Graphic_Object.new(
  internal_proc: lambda { |named_arguments| 
    oi = OI.box_wire()
    state = oi.render
    mesh = state[:mesh]
    named_arguments[:mesh] = mesh 
  },
  external_proc: lambda { |named_arguments| },
  model_matrix: (Geo3d::Matrix.identity()),
  color: Geo3d::Vector.new( 0.0, 0.0, 1.0, 1.0) 
)

0.times do 
  cpu_graphic_objects <<  Cpu_Graphic_Object.new(
    internal_proc: lambda { |named_arguments| 
      oi = OI.cube_corner_spheres()
      state = oi.render
      mesh = state[:mesh]
      named_arguments[:mesh] = mesh 
    },
    external_proc: lambda { |named_arguments| },
    model_matrix: (Geo3d::Matrix.identity()),
    color: Geo3d::Vector.new( 0.0, 0.0, 1.0, 1.0) 
  )
end



#############

object_count = 1
gpu_obj_ids = cpu_graphic_objects.map do |object|
  #puts "pushing object #{object_count} to gpu"
  #object_count += 1
  id = gpu.push_cpu_graphic_object(ctx.program_id, object)
end

# /todo pass in light data
gpu.update_lights(ctx.program_id)

#StackProf.stop
#StackProf.results('./stackprof.dump')

#############
#

state = SDL2::Mouse.state
input_tracker.cursor_position_callback(0,state.x,state.y)


loop do

  while event = SDL2::Event.poll
    case event

    when SDL2::Event::KeyDown
      ev = event
      puts "scancode: #{ev.scancode}(#{SDL2::Key::Scan.name_of(ev.scancode)})"
      puts "keycode: #{ev.sym}(#{SDL2::Key.name_of(ev.sym)})"
      puts "mod: #{ev.mod}"
      puts "mod(SDL2::Key::Mod.state): #{SDL2::Key::Mod.state}"

      camera_translation = Geo3d::Matrix.identity

      case ev.mod
      when 0
        case ev.sym
        when SDL2::Key::LEFT
          camera_translation = Geo3d::Matrix.translation(-5.0, 0.0, 0.0)
        when SDL2::Key::RIGHT
          camera_translation = Geo3d::Matrix.translation(+5.0, 0.0, 0.0)
        when SDL2::Key::UP
          camera_translation = Geo3d::Matrix.translation(0.0, 5.0, 0.0)
        when SDL2::Key::DOWN
          camera_translation = Geo3d::Matrix.translation(0.0, -5.0, 0.0)
        end
 
      when 64 # L control
        case ev.sym
        when SDL2::Key::UP
          camera_translation = Geo3d::Matrix.translation(0.0, 0.0, 5.0)
        when SDL2::Key::DOWN
          camera_translation = Geo3d::Matrix.translation(0.0, 0.0, -5.0)
        end

      when 256 # L Alt
        case ev.sym
        when SDL2::Key::LEFT
          camera_translation = Geo3d::Matrix.translation(-5.0, 0.0, 0.0)
        when SDL2::Key::RIGHT
          camera_translation = Geo3d::Matrix.translation(+5.0, 0.0, 0.0)
        when SDL2::Key::UP
          camera_translation = Geo3d::Matrix.translation(0.0, 5.0, 0.0)
        when SDL2::Key::DOWN
          camera_translation = Geo3d::Matrix.translation(0.0, -5.0, 0.0)
        end
      end

      #when Glfw::KEY_X then @arc_ball.select_axis(X)
      #when Glfw::KEY_Y then @arc_ball.select_axis(Y)
      #when Glfw::KEY_Z then @arc_ball.select_axis(Z)


      ctx.camera.move_camera_in_camera_space(camera_translation)
      gpu.update_camera_view(ctx.program_id, ctx.camera)


    #when SDL2::Event::Quit, SDL2::Event::KeyDown
    when SDL2::Event::Quit
      exit

    when SDL2::Event::MouseButtonUp
      input_tracker.button_release()

    when SDL2::Event::MouseButtonDown
      input_tracker.button_press()

    when SDL2::Event::MouseMotion
      input_tracker.cursor_position_callback(0,event.x,event.y)
    end
  end

  check_for_gl_error()

  Gl.glClearColor(0.0, 0.0, 0.0, 1.0);
  Gl.glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

  #### Move camera if input changed
  #
  if input_tracker.updated?  || (ctx.camera != input_tracker.camera)
    ctx.camera = input_tracker.update_camera(ctx.camera)
    gpu.update_camera_view(ctx.program_id, ctx.camera)
  end

  #### Draw / Update objects
  #
  gpu_obj_ids.each do |obj_id|
    gpu.render_object(obj_id)
  end

  window.gl_swap

  # break if window.should_close?

  input_tracker.end_frame
end
