// Reference shaders below
// RAYMARCHED BALL (iq):  https://www.shadertoy.com/view/ldfSWs
// NOISE (iq): https://www.shadertoy.com/view/4sfGzS#
// CUBEMAP (iq): https://www.shadertoy.com/view/ltl3D8
// SWIRLY STUFF (Antonalog): https://www.shadertoy.com/view/4s23WK
// STAR/FLARE (mu6k): https://www.shadertoy.com/view/4sX3Rs
// RAY V SPHERE (reinder): https://www.shadertoy.com/view/4tjGRh

uniform float iGlobalTime;
uniform vec2 iResolution;

uniform float distort_iterations;
uniform float time_scale; //ru dong

const vec3 col_star = vec3( 1.0, 0.7, 0.5 );
const vec3 pos_star = vec3( 0.0, 9.0, 30.0 );
const vec3 world_up = vec3( 0.0, 1.0, 0.0 );
uniform int firstOctave;
uniform int octaves;
uniform float persistence;
uniform float perlinMagnitude;
uniform float perlinOffset;

uniform float strX;
uniform float strY;
uniform float movX;
uniform float movY;
uniform float Roff;
uniform float Rmut;
uniform float Goff;
uniform float Gmut;
uniform float Boff;
uniform float Bmut;
uniform float Tmut;
uniform float Staralike;
uniform float darkSpots;
uniform float camRot;



uniform float thunderR;
uniform float thunderG;
uniform float thunderB;
uniform float thunderStrength;
uniform float thunderInterval;
uniform float thunderSize;

uniform float perlinDepth;





float noise(int x,int y)
{   
    float fx = float(x);
    float fy = float(y);
    
    return 2.0 * fract(sin(dot(vec2(fx, fy) ,vec2(12.9898,78.233))) * 43758.5453) - 1.0;
}

float smoothNoise(int x,int y)
{
    return noise(x,y)/4.0+(noise(x+1,y)+noise(x-1,y)+noise(x,y+1)+noise(x,y-1))/8.0+(noise(x+1,y+1)+noise(x+1,y-1)+noise(x-1,y+1)+noise(x-1,y-1))/16.0;
}

float COSInterpolation(float x,float y,float n)
{
    float r = n*3.1415926;
    float f = (1.0-cos(r))*0.5;
    return x*(1.0-f)+y*f;
    
}

float InterpolationNoise(float x, float y)
{
    int ix = int(x);
    int iy = int(y);
    float fracx = x-float(int(x));
    float fracy = y-float(int(y));
    
    float v1 = smoothNoise(ix,iy);
    float v2 = smoothNoise(ix+1,iy);
    float v3 = smoothNoise(ix,iy+1);
    float v4 = smoothNoise(ix+1,iy+1);
    
   	float i1 = COSInterpolation(v1,v2,fracx);
    float i2 = COSInterpolation(v3,v4,fracx);
    
    return COSInterpolation(i1,i2,fracy);
    
}

float PerlinNoise2D(float x,float y)
{
    float changeX = x + iGlobalTime * perlinMagnitude + perlinOffset;
    float sum = 0.0;
    float frequency = 0.0;
    float amplitude = 0.0;
    for(int i = 0; i < 9999 ;i++)
    {
        if(i>octaves + firstOctave) {break;}
        if(i < firstOctave) continue;
        frequency = pow(2.0,float(i));
        amplitude = pow(persistence,float(i));
        sum = sum + InterpolationNoise(changeX*frequency,y*frequency)*amplitude;
    }
    
    return sum;
}

    
float hash( float n ) { return fract(sin(n)*123.456789); }

vec2 rotate( in vec2 uv, float a)
{
    float c = cos( a );
    float s = sin( a );
    return vec2( c * uv.x - s * uv.y, s * uv.x + c * uv.y );
}

