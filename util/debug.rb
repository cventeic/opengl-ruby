require 'byebug'

def check_for_gl_error(args={})
  error = Gl.getError()  # Flush any errors
  unless error == 0
    puts "gl_error = #{error}"
    puts args.inspect
    puts caller
  end
end
