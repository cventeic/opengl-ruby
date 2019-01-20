require 'ostruct'

class RenderContext
  attr_accessor :window, :camera, :camera_last_render, :gl_program_ids

  def initialize(params = {})
    @window = params.fetch(:window, OpenStruct.new)
    @camera = params.fetch(:camera,
                           Camera.new(aspect_ratio: @window.aspect_ratio))
    @gl_program_ids = params.fetch(:gl_program_ids, -1)
    @camera_last_render = nil
  end

end
