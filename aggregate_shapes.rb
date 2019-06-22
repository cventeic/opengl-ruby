require './aggregate'

require 'awesome_print'

# Note: translate, rotate, scale --and-- aggregation of sub-objects can be
# supported in a single Aggregate instance.
#
# Aggregate_1 = Aggregates {
#          TRS matrix_1.1 applied to Aggregate_1.1,
#          TRS matrix_1.2 applied to Aggregate_1.2,
#          TRS matrix_1.3 applied to Aggregate_1.3,
#        }
#
# However below we are often layering with an added Aggregate for clarity of code
#
# Aggregate_1 = Aggregates {
#          Aggregate_1.1 = { TRS matrix_1.1 applied to Aggregate_1.1.1 }
#          Aggregate_1.2 = { TRS matrix_1.2 applied to Aggregate_1.2.1 }
#          Aggregate_1.3 = { TRS matrix_1.3 applied to Aggregate_1.3.1 }
#        }
#
# In this case Aggregate_1.1, Aggregate_1.2, Aggregate_1.3 are extra Aggregate for purpose of code clarity
#

class Aggregate
  ############### Helpers

  # Concatinate with world
  # def Aggregate.merge_mesh(aggregate_data_in, element_output_hash)
  #  aggregate_data_out = aggregate_data_in
  #  aggregate_data_out[:mesh] = aggregate_data_in.fetch(:mesh, Mesh.new) + element_output_hash[:mesh]
  #  aggregate_data_out
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
  def self.mesh_transform_element_egress(element_output_hash, element_egress_matrix)
    puts
    puts 'def Aggregate.mesh_transform_element_egress(element_output_hash, element_egress_matrix)'

    ap element_output_hash

    mesh_in_b = element_output_hash.fetch(:mesh, Mesh.new)

    mesh_in_a = mesh_in_b.applyMatrix!(element_egress_matrix)

    { mesh: mesh_in_a }
  end

  ############### Base Shapes

  def self.sphere(**args)
    defaults = {
      radius: 0.5,
      color: get_new_color
    }
    args= defaults.merge(args)

    sphere = Aggregate.new(symbol: :sphere)

    sphere.add_element(
      symbol: :sphere_mesh,
      lambdas: {
        element_render: lambda { |element_input_hash|
                           element_output_hash = {
                             gpu_objs: [{
                               mesh: GL_Shapes.sphere(args.merge(element_input_hash)),
                               color: args[:color]
                             }]
                           }
        }
      }
    )

    sphere
  end

  def self.cylinder(**args)
    cylinder = Aggregate.new(symbol: :cylinder)

    cylinder.add_element(
      symbol: :cylinder_mesh,
      lambdas: {
        element_render: ->(element_input_hash) {
          element_output_hash = {
            gpu_objs: [{
              mesh: GL_Shapes.cylinder(args.merge(element_input_hash)),
              color: args[:color]
            }]
          }
        }
      }
    )

    cylinder
  end

  def self.directional_cylinder(**args)
    cylinder = Aggregate.new(symbol: :directional_cylinder)

    cylinder.add_element(
      symbol: :directional_cylinder_mesh,
      lambdas: {
        element_render: lambda { |element_input_hash|
          element_output_hash = {
            gpu_objs: [{
              mesh: GL_Shapes.directional_cylinder(args.merge(element_input_hash)),
              color: args[:color]
            }]
          }
        }
      }
    )

    cylinder
  end

  def self.arrow(start:, stop:, **args)
    defaults = {
      radius: 0.05,
      color: get_new_color
    }
    args= defaults.merge(args)

    arrow_v = stop - start
    arrow_v = arrow_v.normalize * 8.0 * args[:radius]
    arrow_start = stop - arrow_v
    arrow_stop  = stop

    line_start = start
    line_stop  = arrow_start

    arrow = Aggregate.new(symbol: :arrow)

    arrow.add_element(
      symbol: :arrow_cone_shaft_mesh,
      lambdas: {
        element_render: lambda { |element_input_hash|
          element_output_hash = {
            gpu_objs: [{
                mesh: GL_Shapes.directional_cylinder(
                  start: arrow_start, stop: arrow_stop,
                  base_radius: (4.0 * args[:radius]),
                  top_radius: 0.0
                ),
                color: args[:color]
            },
            {
                mesh: GL_Shapes.directional_cylinder(
                  start: line_start, stop: line_stop,
                  base_radius: args[:radius],
                  top_radius: radius
                ),
                color: args[:color]
            }
            ]
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
  def self.cube_corner_spheres(**args)
    defaults = {
      side_length: 0.5,
      color: get_new_color
    }
    args= defaults.merge(args)


    trs_matricies = [-10.0, 10.0].product([-10.0, 10.0], [-10.0, 10.0]).map do |x, y, z|
      Geo3d::Matrix.translation(x, y, z)
    end

    sphere  = Aggregate.sphere(side_length: args[:side_length])

    spheres = Aggregate.new

    trs_matricies.each do |element_egress_matrix|
      spheres.add_element(
        symbol: :a_transform,

        lambdas: {
          element_render: ->(_element_input_hash) { element_output_hash = sphere.render },

          element_egress: lambda { |aggregate_data_in, element_output_hash|
            # Were going to translate the mesh
            # Error here...
            mesh_in_a = Aggregate.mesh_transform_element_egress(element_output_hash, element_egress_matrix)

            # Combine with the other meshes
            aggregate_data_out = Aggregate.add_gpu_objs_to_aggregate(aggregate_data_in, mesh_in_a)
          }
        }
      )
    end

    spheres
  end

  def self.box_wire(side_length: 20.0, **_args)
    ##### Make 4 parallel cylinders
    #

    parallel_cylinders = Aggregate.new

    hl = side_length / 2.0

    # Translate, Rotate, Scale matrix for each cylinder
    #
    trs_matricies = [-hl, hl].product([-hl, hl]).map do |x, y|
      Geo3d::Matrix.translation(x, y, -hl)
    end

    trs_matricies.each do |element_egress_matrix|
      cylinder = Aggregate.cylinder(f_length: side_length)

      parallel_cylinders.add_element(
        symbol: :a_transform,

        lambdas: {
          element_render: ->(_element_input_hash) { element_output_hash = cylinder.render }, # sub context output = rendered object

          element_egress: lambda { |aggregate_data_in, _element_output_hash| # super context = super context + rendered object
                            aggregate_data_out = aggregate_data_in

                            aggregate_data_out[:mesh] = aggregate_data_out.fetch(:mesh, Mesh.new)

                            puts "aaa aggregate_data_out = #{aggregate_data_out}"

                            # aggregate_data_out[:mesh] += element_output_hash[:mesh].applyMatrix!(trs_matrix)

                            return aggregate_data_out
                          }
        }
      )
    end

    ##### Make the set of (12) cylinders for each edge of the box
    #     3 sets of 4
    #
    trs_matricies = [
      Geo3d::Matrix.rotation_y(radians(90.0)),  # Version with centerline on x
      Geo3d::Matrix.rotation_x(radians(90.0)),  # Version with centerline on y
      Geo3d::Matrix.identity # Version with centerline on z
    ]

    box = Aggregate.new

    trs_matricies.each do |element_egress_matrix|
      box.add_element(
        symbol: :a_transform,

        lambdas: {
          element_render: ->(_element_input_hash) { element_output_hash = parallel_cylinders.render },

          element_egress: lambda { |_aggregate_data_in, element_output_hash_array|
            aggregate_data_out_array = element_output_hash_array.map do |sub_ctx|
              # mesh_in_a = Aggregate.mesh_transform_element_egress(sub_ctx,
              # element_egress_matrix)
              Aggregate.mesh_transform_element_egress(sub_ctx, element_egress_matrix)
            end

            return aggregate_data_out_array
          }
        }
      )
    end

    box
  end
end
