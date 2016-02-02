require 'geo3d'

#######################################################
class Camera
  attr_accessor :model, :view, :perspective

  def initialize
    #@model = Geo3d::Matrix.identity(4)
    @model = Geo3d::Matrix.identity
    #@view  = Matrix.identity(4)
    #@view  = Geo3d::Matrix.identity
    @view  = Geo3d::Matrix.uniform_scaling(0.05)

    #@perspective = Geo3d::Matrix.identity(4) # Ortho
    @perspective = Geo3d::Matrix.identity # Ortho
  end

  def move(view_change_matrix)
    @view = @view * view_change_matrix
    #@view = view_change_matrix * @view
  end

  def mvp
    @perspective * @view * @model
  end

  # Projection matrix : 45° Field of View, 4:3 ratio, display range : 0.1 unit <-> 100 units
  #fov, aspect, zNear, zFar  = 45.0, 4.0/3.0, 0.1, 100.0
  #fov, aspect, zNear, zFar  = 90.0, 4.0/3.0, 0.1, 100.0
  #@geometry[:perspective] = pperspective( fov, aspect, zNear, zFar)
  #
  def unproject(x,y,z, w,h)
    # vec3    const & win,
    # mat4x4  const & model,
    # mat4x4  const & proj,
    # vec4    const & viewport

    #puts "unproject #{x}, #{y}, #{z}, #{w}, #{h}"

    win      = [x, h- y - 1, z]
    viewport = [0, 0, w, h]

    tmp = Array.new
    tmp[0] = (win[0] - viewport[0]) / viewport[2]
    tmp[1] = (win[1] - viewport[1]) / viewport[3]
    tmp[2] =  win[2]
    tmp[3] =  1.0  #?

    tmp.map! {|t| t * 2.0 - 1.0}

    unviewMat = (@perspective * @view * @model).inverse
    obj = unviewMat * Geo3d::Matrix.column_vector(tmp)
    world_point = obj.column(0).to_a

    world_point.map! {|o| o / world_point[3]} # obj /= obj.w

    return world_point 
  end
end    


