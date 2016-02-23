require 'sdl2'
require 'gl'

require 'ostruct'

require "./util/Assert"
require './util/gl_math_util'

require './shapes'
require './gl_input_tracker'
require './mesh'
#require './gl_ffi'

require './gpu_driver'
require './cpu_graphic_object'

require 'stackprof'


include Gl

StackProf.start(mode: :cpu, interval:100, raw: true)

scale = 1.0
aspect_ratio = 1.0 / 1.0
WINDOW_W = 1600.0 * scale # 640
WINDOW_H = WINDOW_W * aspect_ratio # 480

SDL2.init(SDL2::INIT_EVERYTHING)
SDL2::GL.set_attribute(SDL2::GL::RED_SIZE, 8)
SDL2::GL.set_attribute(SDL2::GL::GREEN_SIZE, 8)
SDL2::GL.set_attribute(SDL2::GL::BLUE_SIZE, 8)
SDL2::GL.set_attribute(SDL2::GL::ALPHA_SIZE, 8)
SDL2::GL.set_attribute(SDL2::GL::DOUBLEBUFFER, 1)

# For Antialiasing
SDL2::GL.set_attribute(SDL2::GL::MULTISAMPLEBUFFERS, 1)
SDL2::GL.set_attribute(SDL2::GL::MULTISAMPLESAMPLES, 2)


window  = SDL2::Window.create("testgl", 0, 0, WINDOW_W, WINDOW_H, SDL2::Window::Flags::OPENGL)
context = SDL2::GL::Context.create(window)

printf("OpenGL version %d.%d\n",
       SDL2::GL.get_attribute(SDL2::GL::CONTEXT_MAJOR_VERSION),
       SDL2::GL.get_attribute(SDL2::GL::CONTEXT_MINOR_VERSION))

glViewport( 0, 0, WINDOW_W, WINDOW_H)
glMatrixMode( GL_PROJECTION )
glLoadIdentity( )

glMatrixMode( GL_MODELVIEW )
glLoadIdentity( )

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

glShadeModel(GL_SMOOTH)



ctx = OpenStruct.new

input_tracker = InputTracker.new(WINDOW_W, WINDOW_H)

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
    internal_proc: lambda { |named_arguments| named_arguments[:mesh] = GL_Shapes.cylinder(length, base_radius, top_radius) },
    external_proc: lambda { |named_arguments| },
    model_matrix: Geo3d::Matrix.translation(vec.x, vec.y, vec.z),
    color: Geo3d::Vector.new( 1.0, 0.1, 0.1, 1.0)
  )
end

#10.times do 
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

if true 
  # wire_box
  cpu_graphic_objects <<  Cpu_Graphic_Object.new(
    internal_proc: lambda { |named_arguments| named_arguments[:mesh] = GL_Shapes.box_wire() },
    external_proc: lambda { |named_arguments| },
    model_matrix: Geo3d::Matrix.translation(0.0, 0.0, 0.0),
    color: Geo3d::Vector.new( 0.8, 0.0, 0.0, 1.0)
  )
end


if false 
  radius = 10.0
  cpu_graphic_objects <<  Cpu_Graphic_Object.new(
    internal_proc: lambda { |named_arguments| named_arguments[:mesh] = GL_Shapes.sphere(radius) },
    external_proc: lambda { |named_arguments| },
    model_matrix: Geo3d::Matrix.translation(0.0, 0.0, 0.0),
    color: Geo3d::Vector.new( 0.8, 1.0, 1.0, 1.0)
  )
end

if true 
  #/todo make this match actual light position
  # show light 
  cpu_graphic_objects <<  Cpu_Graphic_Object.new(
    internal_proc: lambda { |named_arguments| named_arguments[:mesh] = GL_Shapes.cylinder(3.0, 3.0, 0.1) },
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

  points = 50.times.map {rand_vector_in_box()}

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



#############


gpu_obj_ids = cpu_graphic_objects.map do |object|
  gpu.push_cpu_graphic_object(ctx.program_id, object)
end

# /todo pass in light data
gpu.update_lights(ctx.program_id)

StackProf.stop
StackProf.results('./stackprof.dump')

#############
#

state = SDL2::Mouse.state
input_tracker.cursor_position_callback(0,state.x,state.y)

loop do

  while event = SDL2::Event.poll
    case event
    when SDL2::Event::Quit, SDL2::Event::KeyDown
      exit

    when SDL2::Event::MouseButtonUp
      input_tracker.button_release()

    when SDL2::Event::MouseButtonDown
      input_tracker.button_press()

    when SDL2::Event::MouseMotion
      input_tracker.cursor_position_callback(0,event.x,event.y)
    end
  end

  error = Gl.getError()  # Flush any errors
  error = Gl.getError()

  glClearColor(0.0, 0.0, 0.0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

  error = Gl.getError()  # Flush any errors
  error = Gl.getError()

  #### Move camera if input changed
  #
  if input_tracker.updated?
    camera = input_tracker.camera

    gpu.update_camera_view(ctx.program_id, camera)
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
