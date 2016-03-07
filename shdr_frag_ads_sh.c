#version 300 es
//#version 330 core

precision mediump float;

// Constants for Old Town Square lighting
//
const float C1 = 0.429043;
const float C2 = 0.511664;
const float C3 = 0.743125;
const float C4 = 0.886227;
const float C5 = 0.247708;

const vec3 L00  = vec3( 0.871297, 0.875222, 0.864470);
const vec3 L1m1 = vec3( 0.175058, 0.245335, 0.312891);
const vec3 L10  = vec3( 0.034675, 0.036107, 0.037362);
const vec3 L11  = vec3(-0.004629, -0.029448, -0.048028);
const vec3 L2m2 = vec3(-0.120535, -0.121160, -0.117507);
const vec3 L2m1 = vec3( 0.003242, 0.003624, 0.007511);
const vec3 L20  = vec3(-0.028667, -0.024926, -0.020998);
const vec3 L21  = vec3(-0.077539, -0.086325, -0.091591);
const vec3 L22  = vec3(-0.161784, -0.191783, -0.219152);

struct Light {
    vec3 position;
};

uniform vec4 surface_color;
uniform Light light;

uniform vec4 vEyePosition; // Location of the "Camera" in world space

in vec4 vFragPosition; // Fragment Position in world space
// in vec3 vFragNormal;   // Fragment Normal   in world space

in vec4 vNormalInWorldSpace; // Vertex Normal in World Space
                             // Fragment Normal entering frag shader (after interpolation)
 
// Final color of the vertex we pass on to the next stage
out vec4 vVaryingColor;


// Returns the specular component of the color
//
vec4 GetSpecularColor(
    vec4 vTransformedVertex,  // Position of fragment in model space
    vec4 vNormalInWorldSpace,  // Fragment normal in model space
    vec4 vLightPosition,      // Light position in model space
    vec4 vEyePosition         // Eye postion in model space
    )
{
    // Get the directional vector to the light and to the camera
    // originating from the vertex position
    vec3 vLightDirection  = vec3(vLightPosition - vTransformedVertex);
    vec3 vCameraDirection = vec3(vEyePosition   - vTransformedVertex);

    vLightDirection   = normalize(vLightDirection);
    vCameraDirection  = normalize(vCameraDirection);

    vec3 vNormalizedNormal =  normalize(vec3(vNormalInWorldSpace));
 
    float lambertian = max(dot(vLightDirection,vNormalizedNormal), 0.0);

    float spec = 0.0;

    if(lambertian > 0.0)
    {
      // Blinn phong shading
      //
      vec3 vViewDir = normalize(vec3(-vTransformedVertex));
      vec3 vHalfDir = normalize(vLightDirection + vViewDir);
      float specAngle = max(dot(vHalfDir, vNormalizedNormal), 0.0);
            spec      = pow(specAngle, 16.0);

      // Phong shading
      //
 
      // Calculate the reflection vector between the incoming light and the
      // normal (incoming angle = outgoing angle)
      // We have to use the invert of the light direction because "reflect"
      // expects the incident vector as its first parameter
      vec3 vReflection = reflect( -vLightDirection, vNormalizedNormal);

      // Based on the dot product between the reflection vector and the camera
      // direction.
      //
      // hint: The Dot Product corresponds to the angle between the two vectors
      // hint: if the angle is out of range (0 ... 180 degrees) we use 0.0
      spec = pow( max( 0.0, dot( vCameraDirection, vReflection )), 4.0 );
    }
 
    return vec4( spec, spec, spec, 1.0 );
}

// Diffuse Color component of vertex
// See Old Town Square, OpenGL programming guide
//
vec4 GetDiffuseColorSphericalHarmonics(
    vec4 vTransformedVertex,  // Position of fragment in model space
    vec4 vNormalInWorldSpace  // Fragment normal in model space
    )
{
  //vec3 tnorm = normalize(vec3(vNormalInWorldSpace));
  vec3 tnorm = vec3(vNormalInWorldSpace);

  vec3 diffuse_color = 
    C1 * L22 *(tnorm.x * tnorm.x - tnorm.y * tnorm.y) +
    C3 * L20 * tnorm.z * tnorm.z +
    C4 * L00 -
    C5 * L20 +
    2.0 * C1 * L2m2 * tnorm.x * tnorm.y +
    2.0 * C1 * L21 * tnorm.x * tnorm.z +
    2.0 * C1 * L2m1 * tnorm.y * tnorm.z +
    2.0 * C2 * L11 * tnorm.x +
    2.0 * C2 * L1m1 * tnorm.y +
    2.0 * C2 * L10 * tnorm.z;

  vec4 vDiffuseColor = vec4(diffuse_color, 1.0);
 
  return vDiffuseColor;
}

void main(void)
{
  vec4 vLightPosition = vec4(light.position, 0.0f);

  vec4 diffuseMagnitudes  = GetDiffuseColorSphericalHarmonics(vFragPosition, vNormalInWorldSpace);

  vec4 specularMagnitudes = GetSpecularColor(vFragPosition, vNormalInWorldSpace, vLightPosition, vEyePosition);

  float DiffusePercent  = 0.75; //0.5;
  float SpecularPercent = 0.75;

  vVaryingColor   =
      //mix(vec4(0.0), diffuseMagnitudes  * surface_color, DiffusePercent);
      mix(vec4(0.0), diffuseMagnitudes  * surface_color, DiffusePercent) +
      mix(vec4(0.0), specularMagnitudes * surface_color, SpecularPercent);

  vVaryingColor.a = 1.0;
}
