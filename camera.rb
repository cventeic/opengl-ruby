require 'geo3d'

#######################################################
class Camera
  attr_accessor :world_to_camera_space, :perspective

  def initialize(aspect_ratio: 1.0)

    # Remember,
    # view matrix moves points in world space to camera space
    # ex.
    # World Space:  Point(  0,0), Camera(10,0)
    # Camera Space: Point(-10,0), Camera(0,0)
    #  -- the view matrix must subtract 10 from x position

    @world_to_camera_space  = Geo3d::Matrix.translation(0.0, 0.0, -10.0 )

    # Geo3d::Matrix.glu_perspective_degrees fovy, aspect, zn, zf #returns an opengl style right handed perspective projection matrix
    # Geo3d::Matrix.gl_frustum l, r, b, t, zn, zf #returns an opengl style right handed perspective projection matrix
    # Geo3d::Matrix.gl_ortho l, r, b, t, zn, zf  #returns an opengl style righthanded orthographic projection matrix

    # Remember, the z near and far are always in camera space and always positive
    zoom = 60.0
    @perspective = Geo3d::Matrix.glu_perspective_degrees(zoom, aspect_ratio, 2.0, 100.0)

    #@perspective = Geo3d::Matrix.gl_ortho(l, r, b, t, zn, zf)
    #@perspective = Geo3d::Matrix.gl_ortho(-20.0, 20.0, -20.0, 20.0, -100.0, 100.0)
  end

  def move_camera_in_world_space(view_change_matrix)
    @world_to_camera_space = view_change_matrix * @world_to_camera_space
  end

  def move_camera_in_camera_space(camera_transform_camera_space)

    world_to_camera_matrix = @world_to_camera_space.dup
    puts "world_to_camera_space matrix= \n#{world_to_camera_matrix.to_s_round}"

=begin
    camera_to_world_matrix = world_to_camera_matrix.inverse
    puts "camera_to_world_matrix inverse = \n#{camera_to_world_matrix.to_s_round}"

    camera_to_world_matrix = camera_to_world_matrix.transpose
    puts "camera_to_world_matrix inverse transpose= \n#{camera_to_world_matrix.to_s_round}"

    puts "matrix for camera movement in camera space:"
    puts "camera_transform_camera_space = \n#{camera_transform_camera_space.to_s_round}"

    puts "this is the matrix to apply to view matrix:"
    camera_transform_world_space = camera_to_world_matrix * camera_transform_camera_space
    puts "camera_transform_matrix_world = \n#{camera_transform_matrix_world.to_s_round}"
=end
    
    #@world_to_camera_space = camera_transform_camera_space * @world_to_camera_space 
    @world_to_camera_space = @world_to_camera_space * camera_transform_camera_space 

    #move_in_world_space(camera_transform_matrix_world)
    puts "this is then new view matrix: "
    puts "view = \n#{@world_to_camera_space.to_s_round}"
  end

  def camera_location_in_world_space

    vec_camera_location_camera_space = Geo3d::Vector.new(0.0, 0.0, 0.0, -1.0)

    matrix            = @world_to_camera_space.dup
    inverse           = matrix.inverse
    inverse_transpose = inverse.transpose
  
    vec_camera_location_in_world_space = inverse_transpose * vec_camera_location_camera_space

    vec_camera_location_in_world_space.w  = 0.0

    # puts "camera in world = #{vec_camera_location_in_world_space.to_s_round}"

    vec_camera_location_in_world_space
  end


end    


