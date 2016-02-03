require "./mesh_shapes"

def deep_copy(complex_array)
    return Marshal.load(Marshal.dump(complex_array))
end


module GL_Shapes

  def GL_Shapes.cylinder(base_radius = 0.1, top_radius=0.1, f_length = 6.0, num_slices=8, num_stacks = 8)
    mesh = Mesh.new
    mesh.push_cylinder(base_radius, top_radius, f_length, num_slices, num_stacks)
    mesh.clamp_ranges

    mesh
  end

  def GL_Shapes.sphere(f_radius = 2.0, i_slices = 4 , i_stacks = 4)
    mesh = Mesh.new
    mesh.push_sphere(f_radius, i_slices, i_stacks)
    mesh.clamp_ranges

    mesh
  end
 
end


