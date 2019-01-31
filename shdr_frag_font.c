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

// Uniforms are constant for all fragments (pixels) in object
uniform vec4 surface_color; //
uniform Light light;        // Position of light in world space
uniform vec4 vEyePosition;  // Position of camera in world space

// Inputs are specific to fragment (pixel)
in vec4 vFragPositionInWorldSpace; // Fragment Position in world space
in vec4 vFragNormalInWorldSpace; // Vertex Normal in World Space

out vec4 vVaryingColor; // Final color of the fragment (pixel)


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


//Shader Inputs
//uniform vec3      iResolution;           // viewport resolution (in pixels)
//uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
//uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube

#define line1 h_ e_ l_ l_ o_ _ s_ h_ a_ d_ e_ r_ t_ o_ y_ crlf
#define line2 t_ h_ i_ s_ _ i_ s_ _ m_ y_ _ f_ o_ n_ t_ crlf
#define line3 h_ o_ p_ e_ _ y_ o_ u_ _ l_ i_ k_ e_ _ i_ t_ crlf
#define line4 f_ e_ e_ l_ _ f_ r_ e_ e_ _ t_ o_ _ u_ s_ e_ crlf
#define line5 _ a_ b_ c_ d_ e_ f_ g_ h_ i_ j_ k_ l_ m_ crlf
#define line6 _ n_ o_ p_ q_ r_ s_ t_ u_ v_ w_ x_ y_ z_

