shader_type spatial;

const float x_period = 10.0;
const float z_period = 10.0;
const float l2_period = 100.0;
const float time_freq = 1.0;
const float spatial_freq = 1.0;
const float mag = 1.0;

uniform sampler2D noise;
uniform vec3 color: source_color;
uniform bool active = false;
varying float local_dy;
varying vec4 local_noise;
uniform sampler2D depth_texture : hint_depth_texture;

float loop(float min_x, float max_x, float x) {
	float range = max_x - min_x;
	float looped = min_x + fract(x / range) * range;
	return looped;
}

vec4 get_noise(float x, float z)
{
	vec2 offset = vec2(x, z);
	return texture(noise, offset);
}

float get_dy(vec3 vert, mat4 model_mat)
{
	if(active && vert.y < 0.001/2.0){
		vec3 world_position = (model_mat * vec4(vert, 1.0)).xyz;
		float x = loop(0, 1, world_position.x/x_period);
		float z = loop(0, 1, world_position.z/z_period);
		float x2 = loop(0, 1, world_position.x/l2_period);
		float z2 = loop(0, 1, world_position.z/l2_period);

		vec4 lnoise = get_noise(x, z);
		vec4 l2noise = get_noise(x2, z2);
		
		vec2 prop_vec = vec2(cos(2.0*PI*l2noise.r), sin(2.0*PI*l2noise.r)); 
		
		
		float dy = -0.2 + 0.2*lnoise.r*mag*sin(time_freq*TIME + dot(prop_vec, spatial_freq*world_position.xz));
		if(dy > 0.0){dy = 0.0;}
		
		return dy;
	}
	return 0.0;
}

void vertex() {
	// Called for every vertex the material is visible on.
	float dy = get_dy(VERTEX, MODEL_MATRIX);
	local_dy = -(dy + 0.2);
	VERTEX.y += dy;
	
}

float linear_depth(float x)
{
	float near = 0.05; float far = 4000.0;
	return (near*far) / (far - x * (far - near));
}

void fragment() {
	if(active)
	{
		float scale = 1.0;
		vec3 water_col = vec3(color.r + scale*local_dy , color.g + scale*local_dy , color.b + scale*local_dy);
		ALBEDO = water_col;
	}
	else
	{
		ALBEDO = color;
	}
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
