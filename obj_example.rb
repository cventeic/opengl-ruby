require 'glfw3'
#require 'opengl-core'
require 'wavefront'
require 'geo3d'
require "awesome_print"

require "./util/Assert"
require './util/gl_math_util'
require './shapes'
require './gl_input_tracker'
require './mesh'
require './gpu_shader_code'
require './gl_ffi'

require './gpu_driver'

require 'ostruct'

#include GL

class Cpu_Graphic_Object
  attr_accessor :mesh

  def initialize(mesh=nil)
    @mesh = mesh
    @translation = nil
  end
end

#############

class Uniforms
  def initialize
    @uniform_locations = {}
  end

  # to do cache on program_id too
  def uniform_location(program_id, name)
    uniform_sym = name.to_sym
    locations = @uniform_locations
    locations[uniform_sym] ||= Gl.getUniformLocation(program_id, name.to_s)
  end

  alias_method :[], :uniform_location
end



def set_matrix_data(program_id, uniformsLocationCache, uniform_name, data)
  location = uniformsLocationCache.uniform_location(program_id, uniform_name)
  d = data.to_a.flatten.pack("f*")
  Gl.uniformMatrix4fv(location, 1, Gl::GL_FALSE, d)
end

def set_vector_data(program_id, uniformsLocationCache, uniform_name, data)
  location = uniformsLocationCache.uniform_location(program_id, uniform_name)
  d = data.pack("f*")
  Gl.uniform4fv(location, 1, d)
end

def update_camera_view(program_id, uniformsLocationsCache, camera)
  #view_delta      = @input_tracker.get_permenent_view_change_matrix
  #view_delta_tmp  = @input_tracker.get_temp_view_change_matrix

  #camera_view = camera.view * view_delta
  #view        = camera_view * view_delta_tmp
  #mvp         = camera.perspective * camera.view * camera.model
  #proj        = camera.perspective

  set_matrix_data(program_id, uniformsLocationsCache, :MVP, camera.mvp)
  set_matrix_data(program_id, uniformsLocationsCache, :V, camera.view)
  set_matrix_data(program_id, uniformsLocationsCache, :M, camera.model)

  vLight = [4,4,4]
  set_vector_data(program_id, uniformsLocationsCache, :LightPosition_worldspace, vLight)
end









# See for description of matrix
# http://www.songho.ca/opengl/gl_transform.html

#######################################################

def register_glfw_callbacks(window, input_tracker)
  #### Callbacks
  window.set_cursor_position_callback do |win, x, y|
    input_tracker.cursor_position_callback(win,x,y)
  end

  window.set_mouse_button_callback do |win, button, action, mods|
    input_tracker.button_callback(win,button,action,mods)
  end

  window.set_key_callback do |win, key, code, action, mods|
    window.should_close = true if key == Glfw::KEY_ESCAPE
    input_tracker.key_callback(win,key,code,action,mods)
  end

  window.set_close_callback do |win|
    window.should_close = true
  end

  window.set_focus_callback do |win, focused|
    window.focus_callback = nil

    # GLFW_CURSOR_NORMAL makes the cursor visible and behaving normally.
    # GLFW_CURSOR_HIDDEN makes the cursor invisible when it is over the client area of the window but does not restrict the cursor from leaving. This is useful if you wish to render your own cursor or have no visible cursor at all.
    # GLFW_CURSOR_DISABLED hides and grabs the cursor, providing virtual and unlimited cursor movement. This is useful for implementing for example 3D camera controls
    #window.set_input_mode Glfw::CURSOR, Glfw::CURSOR_DISABLED
    window.set_input_mode Glfw::CURSOR, Glfw::CURSOR_NORMAL
  end
end

#######################################################

ctx = OpenStruct.new

width, height = 1000,1000

Glfw.init

window        = Glfw::Window.new(width, height, "Foobar")
input_tracker = InputTracker.new(width, height)

register_glfw_callbacks(window, input_tracker)

window.make_context_current

Gl.enable(Gl::GL_DEPTH_TEST)
Gl.enable(Gl::GL_CULL_FACE) # Cull triangles which normal is not towards the camera


##################################################################
##### Load Vertex and Fragment shaders from files and compile them
#
ctx.program_id      = Gl.glCreateProgram()

def vglShaderSource(shader, sources)
  sources = [sources] unless sources.kind_of?(Array)
  source_lengths = sources.map { |s| s.bytesize }.pack('i*')
  source_pointers = sources.pack('p')
  Gl.shaderSource(shader, sources.length, source_pointers, source_lengths)
end

# todo raise info if compile fails

ctx.vertex_shader_id = Gl.glCreateShader(Gl::GL_VERTEX_SHADER)
vglShaderSource(ctx.vertex_shader_id, getShaderCodeVertex)
Gl.compileShader(ctx.vertex_shader_id)

ctx.fragment_shader_id = Gl.glCreateShader(Gl::GL_FRAGMENT_SHADER)
vglShaderSource(ctx.fragment_shader_id, getShaderCodeFragment)
Gl.compileShader(ctx.fragment_shader_id)


Gl.glAttachShader(ctx.program_id, ctx.vertex_shader_id)
Gl.glAttachShader(ctx.program_id, ctx.fragment_shader_id)

Gl.glLinkProgram(ctx.program_id)
Gl.glUseProgram(ctx.program_id)

##################################################################
###### Load objects
#


cpu_graphic_objects = []

#cpu_graphic_objects << GL_Shapes.file("/home/cventeic/teapot.obj")

5.times do 
  length = rand(6).to_f
  mesh = GL_Shapes.cylinder(0.1, 0.1, length)
  mesh.translate!(Geo3d::Vector.new(rand(20)-10, rand(20)-10, rand(20)-10))

  # This loads the vertex, normal, texcoord, index from mesh into independent
  # buffers assocated with the VAO
  go = Cpu_Graphic_Object.new(mesh)

  cpu_graphic_objects << go
end

4.times do 
  radius = rand(1) + 2
  mesh = GL_Shapes.sphere(radius.to_f, 12, 12)
  mesh.translate!(Geo3d::Vector.new(rand(20)-10, rand(20)-10, rand(20)-10))

  go = Cpu_Graphic_Object.new(mesh)

  cpu_graphic_objects << go
end

mesh = GL_Shapes.sphere(1.to_f, 12, 12)
go = Cpu_Graphic_Object.new(mesh)
cpu_graphic_objects << go



#############

gpu = Gpu.new()

gpu_obj_ids = cpu_graphic_objects.map do |object|
  gpu.push_cpu_graphic_object(ctx.program_id, object)
end


#############
#

ctx.ulc = Uniforms.new()

loop {
  Glfw.wait_events

  #### Move camera if input changed
  #
  if input_tracker.updated?
    camera = input_tracker.camera
    update_camera_view(ctx.program_id, ctx.ulc, camera)
  end

  #### Draw / Update objects
  #
  Gl.clear(Gl::GL_COLOR_BUFFER_BIT | Gl::GL_DEPTH_BUFFER_BIT | Gl::GL_STENCIL_BUFFER_BIT)

  gpu_obj_ids.each do |obj_id|
    gpu.render_object(obj_id)
  end

  window.swap_buffers

  break if window.should_close?

  input_tracker.end_frame
}

window.destroy # Explicitly destroy the window when done with it.