// line function, used in k, s, v, w, x, y, z
float line(vec2 p, vec2 a, vec2 b)
{
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

//These functions are re-used by multiple letters
float _u(vec2 uv,float w,float v) {
    return length(vec2(
                abs(length(vec2(uv.x,
                                max(0.0,-(.4-v)-uv.y) ))-w)
               ,max(0.,uv.y-.4))) +.4;
}
float _i(vec2 uv) {
    return length(vec2(uv.x,max(0.,abs(uv.y)-.4)))+.4;
}
float _j(vec2 uv) {
    uv.x+=.2;
    float t = _u(uv,.25,-.15);
    float x = uv.x>0.?t:length(vec2(uv.x,uv.y+.8))+.4;
    return x;
}
float _l(vec2 uv) {
    uv.y -= .2;
    return length(vec2(uv.x,max(0.,abs(uv.y)-.6)))+.4;
}
float _o(vec2 uv) {
    return abs(length(vec2(uv.x,max(0.,abs(uv.y)-.15)))-.25)+.4;
}

// Here is the alphabet
float aa(vec2 uv) {
    uv = -uv;
    float x = abs(length(vec2(max(0.,abs(uv.x)-.05),uv.y-.2))-.2)+.4;
    x = min(x,length(vec2(uv.x+.25,max(0.,abs(uv.y-.2)-.2)))+.4);
    return min(x,(uv.x<0.?uv.y<0.:atan(uv.x,uv.y+0.15)>2.)?_o(uv):length(vec2(uv.x-.22734,uv.y+.254))+.4);
}
float bb(vec2 uv) {
    float x = _o(uv);
    uv.x += .25;
    return min(x,_l(uv));
}
float cc(vec2 uv) {
    float x = _o(uv);
    uv.y= abs(uv.y);
    return uv.x<0.||atan(uv.x,uv.y-0.15)<1.14?x:length(vec2(uv.x-.22734,uv.y-.254))+.4;
}
float dd(vec2 uv) {
    uv.x *= -1.;
    return bb(uv);
}
float ee(vec2 uv) {
    float x = _o(uv);
    return min(uv.x<0.||uv.y>.05||atan(uv.x,uv.y+0.15)>2.?x:length(vec2(uv.x-.22734,uv.y+.254))+.4,
               length(vec2(max(0.,abs(uv.x)-.25),uv.y-.05))+.4);
}
float ff(vec2 uv) {
    uv.x *= -1.;
    uv.x += .05;
    float x = _j(vec2(uv.x,-uv.y));
    uv.y -= .4;
    x = min(x,length(vec2(max(0.,abs(uv.x-.05)-.25),uv.y))+.4);
    return x;
}
float gg(vec2 uv) {
    float x = _o(uv);
    return min(x,uv.x>0.||uv.y<-.65?_u(uv,0.25,-0.2):length(vec2(uv.x+0.25,uv.y+.65))+.4 );
}
float hh(vec2 uv) {
    uv.y *= -1.;
    float x = _u(uv,.25,.25);
    uv.x += .25;
    uv.y *= -1.;
    return min(x,_l(uv));
}
float ii(vec2 uv) {
    return min(_i(uv),length(vec2(uv.x,uv.y-.7))+.4);
}
float jj(vec2 uv) {
    uv.x += .05;
    return min(_j(uv),length(vec2(uv.x-.05,uv.y-.7))+.4);
}
float kk(vec2 uv) {
    float x = line(uv,vec2(-.25,-.1), vec2(0.25,0.4))+.4;
    x = min(x,line(uv,vec2(-.15,.0), vec2(0.25,-0.4))+.4);
    uv.x+=.25;
    return min(x,_l(uv));
}
float ll(vec2 uv) {
    return _l(uv);
}
float mm(vec2 uv) {
    //uv.x *= 1.4;
    uv.y *= -1.;
    uv.x-=.175;
    float x = _u(uv,.175,.175);
    uv.x+=.35;
    x = min(x,_u(uv,.175,.175));
    uv.x+=.175;
    return min(x,_i(uv));
}
float nn(vec2 uv) {
    uv.y *= -1.;
    float x = _u(uv,.25,.25);
    uv.x+=.25;
    return min(x,_i(uv));
}
float oo(vec2 uv) {
    return _o(uv);
}
float pp(vec2 uv) {
    float x = _o(uv);
    uv.x += .25;
    uv.y += .4;
    return min(x,_l(uv));
}
float qq(vec2 uv) {
    uv.x = -uv.x;
    return pp(uv);
}
float rr(vec2 uv) {
    float x =atan(uv.x,uv.y-0.15)<1.14&&uv.y>0.?_o(uv):length(vec2(uv.x-.22734,uv.y-.254))+.4;

    //)?_o(uv):length(vec2(uv.x-.22734,uv.y+.254))+.4);

    uv.x+=.25;
    return min(x,_i(uv));
}
float ss(vec2 uv) {

    if (uv.y <.145 && uv.x>0. || uv.y<-.145)
        uv = -uv;

    float x = atan(uv.x-.05,uv.y-0.2)<1.14?
                abs(length(vec2(max(0.,abs(uv.x)-.05),uv.y-.2))-.2)+.4:
                length(vec2(uv.x-.231505,uv.y-.284))+.4;
    return x;
}
float tt(vec2 uv) {
    uv.x *= -1.;
    uv.y -= .4;
    uv.x += .05;
    float x = min(_j(uv),length(vec2(max(0.,abs(uv.x-.05)-.25),uv.y))+.4);
    return x;
}
float uu(vec2 uv) {
    return _u(uv,.25,.25);
}
float vv(vec2 uv) {
    uv.x=abs(uv.x);
    return line(uv,vec2(0.25,0.4), vec2(0.,-0.4))+.4;
}
float ww(vec2 uv) {
    uv.x=abs(uv.x);
    return min(line(uv,vec2(0.3,0.4), vec2(.2,-0.4))+.4,
               line(uv,vec2(0.2,-0.4), vec2(0.,0.1))+.4);
}
float xx(vec2 uv) {
    uv=abs(uv);
    return line(uv,vec2(0.,0.), vec2(.3,0.4))+.4;
}
float yy(vec2 uv) {
    return min(line(uv,vec2(.0,-.2), vec2(-.3,0.4))+.4,
               line(uv,vec2(.3,.4), vec2(-.3,-0.8))+.4);
}
float zz(vec2 uv) {
    float l = line(uv,vec2(0.25,0.4), vec2(-0.25,-0.4))+.4;
    uv.y=abs(uv.y);
    float x = length(vec2(max(0.,abs(uv.x)-.25),uv.y-.4))+.4;
    return min(x,l);
}

// Spare Q :)
float Q(vec2 uv) {

    float x = _o(uv);
    uv.y += .3;
    uv.x -= .2;
    return min(x,length(vec2(abs(uv.x+uv.y),max(0.,abs(uv.x-uv.y)-.2)))/sqrt(2.) +.4);
}

//Render char if it's up
#define ch(l) if (nr++==ofs) x=min(x,l(uv));

//Make it a bit easier to type text
#define a_ ch(aa);
#define b_ ch(bb);
#define c_ ch(cc);
#define d_ ch(dd);
#define e_ ch(ee);
#define f_ ch(ff);
#define g_ ch(gg);
#define h_ ch(hh);
#define i_ ch(ii);
#define j_ ch(jj);
#define k_ ch(kk);
#define l_ ch(ll);
#define m_ ch(mm);
#define n_ ch(nn);
#define o_ ch(oo);
#define p_ ch(pp);
#define q_ ch(qq);
#define r_ ch(rr);
#define s_ ch(ss);
#define t_ ch(tt);
#define u_ ch(uu);
#define v_ ch(vv);
#define w_ ch(ww);
#define x_ ch(xx);
#define y_ ch(yy);
#define z_ ch(zz);

//Space
#define _ nr++;

//Next line
#define crlf uv.y += 2.0; nr = 0.;



void main(void)
{
  vec4 vLightPosition = vec4(light.position, 0.0f);

  vec4 diffuseMagnitudes  = GetDiffuseColorSphericalHarmonics(vFragPositionInWorldSpace, vFragNormalInWorldSpace);

  vec4 specularMagnitudes = GetSpecularColor(vFragPositionInWorldSpace, vFragNormalInWorldSpace, vLightPosition, vEyePosition);

  float DiffusePercent  = 0.75; //0.5;
  float SpecularPercent = 0.75;

  DiffusePercent  = 0.45; //0.5;
  SpecularPercent = 0.45;

  vVaryingColor   =
      //mix(vec4(0.0), diffuseMagnitudes  * surface_color, DiffusePercent);
      mix(vec4(0.0), diffuseMagnitudes  * surface_color, DiffusePercent) +
      mix(vec4(0.0), specularMagnitudes * surface_color, SpecularPercent);

  vVaryingColor.a = 1.0;

  vec3 iResolution = vec3( 1920.0, 1080.0, 1.0);           // viewport resolution (in pixels)

  float scale = 1.0;//3.5-3.0*sin(iTime*.2);
  //vec2 uv = (vFragPosition.xy-0.5*iResolution.xy) / iResolution.x * 22.0 * scale;
  //vec2 uv = (fragCoord-0.5*iResolution.xy) / iResolution.x * 22.0 * scale;
  vec2 uv = (gl_FragCoord.xy-0.5*iResolution.xy) / iResolution.x * 22.0 * scale;


  float ofs = floor(uv.x)+8.;
  uv.x = mod(uv.x,1.0)-.5;
  float x = 100.;
  float nr = 0.;
  uv.y -= 5.;

  line1;
  line2;
  line3;
  line4;
  line5;
  line6;

  vec3 clr = vec3(0.0);

  //float px = 17.0/iResolution.x*pz_scale;
  float px = 17.0/iResolution.x*1.0;

  clr.r = 0.7-0.7*smoothstep(0.49-px,0.49+px, x); // The body
  clr.g = 0.7-0.7*smoothstep(0.00,px*1.5, abs(x-0.49+px)); // Yellow outline
  clr.b = 0.4-0.4*smoothstep(0.43,0.53,1.0-x); // Background with shadow
  clr.rg += 0.12-0.12*smoothstep(0.00,0.1+px, abs(x-0.49+px)); // Yellow glow

  //if (iMouse.w>0.1) {
  //clr.rgb = vec3(smoothstep(0.49-px,0.49+px, x));
  //}

  vVaryingColor = vec4(clamp(clr,0.0,1.0),1.0); // fragcoor
}
