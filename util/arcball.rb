
require 'geo3d'

EPSILON = 1.0e-5

=begin
class Geo3d::Vector
  attr_accessor :x, :y, :z

  def initialize(x = 0, y = 0, z = 0)
    @x, @y, @z = x, y, z
  end

  def add(vector)
    Geo3d::Vector.new(vector.x + @x, vector.y + @y, vector.z + @z)
  end

  def normalize
    orig_dist = Math.sqrt(@x * @x + @y * @y + @z * @z)
    @x /= orig_dist
    @y /= orig_dist
    @z /= orig_dist
    self
  end

  def self.dot(v1, v2)
    v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
  end

  def self.mult(v, scalar)
    Geo3d::Vector.new(v.x * scalar, v.y * scalar, v.z * scalar)
  end

  def self.sub(v1, v2)
    Geo3d::Vector.new(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z)
  end

  def cross(v)
    Geo3d::Vector.new(@y * v.z - v.y * @z,  @z * v.x - v.z * @x, @x * v.y - v.x * @y)
  end

  def magnitude
    Math.sqrt((@x * @x) + (@y * @y) + (@z * @z))
  end

end
=end



class ArcBall
  attr_reader :center_x, :center_y, :v_down, :v_drag, :q_now, :q_drag, :q_down, :axis, :axis_set, :radius

  #def initialize(cx, cy, radius)
  def initialize(width, height)
    #@center_x = cx
    #@center_y = cy
    #@radius = radius
    @v_down = Geo3d::Vector.new
    @v_drag = Geo3d::Vector.new
    #@q_now = Quaternion.new
    #@q_down = Quaternion.new
    #@q_drag = Quaternion.new
    @axis_set = [Geo3d::Vector.new(1.0, 0.0, 0.0), Geo3d::Vector.new(0.0, 1.0, 0.0), Geo3d::Vector.new(0.0, 0.0, 1.0)]
    @axis = -1

    #width = radius * 2
    #height = radius * 2
    setBounds(width, height)
  end

  def place(x,y)
  end

  def setBounds(width, height)
    # Set new bounds
    assert {width > 1.0 && height > 1.0}  #"Invalid width or height for bounds."
    #Set adjustment factor for width/height
    @m_AdjustWidth = 1.0 / ((width - 1.0) * 0.5)
    @m_AdjustHeight = 1.0 / ((height - 1.0) * 0.5)
  end


  def select_axis(axis)
    @axis = axis
  end

  # Adjust point coords and scale down to range of [-1 ... 1]
  #
  def scale_mouse_position(x, y) 
    Geo3d::Vector.new(
      (x * @m_AdjustWidth) - 1.0,  # X
      1.0 - (y * @m_AdjustHeight), # Y
      0                            # Z
    )
  end

 
  # Compute the projection of the user click at (x,y) onto the unit hemishpere facing the user (aka "the arcball"). 
  #
  # The ball is centered in the middle of the screen and has radius equal to gizmoR.
  # All clicks outside this radius are interpreted as being on the boundary of the disk facing the user.
  #
  # To compute pX and pY (x and y) coordinates of the projection, we subtract the center of the sphere and scale down by gizmoR.
  # Since the projection is on a unit sphere, we know that pX^2 + pY^2 + pZ^2 = 1, so we can compute * the Z coordinate from this formula. 
  #
  # This won't work if pX^2 + pY^2 > 1, i.e. if the user clicked outside of the ball; so we interpret these clicks as being on the boundary.
  #
  # Output is threespace vector x, y, z identifying point on sphere of radius 1
  #
  def mouse2sphere(x, y)

    # vector in x/y plane
    #v = Geo3d::Vector.new((x - @center_x) / @radius, 
    #                (y - @center_y) / @radius, 
    #                0)

    v = scale_mouse_position(x,y)

    mag = v.x * v.x + v.y * v.y
    if (mag > 1.0)
        # Point is mapped outside of the sphere... (length > radius squared)
      v.normalize
    else
      # Return a vector to a point mapped inside the sphere sqrt(radius squared - length)
      v.z = Math.sqrt(1.0 - mag)
    end

    # v = constrain(v, @axis_set[@axis]) unless (@axis == -1)

    return v
  end

  def mouse_pressed(x, y)
    @v_down = mouse2sphere(x, y)
    @v_drag = @v_down

    #@q_down.copy(@q_now)
    #@q_drag.reset
    #puts "mouse_pressed #{[ x, y]}"
  end

  def mouse_dragged(x, y)
    @v_drag = mouse2sphere(x, y)
    #@q_drag.set(Geo3d::Vector.dot(@v_down, @v_drag), @v_down.cross(@v_drag))
    #puts "mouse_dragged #{[x, y]}"
  end


  def constrain(vector, axis)
    res = Geo3d::Vector.sub(vector, Geo3d::Vector.mult(axis, Geo3d::Vector.dot(axis, vector)))
    res.normalize!
  end

  def compute_rotation_quaternion

    # Perp vector is the axis of rotation 
    #perp = @v_down.cross(@v_drag)
    perp = @v_drag.cross(@v_down)

    # Compute the length of the perpendicular vector
    if (perp.length > EPSILON)		# if its non-zero
      # We're ok, so return the perpendicular vector as the transform after all
      #new_rotation[X] = Perp[X] new_rotation[Y] = Perp[Y] new_rotation[Z] = Perp[Z]

      # In the quaternion values, w is cosine (theta / 2), 
      # where theta is rotation angle
      #new_rotation[W] = Vector3fDot(@m_StVec, @m_EnVec)
      w = @v_down.dot(@v_drag)

      perp.normalize

      @new_rotation = Geo3d::Quaternion.new(perp.x, perp.y, perp.z, w)
    end

    #puts "new_rotation = #{@new_rotation.to_a}"

    @new_rotation
  end

end

notes = <<-EOS
def key_pressed                # @todo select via control_panel instead
  case(key)
  when 'x':
    my_ball.select_axis(X)
  when 'y':
    my_ball.select_axis(Y)
  when 'z':
    my_ball.select_axis(Z)
  end
end

def key_released
  my_ball.select_axis(-1)
end
EOS

