require 'ap'
require './util/Assert'
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

  def initialize(position, normal = Geo3d::Vector.new(0.0, 0.0, 0.0), texcoord = Geo3d::Vector.new(0.0, 0.0))
    @position = position
    @normal = normal
    @texcoord = texcoord
  end

  def to_hash
    { position: @position, normal: @normal, texcoord: @texcoord }
  end
end

class Triangle
  attr_accessor :vertex_array

  def initialize(vertex_array)
    @vertex_array = vertex_array
  end

  def initialize_copy(other)
    super # Call superclass initialize_copy

    @vertex_array = @vertex_array.map(&:dup)
  end
end

require 'json'

##############################################
class Mesh
  # attr_accessor :triangles
  attr_reader :triangles

  def initialize(mesh = nil)
    @triangles = []

    # Copy triangles from input mesh
    @triangles = mesh.triangles.map(&:dup) unless mesh.nil?
  end

  def initialize_copy(other)
    super # Call superclass initialize_copy

    @triangles = @triangles.map(&:dup)
  end

  def applyMatrix!(matrix)
    # For Normal Rotation w/o translation
    # matrix_no_t = matrix.clone
    matrix_no_t = matrix.dup
    matrix_no_t._41 = matrix_no_t._42 = matrix_no_t._43 = 0

    @triangles = @triangles.map do |triangle|
      triangle.vertex_array = triangle.vertex_array.map do |vertex|
        # Vertex Position: rotate, translate, scale the vertex postion
        vertex.position.w = 1.0
        position = matrix * vertex.position

        # Vertex Normal: rotate (but don't translate) the vertex normal
        vertex.normal.w = 1.0
        normal = matrix_no_t * vertex.normal

        # texcoord = Geo3d::Vector.new(vertex.texcoord.x, vertex.texcoord.y)
        # Vertex.new(position, normal, texcoord)

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

  def add_mesh!(mesh)
    assert { !mesh.nil? }
    assert { !mesh.triangles.nil? }
    assert { !mesh.triangles.empty? }
    concat(mesh)
    # @triangles += mesh.triangles
  end

  def concat(other)
    @triangles = @triangles.concat(other.triangles)
    self
  end

  def +(other)
    Mesh.new(self).concat(other)
  end

  attr_writer :triangles

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

    @data_sets[:position] = mesh[:position_buffer].map { |v| q = v.position; [q.x, q.y, q.z] }
    @data_sets[:normal]   = mesh[:position_buffer].map { |v| q = v.normal; q.nil? ? q : [q.x, q.y, q.z] }
    @data_sets[:texcoord] = mesh[:position_buffer].map { |v| v.nil? ? v : [v.tex] }
    @data_sets[:index]    = mesh[:index_buffer].map { |i| [i] }
  end
end
