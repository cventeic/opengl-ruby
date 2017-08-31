# A sample Guardfile
# More info at https://github.com/guard/guard#readme

# Add files and commands to this file, like the example:
#   watch(%r{file/path}) { `command(s)` }
#
# `rvm ruby-2.0.0-p0 do ruby -w #{m[0]}"`
guard 'shell' do

    pid = 0

    watch /(.*\.rb)$/ do |m| 
      n m[0], 'Changed'

      Process.kill("TERM", pid) unless pid == 0

      pid = fork do
        # this code is run in the child process
        # you can do anything here, like changing current directory or reopening STDOUT
        #exec "rvm default do ruby -w ./obj_example.rb"
        exec "rvm default do ruby -w ./testgl.rb"
      end
    end
end

