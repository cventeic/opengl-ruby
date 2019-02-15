require './oi'

require 'awesome_print'

# Note: translate, rotate, scale --and-- aggregation of sub-objects can be
# supported in a single Cpu_G_Obj_Job instance.
#
# Cpu_G_Obj_Job_1 = Aggregates {
#          TRS matrix_1.1 applied to Cpu_G_Obj_Job_1.1,
#          TRS matrix_1.2 applied to Cpu_G_Obj_Job_1.2,
#          TRS matrix_1.3 applied to Cpu_G_Obj_Job_1.3,
#        }
#
# However below we are often layering with an added Cpu_G_Obj_Job for clarity of code
#
# Cpu_G_Obj_Job_1 = Aggregates {
#          Cpu_G_Obj_Job_1.1 = { TRS matrix_1.1 applied to Cpu_G_Obj_Job_1.1.1 }
#          Cpu_G_Obj_Job_1.2 = { TRS matrix_1.2 applied to Cpu_G_Obj_Job_1.2.1 }
#          Cpu_G_Obj_Job_1.3 = { TRS matrix_1.3 applied to Cpu_G_Obj_Job_1.3.1 }
#        }
#
# In this case Cpu_G_Obj_Job_1.1, Cpu_G_Obj_Job_1.2, Cpu_G_Obj_Job_1.3 are extra Cpu_G_Obj_Job for purpose of code clarity
#

class Cpu_G_Obj_Job
  ############### Helpers

  # Concatinate with world
  # def Cpu_G_Obj_Job.merge_mesh(sup_ctx_in, sub_ctx_out)
  #  sup_ctx_out = sup_ctx_in
  #  sup_ctx_out[:mesh] = sup_ctx_in.fetch(:mesh, Mesh.new) + sub_ctx_out[:mesh]
  #  sup_ctx_out
  # end

  # Merge triangle meshes from two contexts
  #   Both contexts map to the exact same 3-Space without transforms
  #
  #  *** This needs work.
  #       What are we merging?
  #       There can be multiple gpu_objs with unique mesh and color in each context
  #       Merging should be done on specific gpu_objs
=begin
  def self.mesh_merge(context_0, context_1)
    context_0[:gpu_objs] = {} unless context_0.has_key?(:gpu_objs)
    context_0[:gpu_objs][:mesh] = Mesh.new unless context_0[:gpu_objs].has_key?(:mesh)
    c0_mesh = context_0[:gpu_objs][:mesh]


    context_1[:gpu_objs] = {} unless context_1.has_key?(:gpu_objs)
    context_1[:gpu_objs][:mesh] = Mesh.new unless context_1[:gpu_objs].has_key?(:mesh)
    c1_mesh = context_1[:gpu_objs][:mesh]

    puts "context_0[:gpu_objs][:mesh]: #{c0_mesh}"
    puts "context_1[:gpu_objs][:mesh]: #{c1_mesh}"

    context_0[:gpu_objs][:mesh] = c0_mesh + c1_mesh

    puts "context_0[:gpu_objs][:mesh]: #{c0_mesh}"
    context_0
  end
