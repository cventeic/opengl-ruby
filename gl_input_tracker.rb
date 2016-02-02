require 'geo3d'

require './camera'
require "./util/arcball"

#######################################################
# Simple input tracking class
class InputTracker
    attr_reader :x, :y, :my_scale
    attr_accessor :camera

    def initialize(width, height)
        @arc_ball =  ArcBall.new(width, height)
        @arc_ball_on = false   
        @x=0
        @y=0
        @frame = false
        @my_scale = 1
        @permenent_view_change_matricies = Array.new
        @camera = Camera.new
    end

    def updated?
        @frame
    end

    def button_callback(window,button,action,mods)
        puts "mouse button_callback #{button}, #{action}, #{mods}"

        @mouse_button_state = action

        case action
        when Glfw::PRESS
            @arc_ball.mouse_pressed(@x,@y)
            @camera_on_click = @camera.clone
            @arc_ball_on = true
        when Glfw::RELEASE
            @arc_ball_on = false 
        end
    end

    def cursor_position_callback(window, x, y)
        @frame = true
        @x = x
        @y = y


        if(@arc_ball_on == true)
            @arc_ball.mouse_dragged(@x,@y)
            quaternion = @arc_ball.compute_rotation_quaternion
            @camera = @camera_on_click.clone
            @camera.move(quaternion.to_matrix)
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
        when Glfw::KEY_A then @my_scale += 1
        when Glfw::KEY_D then @my_scale -= 1
            #when Glfw::KEY_W then [2,  motion]
            #when Glfw::KEY_S then [2, -motion]
            #when Glfw::KEY_A then [0,  motion]
            #when Glfw::KEY_D then [0, -motion]
        end

        @my_scale = 1 if @my_scale < 1
        @my_scale = 10 if @my_scale > 10
    end

    def end_frame
        @frame = false
        @my_scale = 1
    end

end

