// Ambient color component of vertex
vec4 GetAmbientColor (
  vec4 vAmbientMaterial
)
{
    return vAmbientMaterial * vec4( 0.2, 0.2, 0.2, 1.0 );
}



highp float rand(vec2 co)
{
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt= dot(co.xy ,vec2(a,b));
    highp float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

// Diffuse Color component of vertex
vec4 GetDiffuseColor(
    vec4 vTransformedVertex,  // Position of fragment in model space
    vec4 vNormalInWorldSpace,  // Fragment normal in model space
    vec4 vLightPosition       // Light position in model space

    )
{
    vNormalInWorldSpace = normalize(vNormalInWorldSpace);
    vec3 vNormalizedNormal =  normalize(vec3(vNormalInWorldSpace));
 
    // Get direction of light in Model space
    vec3 vLightDirection  = vec3(vLightPosition - vTransformedVertex);
    vLightDirection   = normalize(vLightDirection);
 
    // Calculate Diffuse intensity
    float fDiffuseIntensity = max( 0.0, dot( vNormalizedNormal, vLightDirection ));
 
    // Calculate resulting Color intensity
    return vec4( fDiffuseIntensity, fDiffuseIntensity, fDiffuseIntensity, 1.0);
}

void shade_analysis()
{ 
  // Final color of the vertex we pass on to the next stage
  vec4 vVaryingColor;


  // Experimentations to show what frag shader does
  //
  // vVaryingColor = vec4(rand(vec2(vFragPosition)));
  
  // vVaryingColor = vec4(
  //     normalize(vec3(
  //      rand(vec2(vFragPosition.x, vFragPosition.y)),
  //      rand(vec2(vFragPosition.y, vFragPosition.z)),
  //      rand(vec2(vFragPosition.z, vFragPosition.x))
  //             )), 
  //    1.0);

  // vVaryingColor = vec4(normalize(vFragPosition));
  // vVaryingColor = vec4(normalize(vNormalInWorldSpace));

  vVaryingColor.a = 1.0;

  return vVaryingColor;
}
