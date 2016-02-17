require "ap"


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



class Triangle
  attr_accessor :vertex_array

  def initialize(vertex_array)
    @vertex_array = vertex_array
  end

end

class Vertex
  attr_accessor :position, :normal, :texcoord

  def initialize(position, normal, texcoord)
    @position = position 
    @normal = normal
    @texcoord = texcoord
  end
end

##############################################
class Mesh
  attr_accessor :triangles

  def initialize()
    @triangles = Array.new
  end

  def applyMatrix!(matrix)

    # create a matrix without translation for normal rotation
    matrix_no_t = deep_copy(matrix)
    matrix_no_t._41 = matrix_no_t._42 = matrix_no_t._43 = 0

    @triangles.map! do |triangle|
      triangle.vertex_array.map! do |vertex|

        # rotate, translate, scale the vertex postion
        p = vertex.position
        p_v = Geo3d::Vector.new(p[0], p[1], p[2], 1.0)
        v = matrix * p_v
        vertex.position = v.to_a

        # rotate (but don't translate) the vertex normal
        p = vertex.normal
        p_v = Geo3d::Vector.new(p[0], p[1], p[2], 1.0)
        v = matrix_no_t * p_v
        vertex.normal = v.to_a

        vertex
      end
      triangle
    end
  end

  def translate!(vector)
    @triangles.map! do |triangle|
      triangle.vertex_array.map! do |vertex|
        p   = vertex.position
        pp  = Geo3d::Vector.new(p[0], p[1], p[2])
        pp += vector
        vertex.position = pp.to_a
        vertex
      end
      triangle
    end
  end

  def add_mesh(mesh)
    @triangles += deep_copy(mesh.triangles)
  end

  def add_triangle(vertex_array)

    @triangles << Triangle.new(vertex_array) 

    # Note: perhapse we should be rounding our points here

    #vertex_array    = points.map {|point| point.position}
    #computed_normal = compute_position_normals(vertex_array)

    #puts "computed_normal = #{computed_normal}"
    
    # Note we should be doing close_enough(verts[vi],      @position[pi], e)
    # check here to use index to elimiate some close points

  end

  def clamp_range(array)
    array.map! do |v|
      v.map { |d| close_enough(d, 0.0) ? 0.0: d } 
    end
  end

  def clamp_ranges
    # cv --- commenting these out because I don't think they do what I think...

    # @data_sets[:position] = clamp_range(@data_sets[:position]) unless @data_sets[:position].nil?
    # @data_sets[:normal] = clamp_range(@data_sets[:normal]) unless @data_sets[:normal].nil?
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

  # _verts is an array of 4 points
  def push_triangle( _verts, _vNorms = nil, _vTexCoords = nil)

    verts  = deep_copy(_verts.first(3))

    vNorms = [nil, nil, nil]
    vNorms = deep_copy(_vNorms.first(3)) unless _vNorms.nil?

    # make sure the normals are unit length!  # It's almost always a good idea to work with pre-normalized normals
    #vNorms.map! {|v| Vector.elements(v).normalize.to_a}

    #verts = round(verts)
    #vNorms = round(vNorms)
    #vTexCoords = round(vTexCoords)
    
    #puts "vi = #{vi}"
    #@position.each_index do |pi|
    #puts "pi = #{pi}"
    #    break unless @match.nil?
    #    next  unless close_enough(verts[vi],      @position[pi], e) # If the vertex positions are the same
    #    next  unless close_enough(vNorms[vi],      @normal[pi], e) # AND the Normal is the same...
    #    next  unless close_enough(vTexCoords[vi],     @tex[pi], e)   # And Texture is the same...

    # @index << [pi] #  Then add the index only

    # @match = pi 
    #end

    #break unless @match.nil? 

    # No existing point found, add new point 


    vertex_array = []

    (0..2).each do |vi|

      position = verts[vi]
      normal   = vNorms.nil? ? nil : vNorms[vi]
      texcoord = _vTexCoords.nil? ? nil : _vTexCoords[vi]

      vertex = Vertex.new(position, normal, texcoord)

      vertex_array << vertex 
    end

    add_triangle(vertex_array)

  end

end


