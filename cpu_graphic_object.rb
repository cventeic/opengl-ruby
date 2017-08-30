
class Cpu_Graphic_Object

  def initialize(named_arguments = {})
    @named_arguments = named_arguments
  end

  def model_matrix=(matrix)
    @named_arguments[:model_matrix] = matrix
  end

  def model_matrix
    @named_arguments.fetch(:model_matrix, Geo3d::Matrix.identity())
  end


  def color
    @named_arguments[:color]
  end

  def mesh
    @named_arguments[:mesh]
  end

  def internal
    lambda = @named_arguments.fetch(:internal_proc, lambda {|named_arguments|})
    lambda.call(@named_arguments)
  end

  def external
    lambda = @named_arguments.fetch(:external_proc, lambda {|named_arguments|})
    lambda.call(@named_arguments)
  end


  # compute a a normal for each triangle
  # and add that normal to each vertex
  def add_missing_normal_vectors(cpu_graphic_objects)
    cpu_graphic_objects.map! do |object|
      object.mesh.triangles.map! do |triangle|
        normal_vector = compute_triangle_normal(triangle)
        triangle.vertex_array.map! do |vertex|
          vertex.normal = normal_vector if vertex.normal.nil?
          vertex
        end
        triangle
      end

      object
    end
  end

end


