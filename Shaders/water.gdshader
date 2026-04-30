shader_type spatial;

const float x_period = 1.0;
const float z_period = 1.0;
const float time_freq = 4.0;
const float spatial_freq = 0.9;
const float mag = 0.1;

uniform sampler2D noise;
uniform vec3 color: source_color;
uniform bool active = false;



float loop(float min_x, float max_x, float x) {
	float range = max_x - min_x;
	float looped = min_x + fract(x / range) * range;
	return looped;
}

void vertex() {
	// Called for every vertex the material is visible on.
	if(active && VERTEX.y < 0.001/2.0){
		vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float x = loop(0, 1, world_position.x/x_period);
		float z = loop(0, 1, world_position.z/z_period);
		vec2 offset = vec2(x, z);
		
		vec2 prop_vec = vec2(4.0*cos(0.1*TIME), -3.0*sin(0.3*TIME)); 
		
		float dy = -0.2 + 0.2*texture(noise, offset).r*mag*sin(time_freq*TIME + dot(prop_vec, spatial_freq*world_position.xz));
		 if(dy > 0.0){dy = 0.0;}
		
		VERTEX.y += dy;
	}
}

void fragment() {
	ALBEDO = color;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
