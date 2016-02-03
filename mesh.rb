require "ap"


# Mesh has many triangles
#   triangles have 3 vertex_index specified with clockwise rotation
#
#     A vertex_index referes to a vertex
#
#     vertex have position, color, normal vector and texture coordinates
#       position has x, y, z
#       color    has r, g, b
#       normal   has x, y, z
#       texture  has x, y


class Point
  attr_accessor :vertex, :normal, :texcoord

  def initialize(vertex, normal, texcoord)
    @vertex = vertex
    @normal = normal
    @texcoord = texcoord
  end
end

##############################################
class Mesh
  attr_accessor :data_sets

  def initialize()
    @data_sets = Hash.new {|hash,key| hash[key] = Array.new}
  end

  def translate!(vector)
    @data_sets[:vertex].map! do |p|
      ap p
      pp = Geo3d::Vector.new(p[0], p[1], p[2])
      pp += vector
      out = pp.to_a
    end
    @data_sets[:vertex]
  end

  def clamp_range(array)
    array.map! do |v|
      v.map { |d| close_enough(d, 0.0) ? 0.0: d } 
    end
  end

  def clamp_ranges
    ap @data_sets

    @data_sets[:vertex] = clamp_range(@data_sets[:vertex]) unless @data_sets[:vertex].nil?

    @data_sets[:normal] = clamp_range(@data_sets[:normal]) unless @data_sets[:normal].nil?
  end

  def load_wavefront(filename)
    w = Wavefront::File.new filename
    mesh = w.compute_vertex_and_index_buffer

    @data_sets[:vertex]   = mesh[:vertex_buffer].map {|v| q=v.vertex; [q.x, q.y, q.z] }
    @data_sets[:normal]   = mesh[:vertex_buffer].map {|v| q=v.normal;   q.nil? ? q : [q.x, q.y, q.z]}
    @data_sets[:texcoord] = mesh[:vertex_buffer].map {|v| v.nil? ? v : [v.tex]}
    @data_sets[:index]    = mesh[:index_buffer].map {|i| [i]}
  end

  def add_triangle(points)

    # Note: perhapse we should be rounding our points here

    #vertex_array    = points.map {|point| point.vertex}
    #computed_normal = compute_vertex_normals(vertex_array)

    #puts "computed_normal = #{computed_normal}"
    
    index  = @data_sets[:vertex].size

    points.each do |point|
      @data_sets[:index]    << [@data_sets[:vertex].size]
      #@data_sets[:index]    << [index]
      @data_sets[:vertex]   << point.vertex
      @data_sets[:normal]   << (point.normal.nil?   ? computed_normal : point.normal)
      @data_sets[:texcoord] << (point.texcoord.nil? ?      [0.0, 0.0] : point.texcoord)
      index += 1
    end

    # Note we should be doing close_enough(verts[vi],      @position[pi], e)
    # check here to use index to elimiate some close points

  end

end


