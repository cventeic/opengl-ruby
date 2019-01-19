require './util/gl_math_util'
require './cpu_graphic_object'

def merge_graphic_objects(objects = [])
  new_object = Mesh.new

  sum_sizes = 0

  sizes = objects.map { |object| object.triangles.size }

  objects.each do |object|
    sum_sizes += object.triangles.size
    new_object.add_mesh!(object)
  end

  puts "merge_graphic_object new_object.triangles.size = #{new_object.triangles.size}, sum_sizes = #{sum_sizes}"
  puts "merge_graphic_object individual sizes = #{sizes}"

  new_object
end

def clone_graphic_object(reference_shape, translation_rotation_scale_matrices = [])
  translation_rotation_scale_matrices.map do |matrix|
    object = reference_shape.dup
    object = object.applyMatrix!(matrix)
    object
  end
end

def cylinder_vertex(radius, cos_theyta, sin_theyta, z, z_normal, s, t)
  x = cos_theyta * radius
  y = sin_theyta * radius

  position = Geo3d::Vector.new(x, y, z)
  texcoord = Geo3d::Vector.new(s, t)

  normal   = Geo3d::Vector.new(x, y, z_normal, 0.0)
  normal.normalize!

  Vertex.new(position, normal, texcoord)
end

def sphere_vertex(radius, x, y, z, s, t)
  position = Geo3d::Vector.new(x * radius, y * radius, z * radius)
  texcoord = Geo3d::Vector.new(s, t)

  normal   = Geo3d::Vector.new(x, y, z)
  normal.normalize!

  Vertex.new(position, normal, texcoord)
end

