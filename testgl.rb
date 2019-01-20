require 'sdl2'
require 'color-generator'

require 'ostruct'

require './render_context'
require './util/Assert'
require './util/debug'
require './util/gl_math_util'

require './shapes'
require './gl_input_tracker'
require './mesh'
require './gl_ffi'

require './gpu_driver'
require './cpu_graphic_object'

require 'stackprof'

require './oi_shapes'

require 'awesome_print'

include Gl

@color_generator = ColorGenerator.new saturation: 0.3, lightness: 0.75

def new_color
  r, g, b = @color_generator.create_rgb.map { |c| c.to_f / 255.0 }

  assert { r >= 0.0 && r <= 1.0 }

  color = Geo3d::Vector.new(r, g, b, 1.0)

  color
end

######################################################################
###### Load objects
######################################################################

=begin
def load_objects(gpu, ctx)
  cpu_graphic_objects = []

  if true
    # /todo make this match actual light position
    # show light
    cpu_graphic_objects << Cpu_Graphic_Object.new(
      internal_proc: lambda { |named_arguments|
        named_arguments[:mesh] = GL_Shapes.cylinder(f_length: 3.0,
                                                    base_radius: 3.0)
      },
      model_matrix: Geo3d::Matrix.translation(0.0, 0.0, 20.0),
      color: Geo3d::Vector.new(1.0, 1.0, 1.0, 1.0)
    )
  end

  # cpu_graphic_objects << GL_Shapes.file("/home/cventeic/teapot.obj")

  cpu_graphic_objects += GL_Shapes.axis_arrows

  ####################
  # Draw random cylinders
  points = 5.times.map { rand_vector_in_box }
  points.each do |vec|
    length      = rand(1.0..7.0)
    base_radius = rand(0.1..2.0)
    top_radius  = rand(0.1..2.0)

    cpu_graphic_objects << Cpu_Graphic_Object.new(
      mesh: GL_Shapes.cylinder(f_length: length,
                               base_radius: base_radius,
                               top_radius: top_radius),
      # internal_proc: lambda { |named_arguments| named_arguments[:mesh] =
      #   GL_Shapes.cylinder(f_length: length,
      #                      base_radius: base_radius,
      #                      top_radius: top_radius) },
      model_matrix: Geo3d::Matrix.translation(vec.x, vec.y, vec.z),
      color: new_color
    )
  end

  ####################
  # Draw random spheres
  points = 5.times.map { rand_vector_in_box }
  points.each do |vec|
    radius = rand(0.5..2.0)

    cpu_graphic_objects << Cpu_Graphic_Object.new(
      # internal_proc: lambda { |named_arguments| named_arguments[:mesh] =
      #                         GL_Shapes.sphere(radius) },
      mesh: GL_Shapes.sphere(radius),
      model_matrix: Geo3d::Matrix.translation(vec.x, vec.y, vec.z),
      # color: Geo3d::Vector.new( 1.0, 1.0, 1.0, 1.0)
      # color: Geo3d::Vector.new( ((vec.x+10.0)/40.0)+0.5,
      #                           ((vec.y+10.0)/40.0)+0.5,
      #                           ((vec.z+10.0)/40.0)+0.5, 1.0 )
      color: new_color
    )
  end

  #   ####################
  #   # Draw connected line segments to random locations in box
  #   points = 10.times.map {rand_vector_in_box()}
  #   points.each_cons(2) do |p0,p1|
  #     cpu_graphic_objects <<  Cpu_Graphic_Object.new(
  #       # internal_proc: lambda { |named_arguments| named_arguments[:mesh] =
  #                                 GL_Shapes.arrow( p0, p1, 0.05)},
  #       mesh: GL_Shapes.arrow( p0, p1, 0.05 ),
  #       #color: Geo3d::Vector.new( 0.0, 1.0, 0.0, 1.0)
  #       color: new_color()
  #     )
  #   end

  ######################################################################
  #### Push objects to GPU
  ######################################################################

  # object_count = 1

  gpu_mesh_jobs = cpu_graphic_objects.map do |cpu_graphic_object|
    # puts "pushing object #{object_count} to gpu"
    # object_count += 1

    # Render the object in object space
    cpu_graphic_object.internal

    # Position the object in world space
    # cpu_graphic_object.external()

    gpu_mesh_job = GPU_Mesh_Job.new(
      model_matrix: cpu_graphic_object.model_matrix,
      color: cpu_graphic_object.color,
      mesh: cpu_graphic_object.mesh,
      gl_program_id: ctx.gl_program_id
    )

    gpu.push_mesh_job_to_gpu(gpu_mesh_job)

    gpu_mesh_job
  end

  gpu_mesh_jobs
