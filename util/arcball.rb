require 'geo3d'

EPSILON = 1.0e-5

# An Arcball can be thought of as a trackball within the display window.
#
# The trackball is centered in the window and streches from side to side and top
# to bottom
#
# Conceptually the trackball extends out of the window as well.
#
# When you touch any x,y location in the window it's as if your touching the
# same x,y position on the surface of the trackball.
#
# When you then move your touch to another x,y you essentially move the original
# position on the trackball to the new x,y location.
#
#
# compute_sphere_rotation_matrix returns the rotation matrix that could be used
#  to move the arcball sphere to match the touch and drag
#
# The rotation matrix is for the unit sphere / arcball...
#   But can be used to move the camera as well
#

class ArcBall
  #attr_reader :axis, :axis_set

  # width, height = window width and height (apx 1920 x 1080)
  #
  def initialize(width, height)

    assert {width > 1.0 && height > 1.0}  #"Invalid width or height for bounds."

    # window space includes locations in a square plane from
    #   (0, 0, 0) -> (width-1, height-1, 0.0)
    #
    # sphere space includes locations on a unit sphere
    #   center(0.0, 0.0, 0.0), radius(1.0, 1.0, 1.0)

    @conversion_matrix = {}
    @conversion_matrix[:sphere_to_window] = Geo3d::Matrix.viewport(0,0,width,height)
    @conversion_matrix[:window_to_sphere] = @conversion_matrix[:sphere_to_window].inverse

    @sphere_point_when = {}
    @sphere_point_when[:mouse_down]   = Geo3d::Vector.new(0.0)
    @sphere_point_when[:mouse_draged] = Geo3d::Vector.new(0.0)

  end


  # Compute the projection of the user click at (x,y) onto the unit hemishpere facing the user (aka "the arcball").
  #
  # The ball is centered in the middle of the screen.
  #
  # All clicks outside the ball (in the corners) are interpreted as being on the
  #   boundary of the disk facing the user.
  #
  # This won't work if pX^2 + pY^2 > 1, i.e. if the user clicked outside of the ball;
  #   so we interpret these clicks as being on the boundary.
  #
  # Output is vector x, y, z identifying point on sphere of radius 1.0
  #
  def window_to_sphere_space(window_point)

    radius = 1.0

    # window point( x=[0..width], y=[0..height])
    # fix the z and w for matrix math
    window_point.z = 0.0
    window_point.w = 1.0

    # point( x=[-1.0..1.0], y=[-1.0..1.0])
    sphere_point = @conversion_matrix[:window_to_sphere] * window_point

    sphere_point.z = sphere_point.w = 0.0

    x_y_magnitude = sphere_point.x**2 + sphere_point.y**2

    if (x_y_magnitude > 1.0)
      # Point is mapped outside of the sphere space... (length > radius squared)
      # Put x, y inside the sphere but leave z=0.0
      sphere_point.normalize
    else

      # Return a vector to a point mapped inside the sphere
      #
      # Sphere:
      #   pX^2 + pY^2 + pZ^2 = r^2,
      #   pZ^2 = r^2 - (pX^2 + pY^2)
      #   pZ   = sqrt(r^2 - (pX^2 + pY^2))
      #
      sphere_point.z = Math.sqrt((radius * radius) - x_y_magnitude)
    end

    return sphere_point
  end

  # This is where we first make contact with the virtual arcball
  #
  def mouse_pressed(x, y)
    window_point = Geo3d::Vector.new(x,y)

    @sphere_point_when[:mouse_down] = window_to_sphere_space(window_point)
    @sphere_point_when[:mouse_draged] = @sphere_point_when[:mouse_down]
  end

  # This is where we have rotated the arcball to since making contact
  def mouse_dragged(x, y)
    window_point = Geo3d::Vector.new(x,y)

    @sphere_point_when[:mouse_draged] = window_to_sphere_space(window_point)
  end

  # Returns rotation matrix to
  #  rotate the unit sphere from the point where the touch was initiated
  #  to the current point being touched in the window
  #
  def compute_sphere_rotation_matrix

    # Perp vector is the axis of rotation of the sphere
    #   as we roll the arcball from point A to point B
    #
    #perp = @sphere_point_when[:mouse_down].cross(@sphere_point_when[:mouse_draged])
    v_perp = @sphere_point_when[:mouse_draged].cross(@sphere_point_when[:mouse_down])

    # Just return the identity if we didn't move significantly
    #return Geo3d::Matrix.identity if (v_perp.length < EPSILON)

    v_perp.normalize

    # In the quaternion values,
    #  w is cosine (theta / 2), where theta is rotation angle
    #
    v_perp.w = @sphere_point_when[:mouse_down].dot(@sphere_point_when[:mouse_draged])

    # Compute new rotation matrix
    q = Geo3d::Quaternion.new(v_perp.x, v_perp.y, v_perp.z, v_perp.w)

    # arc_ball_rotation_matrix
    q.to_matrix
  end

end