float noise( in vec3 p )
{
    vec3 fl = floor( p );
    vec3 fr = fract( p );
    fr = fr * fr * ( 3.0 - 2.0 * fr );

    float n = fl.x + fl.y * 157.0 + 113.0 * fl.z;
    return mix( mix( mix( hash( n +   0.0), hash( n +   1.0 ), fr.x ),
                     mix( hash( n + 157.0), hash( n + 158.0 ), fr.x ), fr.y ),
                mix( mix( hash( n + 113.0), hash( n + 114.0 ), fr.x ),
                     mix( hash( n + 270.0), hash( n + 271.0 ), fr.x ), fr.y ), fr.z );
}

float fbm( in vec2 p, float t )
{
    float f;
    t += perlinMagnitude * iGlobalTime;
    f  = 0.5000 * noise( vec3( p, t ) ); p *= 2.1;
    f += 0.2500 * noise( vec3( p, t ) );p *= 2.2;
    f += 0.1250 * noise( vec3( p, t ) );p *= 2.3;
    f += 0.0625 * noise( vec3( p, t ) );
    return f;
}

vec2 field(vec2 p)
{
    float t = time_scale * iGlobalTime;

    p.x += t;

    float n = fbm( p, t );

    float e = 0.25;
    float nx = fbm( p + vec2( e, 0.0 ), t );
    float ny = fbm( p + vec2( 0.0, e ), t );

    return vec2( n - ny, nx - n ) / e;
}

vec3 distort( in vec2 p )
{
    for( float i = 0.0; i < 999.0; ++i )
    {
        p += field( p ) / distort_iterations;
        if(i >= distort_iterations) {
            break;
        }
    }
    //vec3 s = 2.5 * texture2D( iChannel0, vec2( 0.0, p.y * tex_scale ) ).xyz;
	vec3 s = Tmut * vec3(PerlinNoise2D(p.x, p.y) * Rmut + Roff, PerlinNoise2D(p.x, p.y) * Gmut + Goff, PerlinNoise2D(p.x, p.y) * Bmut + Boff);
   // vec3 s = Tmut * vec3();
    return fbm( p, perlinDepth ) * s;
}

vec2 map( in vec2 uv )
{
    uv.x *= strX;
    //rotate ballball
    uv.x += movX * iGlobalTime;
    uv.y *= strY;
    uv.y += movY * iGlobalTime;
    return uv;
}


float doCastSphere( in vec3 p, in vec3 rd )
{
    
    float b = dot( p, rd );
    float c = dot( p, p ) - 1.0;
    
    float f = b * b - c;
    if( f >= 0.0 )
    {
        return -b - sqrt( f );
    }
    return -1.0;
}

// vec3 thunder(in vec2 uv) {
//     float p = (PerlinNoise2D(uv.x * 30.0, uv.y * 30.0));
//     return p * p * p * vec3(1.0,1.0,1.0) * 50.0;
// }


vec3 sunspot(in vec2 uv) {
    float p = (PerlinNoise2D(uv.x * 10.0, uv.y * 10.0));
    return -pow(p, 3.0) * vec3(1.0,1.0,1.0) * darkSpots;
}

vec3 thunder(in vec2 uv) {
    float p = (fbm(uv * thunderSize, iGlobalTime * thunderInterval));
    return (pow(p, 35.0)) * vec3(1.0 + thunderR,1.0 + thunderG,2.0 + thunderB) * thunderStrength;
}

vec3 cloud(in vec3 pos) {
    vec2 uv;
    uv.x = atan( pos.x,  pos.z * 2.0) * 1.5;
    uv.y = asin( pos.y ) + 1.0;
    return vec3(1.5,0.5,0.5);
}

vec2 _uv;
vec3 doMaterial( in vec3 pos )
{
    vec2 uv;
    uv.x = atan( pos.x,  pos.z );
    uv.y = asin( pos.y ) + 1.0;
    _uv = uv;
    vec3 color = sunspot(uv) + distort( map( uv ) );
    return color;
}

vec3 doEffect( in vec3 pos ) {
    return thunder(_uv);
}

vec3 doMaterial2( in vec2 uv )
{
    return distort( map( uv ) );
}

