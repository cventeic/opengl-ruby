require 'geo3d'

#######################################################
class Camera
  attr_accessor :view, :perspective

  def initialize
    @view  = Geo3d::Matrix.identity # Ortho
    @view  = Geo3d::Matrix.translation(0.0, 0.0, 50.0 )

    #zoom = 45.0
    #@perspective = Geo3d::Matrix.glu_perspective_degrees(zoom, 4.0/3.0, 0.1, 100.0)

    #@perspective = Geo3d::Matrix.gl_ortho(l, r, b, t, zn, zf)
    @perspective = Geo3d::Matrix.gl_ortho(-20.0, 20.0, -20.0, 20.0, -100.0, 100.0)
  end

  def move(view_change_matrix)
    #@view = @view * view_change_matrix
    @view = view_change_matrix * @view
  end

end    


