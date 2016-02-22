require "ap"
require './util/geo3d_matrix.rb'


# Mesh has many triangles
#
#   triangles have 3 vertex specified by vertex_index (clockwise order)
#
#     A vertex_index referes to a vertex
#
#     A vertex is a position along with color, normal vector and texture coordinates. 
#
#       position has x, y, z
#       color    has r, g, b
#       normal   has x, y, z
#       texture  has x, y
#


class Vertex
  attr_accessor :position, :normal, :texcoord

  def initialize(position, normal, texcoord)
    @position = position 
    @normal = normal
    @texcoord = texcoord
  end

end


class Triangle
  attr_accessor :vertex_array

  def initialize(vertex_array)
    @vertex_array = vertex_array
  end

  def initialize_copy(other)
    super # Call superclass initialize_copy

    @vertex_array = @vertex_array.map {|vertex| vertex.dup}
  end

end

##############################################
class Mesh
  #attr_accessor :triangles
  attr_reader :triangles

  def initialize()
    @triangles = Array.new
  end

  def initialize_copy(other)
    super # Call superclass initialize_copy

    @triangles = @triangles.map {|triangle| triangle.dup}
  end


  def applyMatrix!(matrix)

    # For Normal Rotation w/o translation
    matrix_no_t = matrix.clone
    matrix_no_t._41 = matrix_no_t._42 = matrix_no_t._43 = 0

    @triangles = @triangles.map do |triangle|
      triangle.vertex_array = triangle.vertex_array.map do |vertex|

        # Vertex Position: rotate, translate, scale the vertex postion
        vertex.position.w = 1.0
        position = matrix * vertex.position

        # Vertex Normal: rotate (but don't translate) the vertex normal
        vertex.normal.w = 1.0
        normal = matrix_no_t * vertex.normal

        Vertex.new(position, normal, vertex.texcoord.dup)
      end
      triangle
    end

    self
  end

  def translate!(vector)
    @triangles.map! do |triangle|
      triangle.vertex_array.map! do |vertex|
        vertex += vector
        vertex
      end
      triangle
    end
  end

  def add_mesh(mesh)
    @triangles += mesh.triangles
  end

  def add_triangle(vertex_array)

    @triangles << Triangle.new(vertex_array.first(3)) 

    # /todo Note: perhapse we should be rounding our points here
    # /todo Note: should we be checking for duplicate (close enough) vertex
    # /todo Note: check here to use index to elimiate some close points

  end

  # cv This needs fixed
  def load_wavefront(filename)
    
    w = Wavefront::File.new filename
    mesh = w.compute_position_and_index_buffer

    @data_sets[:position]   = mesh[:position_buffer].map {|v| q=v.position; [q.x, q.y, q.z] }
    @data_sets[:normal]   = mesh[:position_buffer].map {|v| q=v.normal;   q.nil? ? q : [q.x, q.y, q.z]}
    @data_sets[:texcoord] = mesh[:position_buffer].map {|v| v.nil? ? v : [v.tex]}
    @data_sets[:index]    = mesh[:index_buffer].map {|i| [i]}
  end

end


