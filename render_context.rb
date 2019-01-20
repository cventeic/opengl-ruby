require 'ostruct'

class RenderContext
  attr_accessor :window, :camera, :camera_last_render, :gl_program_id

  def initialize(params = {})
    @window = params.fetch(:window, OpenStruct.new)
    @camera = params.fetch(:camera,
                           Camera.new(aspect_ratio: @window.aspect_ratio))
    @gl_program_id = params.fetch(:gl_program_id, -1)
    @camera_last_render = nil
  end

end
