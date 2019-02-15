
# OpenGL 3D graphics written in Ruby

- Programatic shaders with diffuse and specular lighting.
- Arcball and Quaterion implemented in Ruby code.
- Basic shape rendering in Ruby code.
- Buffer management in Ruby.


# Demo:
  - bundle install
  - bundle exec ruby testgl.rb

[![testgl.rb Screen Capture](https://img.youtube.com/vi/_8pJCWOsiIo/0.jpg)](https://www.youtube.com/watch?v=_8pJCWOsiIo "bundle exec ruby testgl.rb Screen Capture")

# Install:
  - Prereqs: libsdl2-dev

# Data Structures

  Aggregate:
  - Job to perform on the CPU to produce a set of meshes used by the GPU to render a specific
      graphical object.
  - Each mesh can have different colors or textures or be rendered by a different shader.
  - The Aggregate encapsulates other Aggregates to render a composite
      object.

  Gpu_Mesh_Job:
  - Job performed by the GPU to render a mesh with a specific shader and color /
      texture.


  Cpu_Graphical_Object:
  - Depricated.  Original representation for Aggregate.
  - Does not support compositing of objects from parts.


# Files

# ToDo:

