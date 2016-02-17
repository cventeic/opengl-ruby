require 'geo3d'

require './camera'
require "./util/arcball"

#######################################################
# Simple input tracking class
class InputTracker
    attr_accessor :camera


    # width, height = window width and height (apx 1920 x 1080)
    def initialize(width, height)
        @arc_ball =  ArcBall.new(width, height)
        @arc_ball_moving = false   
        @x=0
        @y=0
        @frame = false
        @camera = Camera.new
    end

    def updated?
        @frame
    end

    def button_press()
        @arc_ball_moving = true

        @arc_ball.mouse_pressed(@x,@y)

        @camera_before_arcball_touched = @camera.clone
    end

    def button_release()

        @arc_ball_moving = false 
    end

    def cursor_position_callback(window, x, y)
        @frame = true
        @x = x
        @y = y

        if(@arc_ball_moving == true)
            @arc_ball.mouse_dragged(@x,@y)
            arc_ball_rotation_matrix = @arc_ball.compute_sphere_rotation_matrix

            # All movements are delta on the position when we first touched the
            # arcball
            @camera = @camera_before_arcball_touched.clone

            # Rotate the camera space around origin (0.0, 0.0, 0.0) 
            @camera.move(arc_ball_rotation_matrix)
        end

    end

    def key_callback(window, key, code, action, mods)
        @frame = true
        case action
            #when Glfw::PRESS then 1
        when Glfw::RELEASE then @arc_ball.select_axis(-1)
        end

        case key
        when Glfw::KEY_X then @arc_ball.select_axis(X)
        when Glfw::KEY_Y then @arc_ball.select_axis(Y)
        when Glfw::KEY_Z then @arc_ball.select_axis(Z)
        #when Glfw::KEY_W then [2,  motion]
        #when Glfw::KEY_S then [2, -motion]
        #when Glfw::KEY_A then [0,  motion]
        #when Glfw::KEY_D then [0, -motion]
        end
    end

    def end_frame
        @frame = false
    end

end

