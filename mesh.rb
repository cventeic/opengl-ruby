
##############################################
class Mesh
  attr_accessor :position, :normal, :tex, :index

  def initialize()
    @position = Array.new
    @index    = Array.new
    @normal   = Array.new
    @tex      = Array.new
  end

  def translate!(vector)
    @position.map! do |p|
      ap p
      pp = Geo3d::Vector.new(p[0], p[1], p[2])
      pp += vector
      out = pp.to_a
    end
    @position
  end

  def clamp_range(array)
    array.map! do |v|
      v.map { |d| close_enough(d, 0.0) ? 0.0: d } 
    end
  end

  def clamp_ranges
    @position = clamp_range(@position) unless @position.nil?
    @normal   = clamp_range(@normal) unless @normal.nil?
    #@tex      << t
  end

  def load_wavefront(filename)
    puts "load_wavefront(#{filename})"
    w = Wavefront::File.new filename
    mesh = w.compute_vertex_and_index_buffer

    @position = mesh[:vertex_buffer].map {|v| q=v.position; [q.x, q.y, q.z] }
    @normal   = mesh[:vertex_buffer].map {|v| q=v.normal;   q.nil? ? q : [q.x, q.y, q.z]}
    @tex      = mesh[:vertex_buffer].map {|v| v.nil? ? v : [v.tex]}
    @index    = mesh[:index_buffer].map {|i| [i]}
  end

end