end
=end

def load_objects_using_oi(gpu, gl_program_id)
  cpu_g_objs = []
  # cpu_g_objs << Cpu_G_Obj_Job.box_wire()

  ####################
  # Draw 5 connected line segments to random locations in box
  points = 10.times.map { rand_vector_in_box }

  points.each_cons(2) do |p0, p1|
    cpu_g_objs << Cpu_G_Obj_Job.directional_cylinder_aa(start: p0, stop: p1,
                                                        color: new_color)
  end

  ####################
  # Create a single job to render meshes
  #   for a set of multiple arrows between points

  meta_object = Cpu_G_Obj_Job.new

  points = 50.times.map { rand_vector_in_box }

  points.each_cons(2) do |p0, p1|
    new_c = new_color

    # Define a sub-job to render arrow between two points
    #
    arrow_obj = Cpu_G_Obj_Job.arrow(start: p0, stop: p1, color: new_c)

    # Add the sub-job to the meta-job to render all the arrows
    meta_object.add(
      symbol: :a_color,

      computes: {
        sub_ctx_ingress: ->(sup_ctx_in) { sub_ctx_in = sup_ctx_in },

        sub_ctx_render: lambda { |_sub_ctx_in|
          objs = arrow_obj.render

          sub_ctx_out = {
            gpu_objs: [{
              # mesh: GL_Shapes.directional_cylinder(args.merge(sub_ctx_in)),
              mesh: GL_Shapes.directional_cylinder(start: p0, stop: p1,
                                                   color: new_c),
              color: new_c
              # mesh: arrow_obj.render
              # color: args[:color]
            }]

          }
        },

        sub_ctx_egress: lambda { |sup_ctx_in, sub_ctx_out|
          Cpu_G_Obj_Job.std_join_ctx(sup_ctx_in, sub_ctx_out)
        }
      }
    )
  end

  cpu_g_objs << meta_object

  ####################
  ####################
  ####################

  gpu_mesh_jobs = []

  cpu_g_objs.each do |cpu_g_obj|
    # puts "pushing cpu_obj #{object_count} to gpu"
    # object_count += 1

    objs = cpu_g_obj.render

    objs[:gpu_objs].each do |obj|
      mesh = obj[:mesh]
      color = obj[:color]

      gpu_mesh_job = GPU_Mesh_Job.new(
        model_matrix: Geo3d::Matrix.identity,
        color: color,
        mesh: mesh,
        gl_program_id: gl_program_id
      )

      gpu.push_mesh_job_to_gpu(gpu_mesh_job)

      gpu_mesh_jobs << gpu_mesh_job
    end
  end

  gpu_mesh_jobs
end

StackProf.start(mode: :cpu, interval: 100, raw: true)

######################################################################
#### Initialize Configuration Structure, Prep Camera
######################################################################
window = OpenStruct.new
window.aspect_ratio = 1920.0 / 1080.0
window.width = 1900
window.height = (window.width / window.aspect_ratio).to_i
window.x     = 0
window.y     = 0

camera = Camera.new(aspect_ratio: window.aspect_ratio)

ctx = RenderContext.new(camera: camera)
puts "ctx = #{ctx}"

######################################################################
#### Prep X Window
######################################################################

SDL2.init(SDL2::INIT_EVERYTHING)
SDL2::GL.set_attribute(SDL2::GL::RED_SIZE, 8)
SDL2::GL.set_attribute(SDL2::GL::GREEN_SIZE, 8)
SDL2::GL.set_attribute(SDL2::GL::BLUE_SIZE, 8)
SDL2::GL.set_attribute(SDL2::GL::ALPHA_SIZE, 8)
SDL2::GL.set_attribute(SDL2::GL::DOUBLEBUFFER, 1)

# For Antialiasing
SDL2::GL.set_attribute(SDL2::GL::MULTISAMPLEBUFFERS, 1)
SDL2::GL.set_attribute(SDL2::GL::MULTISAMPLESAMPLES, 2)

