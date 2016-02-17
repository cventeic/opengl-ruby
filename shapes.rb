require './util/gl_math_util'

class Array
  def normalize
    sum_squares = self.inject(0) {|sum, item| (sum + item * item) }
    magnitude   = Math.sqrt(sum_squares)
    self.map! {|item| item / magnitude}
  end
end

def merge_graphic_objects(objects=[])
  new_object = Mesh.new

  objects.each do |object|
    new_object.add_mesh(object)
  end

  new_object
end

def clone_graphic_object(reference_shape, translation_rotation_scale_matrices = [])

  translation_rotation_scale_matrices.map do |matrix|
    object = deep_copy(reference_shape)
    object.applyMatrix!(matrix)
    object
  end

end

module GL_Shapes

  def GL_Shapes.box_wire()

    ##### Make the set of (8) spheres for each corner of the box
    #

    reference_sphere = sphere(0.5)

    trs_matricies = [-10.0, 10.0].product( [-10.0, 10.0], [-10.0, 10.0]).map do |x,y,z|
      Geo3d::Matrix.translation(x,y,z)
    end

    corner_spheres = clone_graphic_object(reference_sphere, trs_matricies)

    ##### Make the set of (12) cylinders for each edge of the box
    #

    reference_cylinder = GL_Shapes.cylinder(20.0)

    t_matricies = [-10.0,10.0].product([-10.0,10.0]).map do |x,y|
      Geo3d::Matrix.translation(x, y, -10.0)
    end

    objects = clone_graphic_object(reference_cylinder, t_matricies)
    four_cylinders_on_z = merge_graphic_objects(objects)

    r_matricies = [
      Geo3d::Matrix.rotation_y(radians(90.0)),  # Version with centerline on x
      Geo3d::Matrix.rotation_x(radians(90.0)),  # Version with centerline on y
      Geo3d::Matrix.identity           # Version with centerline on z
    ]

    edge_cylinders = clone_graphic_object(four_cylinders_on_z, r_matricies)

    ##### Combine the object to make the box
    #
    merge_graphic_objects(corner_spheres + edge_cylinders)

  end


  # Cylinder centerline extends from origin along +z axis
  #   (center line vector = [0,0,0] -> [0, 0, f_length])
  #
  # Centerline on
  #   +Y axis -- Rotate +90 on +x axis
  #   +X axis -- Rotate +90 on +y axis
  #

  def GL_Shapes.cylinder(f_length = 6.0, base_radius = 0.1, top_radius=0.1, num_slices=16, num_stacks = 16)
    mesh = Mesh.new

    # Draw a cylinder. Much like gluCylinder
    baseRadius, topRadius, fLength, numSlices, numStacks = base_radius, top_radius, f_length, num_slices, num_stacks

    vVertex  = Array.new(4) { Array.new(3) }
    vNormal  = Array.new(4) { [0.0, 0.0, 0.0] }
    vTexture = nil

    fRadiusStep = (topRadius - baseRadius) / (numStacks)

    fStepSizeSlice = (Math::PI * 2.0) / (numSlices)

    #cylinderBatch.BeginMesh(numSlices * numStacks * 6)

    ds = 1.0 / numSlices
    dt = 1.0 / numStacks

    numStacks.times do |i|
      #puts "iStack = #{i}"
      i_next = i + 1 

      # texture
      t = i * dt
      t = 0.0 if i == 0

      tNext = (i + 1.0) * dt
      tNext = 1.0 if (i==numStacks-1)

      # position
      fCurrentRadius = baseRadius + (fRadiusStep * i)
      fNextRadius    = baseRadius + (fRadiusStep * i_next)

      stack_delta = fLength  / numStacks
      fCurrentZ = i   * stack_delta
      fNextZ    = i_next  * stack_delta

      # Rise over run...
      zNormal = (baseRadius - topRadius) 
      zNormal =  0.0 if(!close_enough(baseRadius - topRadius, 0.0, 0.00001))

      #puts "[zNormal, fCurrentRadius, fNextRadius, fCurrentZ, fNextZ]"
      #puts "#{[zNormal, fCurrentRadius, fNextRadius, fCurrentZ, fNextZ].join(":")}"

      numSlices.times do |j|
        #puts "iSlice = #{j}"
        j_next = j + 1

        # texture
        s = j * ds
        s = 0.0 if(j == 0)

        sNext = j_next * ds
        sNext = 1.0 if(j_next == numSlices)

        # 
        theyta     = fStepSizeSlice * j
        theytaNext = fStepSizeSlice * j_next
        theytaNext = 0.0 if(j_next == numSlices)

        cos_theyta = Math.cos(theyta)
        sin_theyta = Math.sin(theyta)

        cos_theytaNext = Math.cos(theytaNext)
        sin_theytaNext = Math.sin(theytaNext)

        # Inner First
        vVertex[1] = [cos_theyta * fCurrentRadius, sin_theyta * fCurrentRadius, fCurrentZ]

        vNormal[1] = [cos_theyta * fCurrentRadius, sin_theyta * fCurrentRadius, zNormal]
        vNormal[1].normalize

        #vTexture[1] = [s, t]


        # Outer First
        vVertex[0] = [cos_theyta * fNextRadius, sin_theyta * fNextRadius, fNextZ]

        #if(!close_enough(fNextRadius, 0.0, 0.00001))
          vNormal[0] = [cos_theyta * fNextRadius, sin_theyta * fNextRadius, zNormal]
          vNormal[0].normalize
        #else
        #    vNormal[0] = deep_copy(vNormal[1])
        #end

        #vTexture[0] = [s, tNext]

        # Inner second
        vVertex[3] = [cos_theytaNext * fCurrentRadius, sin_theytaNext * fCurrentRadius, fCurrentZ]

        vNormal[3] = [cos_theytaNext * fCurrentRadius, sin_theytaNext * fCurrentRadius, zNormal]
        vNormal[3].normalize

        #vTexture[3] = [sNext, t]

        # Outer second
        vVertex[2] = [cos_theytaNext * fNextRadius,  sin_theytaNext * fNextRadius, fNextZ]

        #if(!close_enough(fNextRadius, 0.0, 0.00001))
            vNormal[2] = [cos_theytaNext * fNextRadius,  sin_theytaNext * fNextRadius, zNormal]
            vNormal[2].normalize
        #else
        #    vNormal[2] = deep_copy(vNormal[3])
        #end


        #vTexture[2] = [sNext, tNext]

        #puts "cylinder push triangle"
        mesh.push_triangle(vVertex, vNormal, vTexture)			

        # Rearrange for next triangle
        vVertex[0] = deep_copy(vVertex[1])
        vNormal[0] = deep_copy(vNormal[1])
        #vTexture[0] = deep_copy(vTexture[1])

        vVertex[1] = deep_copy(vVertex[3])
        vNormal[1] = deep_copy(vNormal[3])
        #vTexture[1] = deep_copy(vTexture[3])

        mesh.push_triangle(vVertex, vNormal, vTexture)			
      end
    end

    mesh.clamp_ranges

    mesh
  end

  def GL_Shapes.sphere(fRadius = 2.0, iSlices = 16 , iStacks = 16)
    mesh = Mesh.new

    vVertex  = Array.new(4) { Array.new(3) }
    vNormal  = Array.new(4) { Array.new(3) }
    vTexture = Array.new(4) { Array.new(2) }

    drho = Math::PI /  iStacks
    dtheta = 2.0 * Math::PI /  iSlices
    ds = 1.0 / iSlices


    dt = 1.0 / iStacks
    t = 1.0	
    s = 0.0

    #sphereBatch.BeginMesh(iSlices * iStacks * 6)

    iStacks.times do |i|
      rho = i * drho
      srho = Math.sin(rho)
      crho = Math.cos(rho)
      srhodrho = Math.sin(rho + drho)
      crhodrho = Math.cos(rho + drho)

      # Many sources of OpenGL sphere drawing code uses a triangle fan
      # for the caps of the sphere. This however introduces texturing 
      # artifacts at the poles on some OpenGL implementations
      s = 0.0
      iSlices.times do |j|
        theta = (j == iSlices) ? 0.0 : j * dtheta
        stheta = -Math.sin(theta)
        ctheta = Math.cos(theta)

        x = stheta * srho
        y = ctheta * srho
        z = crho

        vTexture[0][0] = s
        vTexture[0][1] = t
        vNormal[0][0] = x
        vNormal[0][1] = y
        vNormal[0][2] = z
        vVertex[0][0] = x * fRadius
        vVertex[0][1] = y * fRadius
        vVertex[0][2] = z * fRadius

        x = stheta * srhodrho
        y = ctheta * srhodrho
        z = crhodrho

        vTexture[1][0] = s
        vTexture[1][1] = t - dt
        vNormal[1][0] = x
        vNormal[1][1] = y
        vNormal[1][2] = z
        vVertex[1][0] = x * fRadius
        vVertex[1][1] = y * fRadius
        vVertex[1][2] = z * fRadius



        theta = ((j+1) == iSlices) ? 0.0 : (j+1) * dtheta
        stheta = -Math.sin(theta)
        ctheta = Math.cos(theta)

        x = stheta * srho
        y = ctheta * srho
        z = crho

        s += ds
        vTexture[2][0] = s
        vTexture[2][1] = t
        vNormal[2][0] = x
        vNormal[2][1] = y
        vNormal[2][2] = z
        vVertex[2][0] = x * fRadius
        vVertex[2][1] = y * fRadius
        vVertex[2][2] = z * fRadius


        x = stheta * srhodrho
        y = ctheta * srhodrho
        z = crhodrho

        vTexture[3][0] = s
        vTexture[3][1] = t - dt
        vNormal[3][0] = x
        vNormal[3][1] = y
        vNormal[3][2] = z
        vVertex[3][0] = x * fRadius
        vVertex[3][1] = y * fRadius
        vVertex[3][2] = z * fRadius

        mesh.push_triangle(vVertex, vNormal, vTexture)			

        # Rearrange for next triangle
        vVertex[0] = deep_copy(vVertex[1])
        vNormal[0] = deep_copy(vNormal[1])
        vTexture[0] = deep_copy(vTexture[1])

        vVertex[1] = deep_copy(vVertex[3])
        vNormal[1] = deep_copy(vNormal[3])
        vTexture[1] = deep_copy(vTexture[3])

        mesh.push_triangle(vVertex, vNormal, vTexture)			
      end

      t -= dt
    end 

    mesh.clamp_ranges

    mesh
  end


end

require 'minitest/autorun'

class BugTest < Minitest::Test
  def test_array_normalize
    array = [1.0, 2.0, 3.0]
    array.normalize

    sum_squares = 14.0 # 1.0 + 4.0 + 9.0
    magnitude   = Math.sqrt(sum_squares)
    expected    = [1.0 / magnitude, 2.0 / magnitude, 3.0 / magnitude]

    assert_equal expected, array
  end
end


