//These are all SDFs shamelessly stolen from here:
//				https://iquilezles.org/articles/distfunctions/
//Thank you Inigo Quilez for your awesome work!!

//Fancy Operations
//This one is fun cause I grabbed it here: https://www.shadertoy.com/view/Ml3fWj

vec4 opElongate( in vec3 p, in vec3 h ){
    vec3 q = abs(p)-h;
    return vec4( max(q,0.0), min(max(q.x,max(q.y,q.z)),0.0) );
}

float opRound( in float primitive, float rad ){
    return primitive - rad;
}

float opOnion( in float sdf, in float thickness ){
    return abs(sdf)-thickness;
}

struct Ray{
	float dist;
	vec3 dir;
	vec3 pos;
	int iterations;
	bool hit;
	float id;
	bool inside_bh;
	vec3 vol_color;
	float transmittance;
};

struct Surface{
	float dist;
	float id;
};

float opUnion( float d1, float d2 ){
    return min(d1,d2);
}

Surface opUnion( Surface a, Surface b ){
   	Surface res;
	float factor = step(b.dist, a.dist);
	res.dist = min(a.dist, b.dist);
	res.id = mix(a.id, b.id, factor);
	return res;
}

float opSmoothUnion( float d1, float d2, float k ){
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

float opSmoothUnion( float d1, float d2, float k, int id1, int id2 ){
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

const int op_subtraction = 6;
float opSubtraction( float d1, float d2 ){
    return max(d1,-d2);
}

const int op_smooth_subtraction = 7;
float opSmoothSubtraction( float d1, float d2, float k ){
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h);
}

const int op_intersection = 8;
float opIntersection( float d1, float d2 ){
    return max(d1,d2);
}

const int op_smooth_intersection = 9;
float opSmoothIntersection( float d1, float d2, float k ){
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h);
}

const int op_xor = 10;
float opXor(float d1, float d2 ){
    return max(min(d1,d2),-max(d1,d2));
}


//FIXME :: In the refence anything after "positioning"
//the original functions get an "sdf3d primitive" as one of their
//function parameters. Passing a function into another function is
//not possible in godot so some thinking is gonna need to be done here

//opTranslate and opScale are both incuded by default as transformations
//defined by the SDFObj
vec3 opTransform( in vec3 p, in mat4 t){
	vec4 _p = vec4(p.xyz, 1);
    return  (inverse(t)*_p).xyz;
}
//Symmetry

//slightly modified so we do the operations before instead of after the symmetry
vec3 opSymX( in vec3 p){
    p.x = abs(p.x);
    return p;
}

vec3 opSymXZ( in vec3 p )
{
    p.xz = abs(p.xz);
    return p;
}

//Repititions

//This might be really bad way to do it tbh, like I think this isn't doing the domain bs here????
//I dunno I'm a beginner raymarcher, and all of these are stolen and slightly modified
vec3 opRepetition( in vec3 p, in vec3 s ){
    vec3 q = p - s*round(p/s);
    return q;
}


vec3 opLimitedRepetition( in vec3 p, in float s, in vec3 l ){
    vec3 q = p - s*clamp(round(p/s),-l,l);
    return q;
}

//displacement

//They both need to be along the same point tho
float opDisplace( in float primitive, in float displacement ){
    float d1 = primitive;
    float d2 = displacement;
    return d1+d2;
}

vec3 opTwist(  in vec3 p, float k ){
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2  m = mat2(vec2(c,-s) ,vec2(s,c));
    vec3  q = vec3(m*p.xz,p.y);
    return q;
}

vec3 opCheapBend( in vec3 p , float k){
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(vec2(c,-s), vec2(s,c));
    vec3  q = vec3(m*p.xy,p.z);
    return q;
}