=end

  # Transform mesh in "b" space to mesh in "a" space
  def self.mesh_transform_sub_ctx_egress(sub_ctx_out, sub_ctx_egress_matrix)
    puts
    puts 'def Cpu_G_Obj_Job.mesh_transform_sub_ctx_egress(sub_ctx_out, sub_ctx_egress_matrix)'

    ap sub_ctx_out

    mesh_in_b = sub_ctx_out.fetch(:mesh, Mesh.new)

    mesh_in_a = mesh_in_b.applyMatrix!(sub_ctx_egress_matrix)

    { mesh: mesh_in_a }
  end

  # Join gpu objects from two contexts
  def self.std_join_ctx(ctx_in, ctx_out)
    ctx_in[:gpu_objs]  = [] unless ctx_in.key?(:gpu_objs)
    ctx_in[:gpu_objs] += ctx_out[:gpu_objs] if ctx_out.key?(:gpu_objs)

    ctx_in
  end

  ############### Base Shapes

  def self.sphere(**args)
    defaults = { radius: 0.5 }
    args= defaults.merge(args)

    sphere = Cpu_G_Obj_Job.new(symbol: :sphere)

    sphere.add(
      symbol: :sphere_mesh,
      computes: {
        sub_ctx_render: lambda { |sub_ctx_in|
                           sub_ctx_out = {
                             gpu_objs: [{
                               mesh: GL_Shapes.sphere(args.merge(sub_ctx_in)),
                               color: args[:color]
                             }]
                           }
        }
      }
    )

    sphere
  end

  def self.cylinder(**args)
    cylinder = Cpu_G_Obj_Job.new(symbol: :cylinder)

    cylinder.add(
      symbol: :cylinder_mesh,
      computes: {
        sub_ctx_render: ->(sub_ctx_in) {
          sub_ctx_out = {
            gpu_objs: [{
              mesh: GL_Shapes.cylinder(args.merge(sub_ctx_in)),
              color: args[:color]
            }]
          }
        }
      }
    )

    cylinder
  end

  def self.directional_cylinder(**args)
    cylinder = Cpu_G_Obj_Job.new(symbol: :directional_cylinder)

    cylinder.add(
      symbol: :directional_cylinder_mesh,
      computes: {
        sub_ctx_render: lambda { |sub_ctx_in|
          sub_ctx_out = {
            gpu_objs: [{
              mesh: GL_Shapes.directional_cylinder(args.merge(sub_ctx_in)),
              color: args[:color]
            }]
          }
        }
      }
    )

    cylinder
  end

  def self.arrow(**args)
    arrow = Cpu_G_Obj_Job.new(symbol: :arrow)

    arrow.add(
      symbol: :arrow_mesh,
      computes: {
        sub_ctx_render: lambda { |sub_ctx_in|
                          sub_ctx_out = {
                            mesh: GL_Shapes.arrow(args.merge(sub_ctx_in)),
                            color: args[:color]
                          }
                        }
      }
    )

    arrow
  end

  ############### Composite Shapes

  ##### Make the set of (8) spheres
  # on sphere for each corner of the box
  #
  def self.cube_corner_spheres(side_length: 20.0)
    trs_matricies = [-10.0, 10.0].product([-10.0, 10.0], [-10.0, 10.0]).map do |x, y, z|
      Geo3d::Matrix.translation(x, y, z)
    end

    sphere  = Cpu_G_Obj_Job.sphere(side_length: side_length)

    spheres = Cpu_G_Obj_Job.new

    trs_matricies.each do |sub_ctx_egress_matrix|
      spheres.add(
        symbol: :a_transform,

        computes: {
          sub_ctx_render: ->(_sub_ctx_in) { sub_ctx_out = sphere.render },

          sub_ctx_egress: lambda { |sup_ctx_in, sub_ctx_out|
            mesh_in_a = Cpu_G_Obj_Job.mesh_transform_sub_ctx_egress(sub_ctx_out, sub_ctx_egress_matrix)

            # Combine with the other meshes
            sup_ctx_out = Cpu_G_Obj_Job.std_join_ctx(sup_ctx_in, mesh_in_a)
          }
        }
      )
    end

    spheres
  end

  def self.box_wire(side_length: 20.0, **_args)
    ##### Make 4 parallel cylinders
    #

    parallel_cylinders = Cpu_G_Obj_Job.new

    hl = side_length / 2.0

    # Translate, Rotate, Scale matrix for each cylinder
    #
    trs_matricies = [-hl, hl].product([-hl, hl]).map do |x, y|
      Geo3d::Matrix.translation(x, y, -hl)
    end

    trs_matricies.each do |_trs_matrix|
      cylinder = Cpu_G_Obj_Job.cylinder(f_length: side_length)

      parallel_cylinders.add(
        symbol: :a_transform,

        computes: {
          sub_ctx_render: ->(_sub_ctx_in) { sub_ctx_out = cylinder.render }, # sub context output = rendered object

          sub_ctx_egress: lambda { |sup_ctx_in, _sub_ctx_out| # super context = super context + rendered object
                            sup_ctx_out = sup_ctx_in

                            sup_ctx_out[:mesh] = sup_ctx_out.fetch(:mesh, Mesh.new)

                            puts "aaa sup_ctx_out = #{sup_ctx_out}"

                            # sup_ctx_out[:mesh] += sub_ctx_out[:mesh].applyMatrix!(trs_matrix)

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
      Geo3d::Matrix.identity # Version with centerline on z
    ]

    box = Cpu_G_Obj_Job.new

    matricies.each do |sub_ctx_egress_matrix|
      box.add(
        symbol: :a_transform,

        computes: {
          sub_ctx_render: ->(_sub_ctx_in) { sub_ctx_out = parallel_cylinders.render },

          sub_ctx_egress: lambda { |_sup_ctx_in, sub_ctx_out_array|
            sup_ctx_out_array = sub_ctx_out_array.map do |sub_ctx|
              # mesh_in_a = Cpu_G_Obj_Job.mesh_transform_sub_ctx_egress(sub_ctx,
              # sub_ctx_egress_matrix)
              Cpu_G_Obj_Job.mesh_transform_sub_ctx_egress(sub_ctx, sub_ctx_egress_matrix)
            end

            return sup_ctx_out_array
          }
        }
      )
    end

    box
  end
end
