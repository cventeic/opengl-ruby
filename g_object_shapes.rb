# Augment the Object_Indirection with some shapes
#

# Note: translate, rotate, scale --and-- aggregation of sub-objects can be
# supported in a single OI instance.
#
# OI_1 = Aggregates {
#          TRS matrix_1.1 applied to OI_1.1,
#          TRS matrix_1.2 applied to OI_1.2,
#          TRS matrix_1.3 applied to OI_1.3,
#        }
#
# However below we are often layering with an added OI for clarity of code
#
# OI_1 = Aggregates {
#          OI_1.1 = { TRS matrix_1.1 applied to OI_1.1.1 }
#          OI_1.2 = { TRS matrix_1.2 applied to OI_1.2.1 }
#          OI_1.3 = { TRS matrix_1.3 applied to OI_1.3.1 }
#        }
#
# In this case OI_1.1, OI_1.2, OI_1.3 are extra OI for purpose of code clarity
#

class Object_Indirection

  def Object_Indirection.add_computed_cylinder
    lambda {|input|
      # output mesh
      GL_Shapes.cylinder(input[:f_length])
    }
  end

  def Object_Indirection.add_computed_sphere
    lambda {|input|
      # output mesh
      GL_Shapes.sphere(input[:radius])
    }
  end


  def Object_Indirection.oi_sphere(opts)
    sphere = Object_Indirection.new
    sphere.add_compute(
      inputs: {radius: 0.5}.merge(opts),
      compute: lambda {|input| GL_Shapes.sphere(input[:radius]) }
    )
    sphere
  end

  def Object_Indirection.oi_cylinder(opts)
    cylinder = Object_Indirection.new
    cylinder.add_compute(
      inputs: {}.merge(opts),
      compute: lambda {|input| GL_Shapes.cylinder(input[:f_length]) }
    )
    cylinder
  end

  def Object_Indirection.oi_cube_corner_spheres(side_length: 20.0)

    sphere = Object_Indirection.oi_sphere({side_length: side_length})

    ##### Make the set of (8) spheres for each corner of the box
    #

    trs_matricies = [-10.0, 10.0].product( [-10.0, 10.0], [-10.0, 10.0]).map do |x,y,z|
      Geo3d::Matrix.translation(x,y,z)
    end

    cube_corner_spheres = Object_Indirection.new

    trs_matricies.each do |matrix|

      cube_corner_spheres.add_compute(
        compute: Object_Indirection.add_computed_sub_object(),
        inputs: {trs_matrixes: [matrix], object_indirection: sphere},
      )
    end

    cube_corner_spheres
  end

  # Create new OI that applies translate, rotate, scale matrix to sub OI
  #
  def Object_Indirection.oi_translate_rotate_scale_oi(matrix_array:, sub_oi:)
    oi = Object_Indirection.new

    oi.add_compute(
      compute: Object_Indirection.add_computed_sub_object(),
      inputs: {trs_matrixes: [matrix_array], object_indirection: sub_oi},
    )

    oi
  end

  # Create new OI that aggregates multiple sub OI into one object
  #
  def Object_Indirection.oi_aggregate(sub_oi_array:)
    #sub_oi_array:
    oi = Object_Indirection.new

    sub_oi_array.each do |sub_oi|
      oi.add_compute(
        compute: Object_Indirection.add_computed_sub_object(),
        inputs: {object_indirection: sub_oi},
      )
    end

    oi
  end

  # Produce square made from cylinders
  #   square is centered on 0,0,0 and flat on z plane
  #
  def Object_Indirection.oi_square(side_length: 20.0)

    cylinder = Object_Indirection.oi_cylinder(f_length: side_length)


    ##### Make square from cylinders

    hl = side_length / 2.0

    t_matricies = [-hl, hl].product([-hl, hl]).map do |x,y|
      Geo3d::Matrix.translation(x, y, -hl)
    end

    square_of_cylinder_oi_array = t_matricies.map do |t_matrix|
      Object_Indirection.oi_translate_rotate_scale_oi(matrix_array: [t_matrix], sub_oi: cylinder)
    end

    square_of_cylinder_oi = Object_Indirection.oi_aggregate(sub_oi_array: square_of_cylinder_oi_array)

    square_of_cylinder_oi

  end


  # Produce a wire box centered at 0, 0, 0
  #
  def Object_Indirection.oi_box_wire(side_length: 20.0)

    square_of_cylinder_oi = Object_Indirection.oi_square(side_length: side_length)

    ##### Make the set of (12) cylinders for each edge of the box
    #     3 sets of 4
    #
    r_matricies = [
      Geo3d::Matrix.rotation_y(radians(90.0)),  # Version with centerline on x
      Geo3d::Matrix.rotation_x(radians(90.0)),  # Version with centerline on y
      Geo3d::Matrix.identity           # Version with centerline on z
    ]

    cube_of_cylinders_oi_array = r_matricies.map do |matrix|
      Object_Indirection.oi_translate_rotate_scale_oi(matrix_array: [matrix], sub_oi: square_of_cylinder_oi)
    end

    cube_of_cylinders_oi = Object_Indirection.oi_aggregate(sub_oi_array: cube_of_cylinders_oi_array)

    cube_of_cylinders_oi
  end

  # Produce a wire box centered at 0, 0, 0
  #
  # This example avoids extra OI for code clarity
  #
  def Object_Indirection.oi_box_wire_2(side_length: 20.0)

    #####

    cylinder = Object_Indirection.oi_cylinder(f_length: side_length)


    ##### Make set of 4 cylinders

    four_cylinders_on_z = Object_Indirection.new

    hl = side_length / 2.0

    t_matricies = [-hl, hl].product([-hl, hl]).map do |x,y|
      Geo3d::Matrix.translation(x, y, -hl)
    end

    t_matricies.each do |t_matrix|

      four_cylinders_on_z.add_compute(
        compute: Object_Indirection.add_computed_sub_object(),
        inputs: {trs_matrixes: [t_matrix], object_indirection: cylinder},
      )

    end

    ##### Make the set of (12) cylinders for each edge of the box
    #     3 sets of 4
    #
    r_matricies = [
      Geo3d::Matrix.rotation_y(radians(90.0)),  # Version with centerline on x
      Geo3d::Matrix.rotation_x(radians(90.0)),  # Version with centerline on y
      Geo3d::Matrix.identity           # Version with centerline on z
    ]

    twelve_cylinders = Object_Indirection.new

    r_matricies.each do |r_matrix|
      twelve_cylinders.add_compute(
        compute: Object_Indirection.add_computed_sub_object,
        inputs: {trs_matrixes: [r_matrix], object_indirection: four_cylinders_on_z},
      )
    end

    #####
    #
    twelve_cylinders
  end

end
