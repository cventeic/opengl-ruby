require 'geo3d'

def deep_copy(complex_array)
    return Marshal.load(Marshal.dump(complex_array))
end

def rand_vector_in_box(named_arguments={x: -10.0..10.0, y: -10.0..10.0, z: -10.0..10.0})
  Geo3d::Vector.new( 
                    rand(named_arguments[:x]),
                    rand(named_arguments[:y]),
                    rand(named_arguments[:z])
                   )
end

def radians(degrees)
  radians = degrees * Math::PI / 180.0
end



class Cross

  def crossProduct(v1, v2, vR)
    vR[0] =   ( (v1[1] * v2[2]) - (v1[2] * v2[1]) )
    vR[1] = - ( (v1[0] * v2[2]) - (v1[2] * v2[0]) )
    vR[2] =   ( (v1[0] * v2[1]) - (v1[1] * v2[0]) )
  end

  def normalize(v1, vR)
    fMag = Math.sqrt( (v1[0] ** 2) +
                      (v1[1] ** 2) +
                      (v1[2] ** 2)
                    )

    vR[0] = v1[0] / fMag
    vR[1] = v1[1] / fMag
    vR[2] = v1[2] / fMag
  end

end

def round(verts)
    verts.map! do |v|
        v.map! do |a|
            a.round(4)
        end
    end
end


def scale(x,y,z)

    m_scale = Geo3d::Matrix[
        [  x, 0.0, 0.0, 0.0],
        [0.0,   y, 0.0, 0.0],
        [0.0, 0.0,   z, 0.0],
        [0.0, 0.0, 0.0, 1.0]
    ]

    @position.map! do |v|
        v[3] = 1.0
        a = m_scale * Geo3d::Matrix.column_vector(v)

        b =  a.column(0).to_a.first(3)
        b
    end
end

=begin
def translate(array, x,y,z)
    m_translate = Geo3d::Matrix.new([
        [1.0, 0.0, 0.0,   x],
        [0.0, 1.0, 0.0,   y],
        [0.0, 0.0, 1.0,   z],
        [0.0, 0.0, 0.0, 1.0]
    ].flatten
                               )

    array.map! do |v|
        v[3] = 1.0
        #a = m_translate * Geo3d::Matrix.column_vector(v)
        a = m_translate * v

        #b =  a.column(0).to_a.first(3)
        #b
        a
    end
end
=end


def compute_triangle_normal(triangle)
    c = Cross.new

    s = triangle.vertex_array.map {|vertex| vertex.position}

    #a = Geo3d::Vector.elements(s[1]) - Geo3d::Vector.elements(s[0])
    #b = Geo3d::Vector.elements(s[2]) - Geo3d::Vector.elements(s[1])

    a = Geo3d::Vector.new(*s[1]) - Geo3d::Vector.new(*s[0])
    b = Geo3d::Vector.new(*s[2]) - Geo3d::Vector.new(*s[1])

    a = a.to_a
    b = b.to_a

    vector1 = Array.new
    vector2 = Array.new

    c.crossProduct(a,b,vector1)
    c.normalize(vector1,vector2)

    vector2
end


def close_enough(_fCandidate, _fCompare, fEpsilon = 0.00001)

    can  = _fCandidate
    comp = _fCompare 

    #can  = can.to_a if can.kind_of? Vector
    can  = can.to_a if can.kind_of? Geo3d::Vector

    #comp = comp.to_a if comp.kind_of? Vector
    comp = comp.to_a if comp.kind_of? Geo3d::Vector

    fCandidate = [can].flatten
    fCompare   = [comp].flatten

    @total = 0
    fCandidate.each_with_index do |e,i|
        a = fCandidate[i]
        b = fCompare[i]
        @total += 1 unless ((a-b).abs < fEpsilon)
    end

    @total == 0 ? true : false
end
 
def lookAt ( eye_, center_, up_)
    eye,center,up = Geo3d::Vector.new(eye_), Geo3d::Vector.new(center_), Geo3d::Vector.new(up_)

    f = (center - eye).normalize
    s = crossProduct(f, up).normalize
    u = crossProduct(s, f)

    Geo3d::Matrix[
        [s.x, u.x, -f.x, -1.0 * dot(s,eye)],
        [s.y, u.y, -f.y, -1.0 * dot(u,eye)],
        [s.z, u.z, -f.z,        dot(f,eye)],
        [0.0, 0.0,   e,         0.0]
    ]
end

def pperspective ( fov, aspect, zNear, zFar)
    puts "perspective #{[fov,aspect,zNear,zFar].join(", ")} "
    assert{aspect != 0}
    assert{zFar != zNear}

    r_fov =  fov * Math::PI / 180

    tanHalfFovy = Math.tan(r_fov / 2.0)

    uw = 1.0 / (aspect * tanHalfFovy)
    uh = 1.0 / (tanHalfFovy)
    c = -1.0 * (zFar + zNear) / (zFar - zNear)
    e = -1.0 * (2.0 * zFar * zNear) / (zFar - zNear)

    Geo3d::Matrix[
        [ uw, 0.0, 0.0, 0.0],
        [0.0,  uh, 0.0, 0.0],
        [0.0, 0.0,   c,-1.0],
        [0.0, 0.0,   e, 0.0]
    ]
end

                                 
def ComputeFOVProjection(fov, aspect, nearDist, farDist, leftHanded=true)
    # General form of the Projection Matrix
    #
    # uh = Cot( fov/2 ) == 1/Tan(fov/2)
    # uw / uh = aspect
    # 
    #   uw         0       0       0
    #    0        uh       0       0
    #    0         0      f/(f-n)  1
    #    0         0    -fn/(f-n)  0
    #
    # Make result to be identity first
   
    r_fov =  fov * Math::PI / 180
    
    # check for bad parameters to avoid divide by zero:
    # if found, assert and return an identity matrix.
    if ( r_fov <= 0 || aspect == 0 )
        Assert( r_fov > 0 && aspect != 0 )
        return Geo3d::Matrix.identity
    end


    frustumDepth = farDist - nearDist
    oneOverDepth = 1.0 / frustumDepth

    uh = 1.0 / Math.tan(0.5 * r_fov)
    uw = (leftHanded ? 1.0 : -1.0 ) * uh / aspect
    c  = farDist * oneOverDepth
    d = (-farDist * nearDist) * oneOverDepth

    Geo3d::Matrix[
        [ uw, 0.0, 0.0, 0.0],
        [0.0,  uh, 0.0, 0.0],
        [0.0, 0.0,   c, 1.0],
        [0.0, 0.0,   d, 0.0]
    ]
end
