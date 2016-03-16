require './oi'

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


class OI

  ############### Helpers

  # Concatinate with world
  #def OI.merge_mesh(a_input, b_output)
  #  a_output = a_input
  #  a_output[:mesh] = a_input.fetch(:mesh, Mesh.new) + b_output[:mesh]
  #  a_output
  #end

  def OI.mesh_merge(space_0, space_1)
    space_0[:mesh] = space_0.fetch(:mesh, Mesh.new) + space_1.fetch(:mesh, Mesh.new)
    space_0
  end


  # Transform mesh in "b" space to mesh in "a" space
  def OI.mesh_tranform_b_to_a(b_output, b_to_a_matrix)
    mesh_in_b = b_output.fetch(:mesh, Mesh.new)

    mesh_in_a = mesh_in_b.applyMatrix!(b_to_a_matrix) 

    {mesh: mesh_in_a}
  end

  ############### Base Shapes
  
  def OI.sphere(a_input = {})

    sphere = OI.new(symbol: :sphere)

    sphere.add(
      symbol: :sphere_mesh, 
      computes: {
        a_to_b:   lambda {|a_input|           b_input  = {radius: 0.5}.merge(a_input)},
        b_render: lambda {|b_input|           b_output = {mesh: GL_Shapes.sphere(b_input[:radius])} },
        b_to_a:   lambda {|a_input, b_output| a_output = OI.mesh_merge(a_input, b_output) }
      }
    )

    sphere
  end

  def OI.cylinder(**args)
    cylinder = OI.new(symbol: :cylinder)

    cylinder.add(
      symbol: :cylinder_mesh, 
      computes: {
        #b_render: lambda {|b_input| {mesh: GL_Shapes.cylinder(b_input[:f_length])} },
        
        a_to_b:   lambda {|a_input|            b_input = a_input},
        b_render: lambda {|b_input|           b_output = {mesh: GL_Shapes.cylinder(args.merge(b_input))} },
        b_to_a:   lambda {|a_input, b_output| a_output = OI.mesh_merge(a_input, b_output) }
      }
    )

    cylinder
  end

  def OI.directional_cylinder(**args)
    cylinder = OI.new(symbol: :directional_cylinder)

    cylinder.add(
      symbol: :cylinder_mesh, 
      computes: {
        #b_render: lambda {|b_input| {mesh: GL_Shapes.cylinder(b_input[:f_length])} },
        
        a_to_b:   lambda {|a_input|            b_input = a_input},
        b_render: lambda {|b_input|           b_output = {mesh: GL_Shapes.directional_cylinder(args.merge(b_input))} },
        b_to_a:   lambda {|a_input, b_output| a_output = OI.mesh_merge(a_input, b_output) }
      }
    )

    cylinder
  end

  ############### Composite Shapes
  
  ##### Make the set of (8) spheres 
  # on sphere for each corner of the box
  #
  def OI.cube_corner_spheres(side_length: 20.0)
    
    trs_matricies = [-10.0, 10.0].product( [-10.0, 10.0], [-10.0, 10.0]).map do |x,y,z|
      Geo3d::Matrix.translation(x,y,z)
    end

    sphere  = OI.sphere({side_length: side_length})

    spheres = OI.new

    trs_matricies.each do |b_to_a_matrix| 
      spheres.add(
        symbol: :a_transform, 

        computes: {
          a_to_b:   lambda {|a_input| b_input  = a_input},
          b_render: lambda {|b_input| b_output = sphere.render },

          b_to_a: lambda {|a_input, b_output| 

            mesh_in_a = OI.mesh_tranform_b_to_a(b_output, b_to_a_matrix)

            a_output = OI.mesh_merge(a_input, mesh_in_a)
          }
        }
      )
    end

    spheres 
  end

  def OI.box_wire(side_length: 20.0, **args)

    hl = side_length / 2.0

    cylinder = OI.cylinder(f_length: side_length)

    ##### Make 4 parallel cylinders
    #
    trs_matricies = [-hl, hl].product([-hl, hl]).map do |x,y|
      Geo3d::Matrix.translation(x, y, -hl)
    end

    parallel_cylinders = OI.new

    trs_matricies.each do |b_to_a_matrix| 
      parallel_cylinders.add(
        symbol: :a_transform, 

        computes: {
          a_to_b:   lambda {|a_input| b_input  = a_input},
          b_render: lambda {|b_input| b_output = cylinder.render },

          b_to_a: lambda {|a_input, b_output| 

            mesh_in_a = OI.mesh_tranform_b_to_a(b_output, b_to_a_matrix)

            a_output = OI.mesh_merge(a_input, mesh_in_a)
         }
        }
      )
    end

    ##### Make the set of (12) cylinders for each edge of the box
    #     3 sets of 4 
    #
    matricies = [
      Geo3d::Matrix.rotation_y(radians(90.0)),  # Version with centerline on x
      Geo3d::Matrix.rotation_x(radians(90.0)),  # Version with centerline on y
      Geo3d::Matrix.identity           # Version with centerline on z
    ]

    box = OI.new

    matricies.each do |b_to_a_matrix| 
      box.add(
        symbol: :a_transform, 

        computes: {
          a_to_b:   lambda {|a_input| b_input  = a_input},
          b_render: lambda {|b_input| b_output = parallel_cylinders.render },

          b_to_a: lambda {|a_input, b_output| 

            mesh_in_a = OI.mesh_tranform_b_to_a(b_output, b_to_a_matrix)

            a_output = OI.mesh_merge(a_input, mesh_in_a)
         }
        }
      )
    end

    box

  end


end


