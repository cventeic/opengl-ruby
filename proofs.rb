require 'geo3d'
require './util/gl_math_util.rb'

require 'minitest/autorun'

class BugTest < Minitest::Test

  def test_quaternion_x_y_z_w_cant_be_initialized_directly

    rotation_axis  = Geo3d::Vector.new(0.0, 1.0, 0.0)
    rotation_axis.w = 0 #  Zero Degrees
    
    q = Geo3d::Quaternion.new(*rotation_axis)

    assert Geo3d::Matrix.identity != q.to_matrix 
  end

  def test_quartenion_no_rotation

    rotation_axis  = Geo3d::Vector.new(0.0, 1.0, 0.0)
    radians = 0.0
    
    q = Geo3d::Quaternion.from_axis(rotation_axis, radians)

    assert_equal Geo3d::Matrix.identity, q.to_matrix 
  end

  def test_quartenion_with_rotation

    rotation_axis  = Geo3d::Vector.new(0.0, 1.0, 0.0)

    radians = radians(rand(360)) # pick a random rotation
    
    q = Geo3d::Quaternion.from_axis(rotation_axis, radians)

    expected_matrix = Geo3d::Matrix.rotation_y radians

    assert_equal expected_matrix, q.to_matrix 

    test_vector = Geo3d::Vector.new(1.0, 0.0, 0.0)

    expected_out_vector = expected_matrix * test_vector

    actual_out_vector   = q.to_matrix * test_vector

    assert_equal expected_out_vector, actual_out_vector
  end

  def test_cross_product
    v_x = Geo3d::Vector.new(1.0, 0.0, 0.0)
    v_y = Geo3d::Vector.new(0.0, 1.0, 0.0)
    v_z = Geo3d::Vector.new(0.0, 0.0, 1.0)

    v_perp   = v_z.cross(v_x) # thumb rule... z -> x == y

    assert_equal v_y, v_perp
  end

end


