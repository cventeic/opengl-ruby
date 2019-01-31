#version 300 es
//#version 330 core

// This shader is called once for each vertex

// Uniforms are constant for all vertexes in object
//
uniform mat4 model;      // model to world (space) matrix
uniform mat4 view;       // world to eye   (space) matrix
uniform mat4 projection; // eye   to clip  (space) matrix

// Matrix to generate Normal in World Space from Normal in Modle Space
//
// Inverse and transpose are expensive.
// Don't repeat this calc for every vertex or worse every fragment.
//
// Pass in a rotation matrix for
// mat4 normalMatrix = transpose(inverse(modelView));
//
uniform mat4 model_matrix_for_normals;


// Inputs are specific to vertex
//
in vec3 position;   // vertex position in model space
in vec3 normal;     // vertex normal in model space
in vec2 texcoord;  // vertex texture coords in texture space

// Output vars leave vertex shader vertex specific
// but enter frag shader fragment specific
// due to expansion by other shader blocks
//
//out vec4 gl_Position; // Fragment position in clip (2D screen) space
                        // Required by fixed function blocks between vertex and fragment shaders.

out vec4 vFragPositionInWorldSpace; // Fragment Position in World space
out vec4 vFragNormalInWorldSpace; // Fragment Normal in World Space

out vec2 vFragTexCoords;   // Fragment texCoord in texture space


void main()
{
  // Fragment position in clip space
  gl_Position = projection * view *  model * vec4(position, 1.0f);

  // Transform the postion from Model to World space
  vFragPositionInWorldSpace = model * vec4(position, 1.0f);

  vFragNormalInWorldSpace = model_matrix_for_normals * vec4(normal, 1.0f);

  vFragTexCoords = texcoord;
}
