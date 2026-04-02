//These are all SDFs shamelessly stolen from here:
//				https://iquilezles.org/articles/distfunctions/
//Thank you Inigo Quilez for your awesome work!!

float dot2( in vec3 v ) { return dot(v,v); }
float ndot( in vec3 a, in vec3 b ) { return a.x*b.x - a.y*b.y; }

const int SHAPE_SPHERE = 1;
float sdSphere( vec3 p, float s ){
  return length(p) - s;
}

float sdOutsideSphere( vec3 p, float s ){
  return  length(p) - s;
}

const int SHAPE_BOX = 2;
float sdBox( vec3 p, vec3 b ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

const int SHAPE_BOX_FRAME = 3;
float sdBoxFrame( vec3 p, vec3 b, float e ){
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

const int SHAPE_TORUS = 4;
float sdTorus( vec3 p, vec2 t ){
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdCappedTorus( vec3 p, vec2 sc, float ra, float rb){
  p.x = abs(p.x);
  float k = (sc.y*p.x>sc.x*p.y) ? dot(p.xy,sc) : length(p.xy);
  return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

const int SHAPE_CONE = 6;
float sdCone( vec3 p, vec2 c, float h ){
  float q = length(p.xz);
  return max(dot(c.xy,vec2(q,p.y)),-h-p.y);
}

const int SHAPE_CYLINDER = 7;
float sdCylinder( vec3 p, vec3 c ){
  return length(p.xz-c.xy)-c.z;
}

float sdCappedCylinder( vec3 p, float r, float h ){
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

const int SHAPE_PLANE = 8;
float sdPlane( vec3 p, vec3 n, float h ){
  // n must be normalized
  return dot(p,n) + h;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r ){
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

const int SHAPE_CAPSULE = 9;
float sdVerticalCapsule( vec3 p, float h, float r ){
  p.y -= clamp( p.y, -h/2., h/2. );
  return length( p ) - r;
}