def getShaderCodeVertex()
vertexShaderCode = <<-EOS
#version 300 es

// This code is called once for each vertex

// Input vertex data (different for each vertex)
in vec3 vertexPosition_modelspace;
in vec2 vertexUV;
in vec3 vertexNormal_modelspace;

// Output data (will be interpolated for each fragment).
out vec2 UV;
out vec3 Position_worldspace;
out vec3 Normal_cameraspace;
out vec3 EyeDirection_cameraspace;
out vec3 LightDirection_cameraspace;

// Uniform values that stay constant for the whole mesh of vertices.
uniform mat4 MVP;
uniform mat4 V;
uniform mat4 M;
uniform vec3 LightPosition_worldspace;

void main(){

  // Output position of the vertex, in clip space : MVP * position
  gl_Position =  MVP * vec4(vertexPosition_modelspace,1);

  // Position of the vertex, in worldspace : M * position
  Position_worldspace = (M * vec4(vertexPosition_modelspace,1)).xyz;

  // Vector that goes from the vertex to the camera, in camera space.
  // In camera space, the camera is at the origin (0,0,0).
  vec3 vertexPosition_cameraspace = ( V * M * vec4(vertexPosition_modelspace,1)).xyz;
  EyeDirection_cameraspace = vec3(0,0,0) - vertexPosition_cameraspace;

  // Vector that goes from the vertex to the light, in camera space. M is ommited because it's identity.
  vec3 LightPosition_cameraspace = ( V * vec4(LightPosition_worldspace,1)).xyz;
  LightDirection_cameraspace = LightPosition_cameraspace + EyeDirection_cameraspace;

  // Normal of the the vertex, in camera space
  Normal_cameraspace = ( V * M * vec4(vertexNormal_modelspace,0)).xyz; // Only correct if ModelMatrix does not scale the model ! Use its inverse transpose if not.

  // UV of the vertex. No special space for this one.
  UV = vertexUV;
}
EOS
end

def getShaderCodeFragment()
fragmentShaderCode = <<-EOS
#version 300 es
precision mediump float;

// Input interpolated values for each vertex (input is output of vertex shader code called for each vertex)
in vec2 UV;
in vec3 Position_worldspace;
in vec3 Normal_cameraspace;
in vec3 EyeDirection_cameraspace;
in vec3 LightDirection_cameraspace;

// Output color for each vertex
// cv - note this is vec4 in some examples
out vec4 color;

// Uniform values that stay constant for the whole mesh.
//uniform sampler2D myTextureSampler;
uniform mat4 MV;
uniform vec3 LightPosition_worldspace;

void main(){

  // Light emission properties
  // You probably want to put them as uniforms
  vec3 LightColor = vec3(1,1,1);
  float LightPower = 100.0f;

  // Material properties
  //vec3 MaterialDiffuseColor = texture2D( myTextureSampler, UV ).rgb;
  vec3 MaterialDiffuseColor = vec3(1.0,1.0,1.0);
  //vec3 MaterialAmbientColor = vec3(0.1,0.1,0.1) * MaterialDiffuseColor;
  vec3 MaterialAmbientColor = vec3(0.5,0.5,0.5) * MaterialDiffuseColor;
  vec3 MaterialSpecularColor = vec3(0.3,0.3,0.3);

  // Distance to the light
  float distance = length( LightPosition_worldspace - Position_worldspace );

  // Normal of the computed fragment, in camera space
  vec3 n = normalize( Normal_cameraspace );

  // Direction of the light (from the fragment to the light)
  vec3 l = normalize( LightDirection_cameraspace );

  // Cosine of the angle between the normal and the light direction,
  // clamped above 0
  //  - light is at the vertical of the triangle -> 1
  //  - light is perpendicular to the triangle -> 0
  //  - light is behind the triangle -> 0
  float cosTheta = clamp( dot( n,l ), 0,1 );

  //calculate the cosine of the angle of incidence (brightness)
  //float brightness = dot(normal, surfaceToLight) / (length(surfaceToLight) * length(normal));
  // brightness = clamp(brightness, 0, 1);

  // Eye vector (towards the camera)
  vec3 E = normalize(EyeDirection_cameraspace);

  // Direction in which the triangle reflects the light
  vec3 R = reflect(-l,n);

  // Cosine of the angle between the Eye vector and the Reflect vector, clamped to 0
  //  - Looking into the reflection -> 1
  //  - Looking elsewhere -> < 1
  float cosAlpha = clamp( dot( E,R ), 0,1 );

  vec3 ccolor =
    // Ambient : simulates indirect lighting
    MaterialAmbientColor +
    // Diffuse : "color" of the object
    MaterialDiffuseColor * LightColor * LightPower * cosTheta / (distance*distance) +
    // Specular : reflective highlight, like a mirror
    MaterialSpecularColor * LightColor * LightPower * pow(cosAlpha,5) / (distance*distance);

  color = vec4(ccolor, 1.0);

  vec3 fragVertexEc = Position_worldspace;
  vec3 X = dFdx(fragVertexEc);
  vec3 Y = dFdy(fragVertexEc);
  vec3 normal=normalize(cross(X,Y));

  color = vec4(normal, 1.0);
}
EOS
end


