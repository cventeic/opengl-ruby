require './gpu_object'

def deep_copy(complex_array)
    return Marshal.load(Marshal.dump(complex_array))
end

class Mesh

    def push_triangle( _verts, _vNorms = nil, _vTexCoords = nil)

        verts  = deep_copy(_verts.first(3))
        vNorms = _vNorms.nil? ? nil : deep_copy(_vNorms.first(3))
        vTexCoords = _vTexCoords.nil? ? nil :  deep_copy(_vTexCoords.first(3))

        e = 0.00001 # How small a difference to equate

        # Change Vectors to array of vertex
        #verts.map!      { |v|  (v.kind_of? Vector) ? v.to_a : v}

        # Synthesize vNorms and vTexCoord if not provided
        vNorms = compute_vertex_normals(verts) if vNorms.nil?

        if vTexCoords.nil? then
            vTexCoords = verts.map do |v|
                [0.0, 0.0]
            end
        end

        #  Only deal with first 3 points to make a triangle
        #verts  = verts.first(3)
        #vTexCoords = vTexCoords.first(3)
        #vNorms = vNorms.first(3)

        # Change Vectors to array of vertex
        #vTexCoords.map! { |v|  (v.kind_of? Vector) ? v.to_a : v}
        #vNorms.map!     { |v|  (v.kind_of? Vector) ? v.to_a : v}


        # make sure the normals are unit length!  # It's almost always a good idea to work with pre-normalized normals
        #vNorms.map! {|v| Vector.elements(v).normalize.to_a}

        #verts = round(verts)
        #vNorms = round(vNorms)
        #vTexCoords = round(vTexCoords)

        verts.each_index do |vi|
            @match = nil

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
            @index    << [@position.size]
            @position << verts[vi] 
            @normal   << vNorms[vi]
            @tex      << vTexCoords[vi]
        end
    end

    def push_sphere(fRadius, iSlices, iStacks)

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

                push_triangle(vVertex, vNormal, vTexture)			

                # Rearrange for next triangle
                vVertex[0] = deep_copy(vVertex[1])
                vNormal[0] = deep_copy(vNormal[1])
                vTexture[0] = deep_copy(vTexture[1])

                vVertex[1] = deep_copy(vVertex[3])
                vNormal[1] = deep_copy(vNormal[3])
                vTexture[1] = deep_copy(vTexture[3])

                push_triangle(vVertex, vNormal, vTexture)			
            end

            t -= dt
        end 
        #sphereBatch.End
    end

    # Draw a cylinder. Much like gluCylinder
    def push_cylinder(baseRadius, topRadius, fLength, numSlices, numStacks)
        #puts "push_cylinder"

        vVertex  = Array.new(4) { Array.new(3) }
        #vNormal  = Array.new(4) { Array.new(3) }
        vNormal  = nil
        #vTexture = Array.new(4) { Array.new(2) }
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

                #vNormal[1] = [cos_theyta * fCurrentRadius, sin_theyta * fCurrentRadius, zNormal]
                #m3dNormalizeVector3(vNormal[1]);

                #vTexture[1] = [s, t]

                # Outer First
                vVertex[0] = [cos_theyta * fNextRadius, sin_theyta * fNextRadius, fNextZ]

                #if(!close_enough(fNextRadius, 0.0, 0.00001))
                    #vNormal[0] = [cos_theyta * fNextRadius, sin_theyta * fNextRadius, zNormal]
                    #m3dNormalizeVector3(vNormal[0]);
                #else
                #    vNormal[0] = deep_copy(vNormal[1])
                #end

                #vTexture[0] = [s, tNext]

                # Inner second
                vVertex[3] = [cos_theytaNext * fCurrentRadius, sin_theytaNext * fCurrentRadius, fCurrentZ]

                #vNormal[3] = [cos_theytaNext * fCurrentRadius, sin_theytaNext * fCurrentRadius, zNormal]
                #m3dNormalizeVector3(vNormal[3])

                #vTexture[3] = [sNext, t]

                # Outer second
                vVertex[2] = [cos_theytaNext * fNextRadius,  sin_theytaNext * fNextRadius, fNextZ]

                #if(!close_enough(fNextRadius, 0.0, 0.00001))
                #    vNormal[2] = [cos_theytaNext * fNextRadius,  sin_theytaNext * fNextRadius, zNormal]
                    #m3dNormalizeVector3(vNormal[2]);
                #else
                #    vNormal[2] = deep_copy(vNormal[3])
                #end


                #vTexture[2] = [sNext, tNext]

                #puts "cylinder push triangle"
                push_triangle(vVertex, vNormal, vTexture)			

                # Rearrange for next triangle
                vVertex[0] = deep_copy(vVertex[1])
                #vNormal[0] = deep_copy(vNormal[1])
                #vTexture[0] = deep_copy(vTexture[1])

                vVertex[1] = deep_copy(vVertex[3])
                #vNormal[1] = deep_copy(vNormal[3])
                #vTexture[1] = deep_copy(vTexture[3])

                push_triangle(vVertex, vNormal, vTexture)			
            end
        end
    end
end 

