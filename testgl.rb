require 'sdl2'

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

require './aggregate_shapes'

require './app_common'

require 'awesome_print'

include Gl

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
      color: get_new_color
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
      color: get_new_color
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
  #       color: get_new_color()
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

def load_objects_using_aggregate(gpu, gl_program_id)
  cpu_g_objs = []
  # cpu_g_objs << Aggregate.box_wire()

  ####################
  # Draw 5 connected line segments to random locations in box
  points = 10.times.map { rand_vector_in_box }

  points.each_cons(2) do |p0, p1|
    cpu_g_objs << Aggregate.directional_cylinder(start: p0, stop: p1,
                                                        color: get_new_color)
  end

  ####################
  # Create a single job to render meshes
  #   for a set of multiple arrows between points

  meta_object = Aggregate.new

  points = 5.times.map { rand_vector_in_box }

  points.each_cons(2) do |p0, p1|
    new_c = get_new_color

    # Define a sub-job to render arrow between two points
    #
    arrow_obj = Aggregate.arrow(start: p0, stop: p1, color: new_c)

    # Add the sub-job to the meta-job to render all the arrows
    meta_object.add_element(
      symbol: :a_color,

      computes: {
        element_render: lambda { |_element_input_hash|
          objs = arrow_obj.render

          element_output_hash = {
            gpu_objs: [{
              # mesh: GL_Shapes.directional_cylinder(args.merge(element_input_hash)),
              mesh: GL_Shapes.directional_cylinder(start: p0, stop: p1,
                                                   color: new_c),
              color: new_c
              # mesh: arrow_obj.render
              # color: args[:color]
            }]

          }
        },
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

    objs.fetch(:gpu_objs,[]).each do |obj|
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

#### Prep X Window
window.gl_window = sdl_context(x: window.x, y: window.y, w: window.width, h: window.height)

gpu = Gpu.new

camera = Camera.new(aspect_ratio: window.aspect_ratio)

ctx = RenderContext.new(camera: camera)
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
  fragment_shader: './shdr_frag_font.c'
)

program_groups = [:objects, :text]

######################################################################
###### Load objects
######################################################################

gpu_mesh_jobs = {}

gpu_mesh_jobs[:objects] = []
gpu_mesh_jobs[:objects] += load_objects_using_aggregate(gpu, ctx.gl_program_ids[:objects])

gpu_mesh_jobs[:text] = []
gpu_mesh_jobs[:text] += load_objects_using_aggregate(gpu, ctx.gl_program_ids[:text])


StackProf.stop
StackProf.results('./stackprof.dump')

puts
puts 'Loading Done'

#### Prep OpenGL
prep_opengl(w: window.width, h: window.height)

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
  camera_translation = nil

  while event = SDL2::Event.poll
    case event
    when SDL2::Event::KeyDown
      camera_translation = key_to_camera_translation(event)

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

  #### Move camera based on input
  #
  ctx.camera.move_camera_in_camera_space(camera_translation) unless camera_translation.nil?
  ctx.camera = input_tracker.update_camera(ctx.camera) if input_tracker.updated?

  #### Render
  #

  #Gl.glClearColor(0.0, 0.0, 0.0, 1.0)
  Gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

  program_groups.each do |pg|
    Gl.glUseProgram(ctx.gl_program_ids[pg]) # select the program for use

    gpu.update_camera_view(ctx.gl_program_ids[pg], ctx.camera) if ctx.camera != ctx.camera_last_render

    #### Draw / Update objects
    #
    gpu_mesh_jobs[pg].each do |job|
      gpu.render_object(job)
    end

    check_for_gl_error(gl_program_id: ctx.gl_program_ids[pg])
  end

  window.gl_window.gl_swap

  # break if window.should_close?
  ctx.camera_last_render = ctx.camera.clone

  input_tracker.end_frame
end