window.gl_window = SDL2::Window.create(
  'testgl',
  window.x, window.y,
  window.width, window.height,
  SDL2::Window::Flags::OPENGL
)

SDL2::GL::Context.create(window.gl_window)

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

gpu = Gpu.new

ctx.gl_program_ids = {}

ctx.gl_program_ids[:objects] = Gl.glCreateProgram

compile_link_shaders(
  gpu: gpu,
  gl_program_id: ctx.gl_program_ids[:objects],
  vertex_shader: './shdr_vertex_basic.c',
  fragment_shader: './shdr_frag_ads_sh.c'
)

ctx.gl_program_ids[:text] = Gl.glCreateProgram

compile_link_shaders(
  gpu: gpu,
  gl_program_id: ctx.gl_program_ids[:text],
  vertex_shader: './shdr_vertex_basic.c',
  fragment_shader: './shdr_frag_ads_sh.c'
)

program_groups = [:objects, :text]

######################################################################
###### Load objects
######################################################################

gpu_mesh_jobs = {}

gpu_mesh_jobs[:objects] = []
gpu_mesh_jobs[:objects] += load_objects_using_oi(gpu, ctx.gl_program_ids[:objects])

gpu_mesh_jobs[:text] = []
gpu_mesh_jobs[:text] += load_objects_using_oi(gpu, ctx.gl_program_ids[:text])


StackProf.stop
StackProf.results('./stackprof.dump')

puts
puts 'Loading Done'

######################################################################
#### Prep OpenGL
######################################################################

printf("OpenGL version %d.%d\n",
       SDL2::GL.get_attribute(SDL2::GL::CONTEXT_MAJOR_VERSION),
       SDL2::GL.get_attribute(SDL2::GL::CONTEXT_MINOR_VERSION))

Gl.viewport(0, 0, window.width, window.height)

Gl.matrixMode(GL_PROJECTION)
Gl.loadIdentity

Gl.matrixMode(GL_MODELVIEW)
Gl.loadIdentity

Gl.enable(Gl::GL_DEPTH_TEST)
Gl.depthFunc(Gl::GL_LESS)
Gl.shadeModel(Gl::GL_SMOOTH)

######################################################################
###### Load lights
######################################################################

# /todo pass in light data
program_groups.each do |pg|
  gpu.update_lights(ctx.gl_program_ids[pg])
end


######################################################################
#### Enter interactive loop
######################################################################

state = SDL2::Mouse.state

input_tracker = InputTracker.new(ctx.camera,
                                 window.width, window.height)

input_tracker.cursor_position_callback(0, state.x, state.y)

loop do
  while event = SDL2::Event.poll
    case event

    when SDL2::Event::KeyDown
      ev = event

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

      # when Glfw::KEY_X then @arc_ball.select_axis(X)
      # when Glfw::KEY_Y then @arc_ball.select_axis(Y)
      # when Glfw::KEY_Z then @arc_ball.select_axis(Z)

      ctx.camera.move_camera_in_camera_space(camera_translation)

      # end key down case

    # when SDL2::Event::Quit, SDL2::Event::KeyDown
    when SDL2::Event::Quit
      exit

    when SDL2::Event::MouseButtonUp
      input_tracker.button_release

    when SDL2::Event::MouseButtonDown
      input_tracker.button_press

    when SDL2::Event::MouseMotion
      input_tracker.cursor_position_callback(0, event.x, event.y)
    end
  end

  #### Move camera if input changed
  #
  ctx.camera = input_tracker.update_camera(ctx.camera) if input_tracker.updated?

  #### Render
  #
  check_for_gl_error

  Gl.glClearColor(0.0, 0.0, 0.0, 1.0)
  Gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

  program_groups.each do |pg|
    Gl.glUseProgram(ctx.gl_program_ids[pg]) # select the program for use

    gpu.update_camera_view(ctx.gl_program_ids[pg], ctx.camera) if ctx.camera != ctx.camera_last_render

    #### Draw / Update objects
    #
    gpu_mesh_jobs[pg].each do |job|
      gpu.render_object(job)
    end
  end

  window.gl_window.gl_swap

  # break if window.should_close?
  ctx.camera_last_render = ctx.camera.clone

  input_tracker.end_frame
end