vec3 doLighting( in vec3 n, in vec3 c, in vec3 rd, in vec3 rdc )
{
    vec3  l   = normalize( pos_star + 2.0 * ( pos_star - dot( pos_star, rdc ) * rdc ) );
    float ndl = dot( n, l );
    float ndr = dot( n, -rd );
    float ldr = dot( l, rd );
    float f   = max( ndl, 0.0 ) + Staralike;
    float g   = ldr * smoothstep( 0.0, 0.01, ndr ) * pow( 1.0 - ndr, 10.0 );
    return clamp( f * c + g * col_star, 0.0, 1.1 );
}

// float doFlare( in vec2 uv, in vec2 dir, float s )
// {
//     float d = length( uv - dot( uv, dir ) * dir );
//     float f = 0.0;
//     f += max( pow( 1.0 - d, 128.0 ) * ( 1.0   * s - length( uv ) ), 0.0 );
//     f += max( pow( 1.0 - d,  64.0 ) * ( 0.5   * s - length( uv ) ), 0.0 );
//     f += max( pow( 1.0 - d,  32.0 ) * ( 0.25  * s - length( uv ) ), 0.0 );
//     f += max( pow( 1.0 - d,  16.0 ) * ( 0.125 * s - length( uv ) ), 0.0 );
//     return f;
// }

// float doLensGlint( in vec2 uv, in vec2 c, float r, float w )
// {
//     float l = length( uv - c );
//     return length( c ) * smoothstep( 0.0, w * r, l ) * ( 1.0 - smoothstep( w * r, r, l ) );
// }

mat3 cammat;
vec3 campos;
vec3 camdir;
mat3 cammInv;

vec3 render( in vec2 uv )
{
    // create view ray
    vec3 rd  = cammat * normalize( vec3( uv, 1.0 ) );
    vec3 rdc = cammat * vec3( 0.0, 0.0, 1.0 );
    
    // background stars
    vec3 c = vec3(0.0,0.0,0.0);
    
    // planet
    float t = doCastSphere( campos, rd );
    if( t > 0.0 )
    {
        vec3 pos = campos + t * rd;
        vec3 nor = normalize( pos );
        c = doMaterial( pos );
        c = doLighting( nor, c, rd, rdc );
        c += doEffect( pos );
    }
    return c;
}


vec3 render2( in vec2 uv )
{
    vec3 c = doMaterial2( uv );
    return c;
}


void doCamera( in vec3 pos, in vec3 dir )
{
    campos = pos;
    vec3 ww = dir;
    vec3 uu = normalize( cross( ww, world_up ) );
    vec3 vv = normalize( cross( uu, ww ) );
    mat3 m = mat3( uu, vv, ww );
    mat3 mInv = mat3( uu.x, vv.x, ww.x,
                      uu.y, vv.y, ww.y,
                      uu.z, vv.z, ww.z );
    
	camdir = dir;
    cammat = m;
    cammInv = mInv;
}
void main ()
{
    vec2 uv = gl_FragCoord.xy / iResolution.xy - 0.5;
    uv.x *= iResolution.x / iResolution.y;
    
    // camera default movement
    float cx = cos( camRot * iGlobalTime + 1.1 );
    float sx = sin( camRot * iGlobalTime + 1.1 );
    float cy = 0.;
    
    // camera position/direction
    vec3 camPos = 2. * vec3( cx - sx, cy, sx + cx );
    vec3 camDir = normalize( -camPos );

    // render scene
    vec3 c = vec3(.0, .0, .0);
    doCamera( camPos, camDir );
    c += render( uv ) * 1.0;
    //vec3 c = vec3( distort( map( uv ) ) );
    //vec3 c = vec3( fbm( map( uv ), iGlobalTime ) );
    
    // gamma correction
    c = pow( c, vec3( 0.4545 ) );
    c.r = clamp(c.r, 0.0, 1.0);
    c.g = clamp(c.g, 0.0, 1.0);
    c.b = clamp(c.b, 0.0, 1.0);
    gl_FragColor = vec4( c, 1.0 );
}
