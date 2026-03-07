//adapted from here https://timcoster.com/2020/02/11/raymarching-shader-pt1-glsl/
float diffusedPoint(vec3 p, in vec3 light, in vec3 normals){
	vec3 l = normalize(light - p);
	float dif = dot(normals,l); //diffuse lighting is just the dot products
	dif = clamp(dif,0.,1.); //clamp to zero
	return dif;
}