module GL_Shapes
  def self.box_wire
    ##### Make the set of (8) spheres for each corner of the box
    #

    reference_sphere = sphere(0.5)

    trs_matricies = [-10.0, 10.0].product([-10.0, 10.0], [-10.0, 10.0]).map do |x, y, z|
      Geo3d::Matrix.translation(x, y, z)
    end

    corner_spheres = clone_graphic_object(reference_sphere, trs_matricies)

    ##### Make set of 4 cylinders
    #
    reference_cylinder = GL_Shapes.cylinder(f_length: 20.0)

    t_matricies = [-10.0, 10.0].product([-10.0, 10.0]).map do |x, y|
      Geo3d::Matrix.translation(x, y, -10.0)
    end

    objects = clone_graphic_object(reference_cylinder, t_matricies)

    four_cylinders_on_z = merge_graphic_objects(objects)

    ##### Make the set of (12) cylinders for each edge of the box
    #     3 sets of 4
    #
    r_matricies = [
      Geo3d::Matrix.rotation_y(radians(90.0)),  # Version with centerline on x
      Geo3d::Matrix.rotation_x(radians(90.0)),  # Version with centerline on y
      Geo3d::Matrix.identity # Version with centerline on z
    ]

    edge_cylinders = clone_graphic_object(four_cylinders_on_z, r_matricies)

    ##### Combine the object to make the box
    #
    merge_graphic_objects(corner_spheres + edge_cylinders)
  end

  # Draw arror between start and stop point
  #
  # def GL_Shapes.arrow(line_start: 0, line_stop: 0, radius: 0)
  def self.arrow(start:, stop:, radius: 0.05, **_)
    line_start = start
    line_stop  = stop

    v = line_stop - line_start

    # line_start + v = line_stop
    # line_stop - v  = line_start

    v_arrow = v.normalize * 8.0 * radius

    v_arrow_start = line_stop - v_arrow
    v_arrow_stop  = line_stop

    cone  = GL_Shapes.directional_cylinder(start: v_arrow_start, stop: v_arrow_stop, base_radius: 4.0 * radius, top_radius: 0.0)

    line  = GL_Shapes.line(line_start, line_stop, radius)

    merge_graphic_objects([line, cone])
  end

  # Draw line between start and stop point
  #
  def self.line(start, stop, radius)
    GL_Shapes.directional_cylinder(start: start, stop: stop, base_radius: radius, top_radius: radius)
  end

  def self.directional_cylinder(start: Geo3d::Vector.new, stop: Geo3d::Vector.new, **args)
    # Generate the translation rotation matrix to get the line where we want it
    #
    v_end = stop - start # Vector for ending line
    v_start  = Geo3d::Vector.new(0.0, 0.0, v_end.length.abs, 0.0) # Vector for original cylinder

    v_perp   = v_start.cross(v_end).normalize

    angle = angle_between_two_vectors([v_start, v_end])

    q = Geo3d::Quaternion.from_axis(v_perp, angle)

    m_rotation = q.to_matrix
    m_translation = Geo3d::Matrix.translation(start.x, start.y, start.z)

    # Why is this backward order?????? It works but why???
    m_translation_rotation = m_rotation * m_translation

    # Create the line and move it into position
    # line = GL_Shapes.cylinder(f_length: v_end.length, base_radius: base_radius, top_radius: top_radius, num_slices: num_slices, num_stacks: num_stacks)
    line = GL_Shapes.cylinder(args.merge(f_length: v_end.length))
    line.applyMatrix!(m_translation_rotation)
    # line = line.applyMatrix!(m_rotation)
    # line.applyMatrix!(m_translation)

    line
  end

  # Cylinder centerline extends from origin along +z axis
  #   (center line vector = [0,0,0] -> [0, 0, f_length])
  #
  # Centerline on
  #   +Y axis -- Rotate +90 on +x axis
  #   +X axis -- Rotate +90 on +y axis
  #

  # def GL_Shapes.cylinder(f_length = 6.0, base_radius = 0.1, top_radius=0.1, num_slices=16, num_stacks = 16)
  def self.cylinder(f_length: 6.0, base_radius: 0.1, top_radius: 0.1, num_slices: 16, num_stacks: 16, **_args)
    mesh = Mesh.new

    # Draw a cylinder. Much like gluCylinder
    baseRadius = base_radius
    topRadius = top_radius
    fLength = f_length
    numSlices = num_slices
    numStacks = num_stacks

    vVertex = Array.new(4)

    fRadiusStep = (topRadius - baseRadius) / numStacks

    fStepSizeSlice = (Math::PI * 2.0) / numSlices

    # cylinderBatch.BeginMesh(numSlices * numStacks * 6)

    ds = 1.0 / numSlices
    dt = 1.0 / numStacks

    numStacks.times do |_i|
      i = _i.to_f
      i_next = i + 1.0

      # texture
      t = i * dt
      t = 0.0 if _i == 0

      tNext = (i + 1.0) * dt
      tNext = 1.0 if i == numStacks - 1

      # position
      fCurrentRadius = baseRadius + (fRadiusStep * i)
      fNextRadius    = baseRadius + (fRadiusStep * i_next)

      stack_delta = fLength / numStacks
      fCurrentZ = i * stack_delta
      fNextZ    = i_next * stack_delta

      # Rise over run...
      zNormal = (baseRadius - topRadius) / fLength # /todo check this is right
      # zNormal = (baseRadius - topRadius) # /todo check this is right
      zNormal = 0.0 if close_enough(zNormal, 0.0, 0.00001)

      numSlices.times do |_j|
        # puts "iSlice = #{j}"
        j = _j.to_f
        _j_next = _j + 1
        j_next = _j_next.to_f

        # texture
        s = j * ds
        s = 0.0 if _j == 0

        sNext = j_next * ds
        sNext = 1.0 if _j_next == numSlices

        theyta     = fStepSizeSlice * j
        theytaNext = fStepSizeSlice * j_next
        theytaNext = 0.0 if _j_next == numSlices

        cos_theyta = Math.cos(theyta)
        sin_theyta = Math.sin(theyta)

        cos_theytaNext = Math.cos(theytaNext)
        sin_theytaNext = Math.sin(theytaNext)

        # Inner First
        vVertex[1] = cylinder_vertex(fCurrentRadius, cos_theyta, sin_theyta, fCurrentZ, zNormal, s, t)

        # Outer First
        vVertex[0] = cylinder_vertex(fNextRadius, cos_theyta, sin_theyta, fNextZ, zNormal, s, tNext)

        # Inner second
        vVertex[3] = cylinder_vertex(fCurrentRadius, cos_theytaNext, sin_theytaNext, fCurrentZ, zNormal, sNext, t)

        # Outer second
        vVertex[2] = cylinder_vertex(fNextRadius, cos_theytaNext, sin_theytaNext, fNextZ, zNormal, sNext, tNext)

        mesh.add_triangle([vVertex[0], vVertex[1], vVertex[2]])

        # Rearrange for next triangle
        #
        mesh.add_triangle([vVertex[1], vVertex[3], vVertex[2]])
      end
    end

    # mesh.clamp_ranges

    mesh
  end

  def self.sphere(fRadius = 2.0, iSlices = 16, iStacks = 16)
    mesh = Mesh.new

    vVertex = Array.new(4)

    drho = Math::PI / iStacks
    dtheta = 2.0 * Math::PI / iSlices
    ds = 1.0 / iSlices

    dt = 1.0 / iStacks
    t = 1.0
    s = 0.0

    # sphereBatch.BeginMesh(iSlices * iStacks * 6)

    iStacks.times do |_i|
      i = _i.to_f
      rho = i * drho
      srho = Math.sin(rho)
      crho = Math.cos(rho)

      srhodrho = Math.sin(rho + drho)
      crhodrho = Math.cos(rho + drho)

      # Many sources of OpenGL sphere drawing code uses a triangle fan
      # for the caps of the sphere. This however introduces texturing
      # artifacts at the poles on some OpenGL implementations
      s = 0.0
      iSlices.times do |_j|
        j = _j.to_f

        ##################
        theta = j == iSlices ? 0.0 : j * dtheta
        stheta = -Math.sin(theta)
        ctheta = Math.cos(theta)

        x = stheta * srho
        y = ctheta * srho
        z = crho

        vVertex[0] = sphere_vertex(fRadius, x, y, z, s, t)

        x = stheta * srhodrho
        y = ctheta * srhodrho
        z = crhodrho

        vVertex[1] = sphere_vertex(fRadius, x, y, z, s, t - dt)

        ##################
        theta = (_j + 1) == iSlices ? 0.0 : (j + 1.0) * dtheta
        stheta = -Math.sin(theta)
        ctheta = Math.cos(theta)

        x = stheta * srho
        y = ctheta * srho
        z = crho

        s += ds

        vVertex[2] = sphere_vertex(fRadius, x, y, z, s, t)

        x = stheta * srhodrho
        y = ctheta * srhodrho
        z = crhodrho

        vVertex[3] = sphere_vertex(fRadius, x, y, z, s, t - dt)

        ##################

        mesh.add_triangle([vVertex[0], vVertex[1], vVertex[2]])
        mesh.add_triangle([vVertex[1], vVertex[3], vVertex[2]])
      end

      t -= dt
    end

    # mesh.clamp_ranges

    mesh
  end

  def self.axis_arrows
    cpu_graphic_objects = []

    # show origin
    radius = 0.2
    cpu_graphic_objects << Cpu_Graphic_Object.new(
      internal_proc: ->(named_arguments) { named_arguments[:mesh] = GL_Shapes.sphere(radius) },
      external_proc: ->(named_arguments) {},
      model_matrix: Geo3d::Matrix.translation(0.0, 0.0, 0.0),
      color: Geo3d::Vector.new(1.0, 1.0, 1.0, 1.0)
    )

    # show x axis
    cpu_graphic_objects << Cpu_Graphic_Object.new(
      internal_proc: ->(named_arguments) { named_arguments[:mesh] = GL_Shapes.cylinder(f_length: 0.6, base_radius: 0.2, top_radius: 0.0) },
      external_proc: ->(named_arguments) {},
      model_matrix: (Geo3d::Matrix.translation(0.0, 0.0, 1.0) * Geo3d::Matrix.rotation_y(radians(-90.0))),
      color: Geo3d::Vector.new(1.0, 0.0, 0.0, 1.0)
    )

    # show y axis
    cpu_graphic_objects << Cpu_Graphic_Object.new(
      internal_proc: ->(named_arguments) { named_arguments[:mesh] = GL_Shapes.cylinder(f_length: 0.6, base_radius: 0.2, top_radius: 0.0) },
      external_proc: ->(named_arguments) {},
      model_matrix: (Geo3d::Matrix.translation(0.0, 0.0, 1.0) * Geo3d::Matrix.rotation_x(radians(90.0))),
      color: Geo3d::Vector.new(0.0, 1.0, 0.0, 1.0)
    )

    # show z axis
    cpu_graphic_objects << Cpu_Graphic_Object.new(
      internal_proc: ->(named_arguments) { named_arguments[:mesh] = GL_Shapes.cylinder(f_length: 0.6, base_radius: 0.2, top_radius: 0.0) },
      external_proc: ->(named_arguments) {},
      model_matrix: Geo3d::Matrix.translation(0.0, 0.0, 1.0),
      color: Geo3d::Vector.new(0.0, 0.0, 1.0, 1.0)
    )

    # show z axis
    cpu_graphic_objects << Cpu_Graphic_Object.new(
      internal_proc: ->(named_arguments) { named_arguments[:mesh] = GL_Shapes.cylinder(f_length: 0.6, base_radius: 0.2, top_radius: 0.0) },
      external_proc: ->(named_arguments) {},
      model_matrix: Geo3d::Matrix.translation(0.0, 0.0, 2.0),
      color: Geo3d::Vector.new(0.0, 0.0, 1.0, 1.0)
    )

    cpu_graphic_objects
  end
end

require 'minitest/autorun'

class BugTest < Minitest::Test
end
