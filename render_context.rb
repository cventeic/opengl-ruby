require 'ostruct'

class RenderContext
  attr_accessor :window, :camera, :gl_program_id, :vertex_shader_id, :fragment_shader_id

  def initialize(params = {})
    @window = params.fetch(:window, OpenStruct.new)
    @camera = params.fetch(:camera,
                           Camera.new(aspect_ratio: @window.aspect_ratio))
    @gl_program_id = params.fetch(:gl_program_id, -1)
    @vertex_shader_id = params.fetch(:vertex_shader_id, -1)
    @fragment_shader_id = params.fetch(:fragment_shader_id, -1)
  end

end
