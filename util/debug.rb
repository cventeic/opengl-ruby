require 'byebug'

def check_for_gl_error(args={})
  error = Gl.getError()  # Flush any errors
  unless error == 0
    puts "************************************"
    puts "**** gl_error = #{error}"
    puts "**** args: #{args.inspect}"
    puts "**** caller:"
    puts caller

    gl_program_id = args.fetch(:gl_program_id, nil)
    puts "**** gl_program_id: #{gl_program_id}"

    unless gl_program_id.nil?
      puts "**** shader_ids  = #{ Gl.getAttachedShaders(gl_program_id).to_s } "
    end
    puts "************************************"
  end
end
