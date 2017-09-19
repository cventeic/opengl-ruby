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
  #def OI.merge_mesh(sup_ctx_in, sub_ctx_out)
  #  sup_ctx_out = sup_ctx_in
  #  sup_ctx_out[:mesh] = sup_ctx_in.fetch(:mesh, Mesh.new) + sub_ctx_out[:mesh]
  #  sup_ctx_out
  #end

  # Merge triangle meshes from two contexts
  #   Both contexts map to the exact same 3-Space without transforms
  #
  def OI.mesh_merge(context_0, context_1)
    context_0[:mesh] = context_0.fetch(:mesh, Mesh.new) + context_1.fetch(:mesh, Mesh.new)
    context_0
  end


  # Transform mesh in "b" space to mesh in "a" space
  def OI.mesh_tranform_sub_ctx_egress(sub_ctx_out, sub_ctx_egress_matrix)
    mesh_in_b = sub_ctx_out.fetch(:mesh, Mesh.new)

    mesh_in_a = mesh_in_b.applyMatrix!(sub_ctx_egress_matrix)

    {mesh: mesh_in_a}
  end

  ############### Base Shapes

  def OI.sphere(sup_ctx_in = {})

    sphere = OI.new(symbol: :sphere)

    sphere.add(
      symbol: :sphere_mesh,
      computes: {
        sub_ctx_ingress:   lambda {|sup_ctx_in|           sub_ctx_in  = {radius: 0.5}.merge(sup_ctx_in)},
        sub_ctx_render: lambda {|sub_ctx_in|           sub_ctx_out = {mesh: GL_Shapes.sphere(sub_ctx_in[:radius])} },
        sub_ctx_egress:   lambda {|sup_ctx_in, sub_ctx_out| sup_ctx_out = OI.mesh_merge(sup_ctx_in, sub_ctx_out) }
      }
    )

    sphere
  end

  def OI.cylinder(**args)
    cylinder = OI.new(symbol: :cylinder)

    cylinder.add(
      symbol: :cylinder_mesh,
      computes: {
        #sub_ctx_render: lambda {|sub_ctx_in| {mesh: GL_Shapes.cylinder(sub_ctx_in[:f_length])} },

        sub_ctx_ingress:   lambda {|sup_ctx_in|            sub_ctx_in = sup_ctx_in},
        sub_ctx_render: lambda {|sub_ctx_in|           sub_ctx_out = {mesh: GL_Shapes.cylinder(args.merge(sub_ctx_in))} },
        sub_ctx_egress:   lambda {|sup_ctx_in, sub_ctx_out| sup_ctx_out = OI.mesh_merge(sup_ctx_in, sub_ctx_out) }
      }
    )

    cylinder
  end

  def OI.directional_cylinder(**args)
    cylinder = OI.new(symbol: :directional_cylinder)

    cylinder.add(
      symbol: :cylinder_mesh,
      computes: {
        #sub_ctx_render: lambda {|sub_ctx_in| {mesh: GL_Shapes.cylinder(sub_ctx_in[:f_length])} },

        sub_ctx_ingress:   lambda {|sup_ctx_in|            sub_ctx_in = sup_ctx_in},
        sub_ctx_render: lambda {|sub_ctx_in|           sub_ctx_out = {mesh: GL_Shapes.directional_cylinder(args.merge(sub_ctx_in))} },
        sub_ctx_egress:   lambda {|sup_ctx_in, sub_ctx_out| sup_ctx_out = OI.mesh_merge(sup_ctx_in, sub_ctx_out) }
      }
    )

    cylinder
  end


  def OI.arrow(**args)
    arrow = OI.new(symbol: :arrow)

    arrow.add(
      symbol: :arrow_mesh,
      computes: {
        sub_ctx_ingress:   lambda {|sup_ctx_in|           sub_ctx_in = sup_ctx_in},
        sub_ctx_render: lambda {|sub_ctx_in|           sub_ctx_out = {
                                                mesh: GL_Shapes.arrow(args.merge(sub_ctx_in)),
                                                color: args[:color]
                                              }
                         },
        sub_ctx_egress:   lambda {|sup_ctx_in, sub_ctx_out| sup_ctx_out = OI.mesh_merge(sup_ctx_in, sub_ctx_out) }
      }
    )

    arrow
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

    trs_matricies.each do |sub_ctx_egress_matrix|
      spheres.add(
        symbol: :a_transform,

        computes: {
          sub_ctx_ingress:   lambda {|sup_ctx_in| sub_ctx_in  = sup_ctx_in},
          sub_ctx_render: lambda {|sub_ctx_in| sub_ctx_out = sphere.render },

          sub_ctx_egress: lambda {|sup_ctx_in, sub_ctx_out|

            mesh_in_a = OI.mesh_tranform_sub_ctx_egress(sub_ctx_out, sub_ctx_egress_matrix)

            sup_ctx_out = OI.mesh_merge(sup_ctx_in, mesh_in_a)
          }
        }
      )
    end

    spheres
  end

  def OI.box_wire(side_length: 20.0, **args)



    ##### Make 4 parallel cylinders
    #

    parallel_cylinders = OI.new

    hl = side_length / 2.0

    # Translate, Rotate, Scale matrix for each cylinder
    #
    trs_matricies = [-hl, hl].product([-hl, hl]).map do |x,y|
      Geo3d::Matrix.translation(x, y, -hl)
    end


    trs_matricies.each do |trs_matrix|

      cylinder = OI.cylinder(f_length: side_length)

      parallel_cylinders.add(
        symbol: :a_transform,

        computes: {
          sub_ctx_ingress: lambda {|sup_ctx_in| sub_ctx_in  = sup_ctx_in},        # sub context input = untransformed super context

          sub_ctx_render:  lambda {|sub_ctx_in| sub_ctx_out = cylinder.render },  # sub context output = rendered object

          sub_ctx_egress:  lambda {|sup_ctx_in, sub_ctx_out|                      # super context = super context + rendered object


                                    sup_ctx_out = sup_ctx_in

                                    sup_ctx_out[:mesh] = sup_ctx_out.fetch(:mesh, Mesh.new)
                                    sup_ctx_out[:mesh] += sub_ctx_out[:mesh].applyMatrix!(trs_matrix)

                                    return sup_ctx_out
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

    matricies.each do |sub_ctx_egress_matrix|
      box.add(
        symbol: :a_transform,

        computes: {
          sub_ctx_ingress: lambda {|sup_ctx_in| sub_ctx_in  = sup_ctx_in},
          sub_ctx_render:  lambda {|sub_ctx_in| sub_ctx_out = parallel_cylinders.render },

          sub_ctx_egress:  lambda {|sup_ctx_in, sub_ctx_out|

            mesh_in_a = OI.mesh_tranform_sub_ctx_egress(sub_ctx_out, sub_ctx_egress_matrix)

            sup_ctx_out = OI.mesh_merge(sup_ctx_in, mesh_in_a)
          }
        }
      )
    end

    box

  end

end


