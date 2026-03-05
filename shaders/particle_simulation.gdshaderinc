// Configurable particle process shader -- include this file in a separate shader and define macros for features you need
// NOTE: This shader was taken and heavily modified from automatically-converted Godot Engine 4.2.1 stable's ParticleProcessMaterial

/**************************************************************************/
/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
/*                                                                        */
/* Permission is hereby granted, free of charge, to any person obtaining  */
/* a copy of this software and associated documentation files (the        */
/* "Software"), to deal in the Software without restriction, including    */
/* without limitation the rights to use, copy, modify, merge, publish,    */
/* distribute, sublicense, and/or sell copies of the Software, and to     */
/* permit persons to whom the Software is furnished to do so, subject to  */
/* the following conditions:                                              */
/*                                                                        */
/* The above copyright notice and this permission notice shall be         */
/* included in all copies or substantial portions of the Software.        */
/*                                                                        */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
/**************************************************************************/

render_mode disable_velocity;

////////////////////////////////////////////////////////
// Emission

uniform vec3 direction;
uniform float spread;
uniform float flatness;
uniform float inherit_emitter_velocity_ratio = 0;
uniform float initial_linear_velocity_min;
uniform float initial_linear_velocity_max;
uniform float lifetime_randomness;

#define ENSURE_NON_ZERO_BRANCHLESS(a) (float(a == 0.0) * 1.0 + float(a != 0.0) * a)
#define SAFE_NORMALIZE_BRANCHLESS(vec, len) (vec / ENSURE_NON_ZERO_BRANCHLESS(len))

// Emission Shape

#ifdef EMISSION_SHAPE_RING
uniform float emission_ring_radius;
uniform float emission_ring_inner_radius;
#endif

////////////////////////////////////////////////////////
// Physics

// Animated Velocity

#ifdef APPLY_ANGULAR_VELOCITY
uniform float angular_velocity_min;
uniform float angular_velocity_max;
#endif

#ifdef APPLY_ORBIT_VELOCITY
uniform float orbit_velocity_min;
uniform float orbit_velocity_max;
#endif

#ifdef APPLY_RADIAL_VELOCITY
uniform float radial_velocity_min;
uniform float radial_velocity_max;
#endif

#if defined(APPLY_ORBIT_VELOCITY) || defined(APPLY_RADIAL_VELOCITY)
uniform vec3 velocity_pivot = vec3(0.);
#endif

// Accelerations

uniform vec3 gravity;

#ifdef APPLY_ACCELERATIONS
uniform float linear_accel_min;
uniform float linear_accel_max;
uniform float radial_accel_min;
uniform float radial_accel_max;
uniform float tangent_accel_min;
uniform float tangent_accel_max;
#endif

#ifdef APPLY_DAMPING
uniform float damping_min;
uniform float damping_max;
#endif

////////////////////////////////////////////////////////
// Display

uniform float initial_angle_min;
uniform float initial_angle_max;
uniform float scale_min;
uniform float scale_max;

// Colour

uniform vec4 color_value : source_color;

#ifdef RANDOM_RGB
uniform float random_r;
uniform float random_g;
uniform float random_b;
#endif

#ifdef RANDOM_ALPHA
uniform float random_a;
#endif

#ifdef RANDOM_HUE
uniform float hue_variation_min;
uniform float hue_variation_max;
#endif

////////////////////////////////////////////////////////
// Target Follow

#ifdef APPLY_TARGET_FOLLOW
uniform vec2 target_pos;
uniform bool target_mode_active;
uniform float min_target_distance;
uniform float target_follow_speed;
uniform float target_follow_stiffness;
#endif

#ifdef APPLY_PATH_FOLLOW
// NOTE: if you change this value, it must also be changed elsewhere in the codebase
#define MAX_PATH_LENGTH 50

uniform vec2 path[MAX_PATH_LENGTH];
uniform int path_length = 0;
uniform float path_follow_speed;
uniform float path_follow_stiffness;
uniform float point_distance_threshold = 1.0;
#endif

////////////////////////////////////////////////////////
// Noise

// Perlin noise

#ifdef APPLY_NOISE
uniform bool use_random_seed = false;
uniform float noise_influence_min;
uniform float noise_influence_max;
uniform float noise_frequency;
uniform float noise_persistence;
uniform float noise_lacunarity;
uniform vec2 noise_speed = vec2(0.0);
#endif

// Turbulence

#ifdef APPLY_TURBULENCE
uniform float turbulence_noise_strength;
uniform float turbulence_noise_scale;
uniform float turbulence_influence_min;
uniform float turbulence_influence_max;
uniform float turbulence_initial_displacement_min;
uniform float turbulence_initial_displacement_max;
uniform float turbulence_noise_speed_random;
uniform vec3 turbulence_noise_speed = vec3(1.0, 1.0, 1.0);
uniform sampler2D turbulence_influence_over_life;
#endif

////////////////////////////////////////////////////////
// Texture Samplers

#ifdef APPLY_ALPHA_CURVE
uniform sampler2D alpha_curve : filter_linear, repeat_disable;
#endif

////////////////////////////////////////////////////////
// Code

#ifdef APPLY_TURBULENCE
vec4 grad(vec4 p) {
	p = fract(vec4(
		dot(p, vec4(0.143081, 0.001724, 0.280166, 0.262771)),
		dot(p, vec4(0.645401, -0.047791, -0.146698, 0.595016)),
		dot(p, vec4(-0.499665, -0.095734, 0.425674, -0.207367)),
		dot(p, vec4(-0.013596, -0.848588, 0.423736, 0.17044))));
	return fract((p.xyzw * p.yzwx) * 2365.952041) * 2.0 - 1.0;
}

float noise(vec4 coord) {
	// Domain rotation to improve the look of XYZ slices + animation patterns.
	coord = vec4(
	coord.xyz + dot(coord, vec4(vec3(-0.1666667), -0.5)),
	dot(coord, vec4(0.5)));

	vec4 base = floor(coord), delta = coord - base;
	vec4 grad_0000 = grad(base + vec4(0.0, 0.0, 0.0, 0.0)), grad_1000 = grad(base + vec4(1.0, 0.0, 0.0, 0.0));
	vec4 grad_0100 = grad(base + vec4(0.0, 1.0, 0.0, 0.0)), grad_1100 = grad(base + vec4(1.0, 1.0, 0.0, 0.0));
	vec4 grad_0010 = grad(base + vec4(0.0, 0.0, 1.0, 0.0)), grad_1010 = grad(base + vec4(1.0, 0.0, 1.0, 0.0));
	vec4 grad_0110 = grad(base + vec4(0.0, 1.0, 1.0, 0.0)), grad_1110 = grad(base + vec4(1.0, 1.0, 1.0, 0.0));
	vec4 grad_0001 = grad(base + vec4(0.0, 0.0, 0.0, 1.0)), grad_1001 = grad(base + vec4(1.0, 0.0, 0.0, 1.0));
	vec4 grad_0101 = grad(base + vec4(0.0, 1.0, 0.0, 1.0)), grad_1101 = grad(base + vec4(1.0, 1.0, 0.0, 1.0));
	vec4 grad_0011 = grad(base + vec4(0.0, 0.0, 1.0, 1.0)), grad_1011 = grad(base + vec4(1.0, 0.0, 1.0, 1.0));
	vec4 grad_0111 = grad(base + vec4(0.0, 1.0, 1.0, 1.0)), grad_1111 = grad(base + vec4(1.0, 1.0, 1.0, 1.0));

	vec4 result_0123 = vec4(
		dot(delta - vec4(0.0, 0.0, 0.0, 0.0), grad_0000), dot(delta - vec4(1.0, 0.0, 0.0, 0.0), grad_1000),
		dot(delta - vec4(0.0, 1.0, 0.0, 0.0), grad_0100), dot(delta - vec4(1.0, 1.0, 0.0, 0.0), grad_1100)
	);
	vec4 result_4567 = vec4(
		dot(delta - vec4(0.0, 0.0, 1.0, 0.0), grad_0010), dot(delta - vec4(1.0, 0.0, 1.0, 0.0), grad_1010),
		dot(delta - vec4(0.0, 1.0, 1.0, 0.0), grad_0110), dot(delta - vec4(1.0, 1.0, 1.0, 0.0), grad_1110)
	);
	vec4 result_89AB = vec4(
		dot(delta - vec4(0.0, 0.0, 0.0, 1.0), grad_0001), dot(delta - vec4(1.0, 0.0, 0.0, 1.0), grad_1001),
		dot(delta - vec4(0.0, 1.0, 0.0, 1.0), grad_0101), dot(delta - vec4(1.0, 1.0, 0.0, 1.0), grad_1101)
	);
	vec4 result_CDEF = vec4(
		dot(delta - vec4(0.0, 0.0, 1.0, 1.0), grad_0011), dot(delta - vec4(1.0, 0.0, 1.0, 1.0), grad_1011),
		dot(delta - vec4(0.0, 1.0, 1.0, 1.0), grad_0111), dot(delta - vec4(1.0, 1.0, 1.0, 1.0), grad_1111)
	);

	vec4 fade = delta * delta * delta * (10.0 + delta * (-15.0 + delta * 6.0));
	vec4 result_W0 = mix(result_0123, result_89AB, fade.w), result_W1 = mix(result_4567, result_CDEF, fade.w);
	vec4 result_WZ = mix(result_W0, result_W1, fade.z);
	vec2 result_WZY = mix(result_WZ.xy, result_WZ.zw, fade.y);
	return mix(result_WZY.x, result_WZY.y, fade.x);
}

// Curl 3D and three-noise function with friendly permission by Isaac Cohen.
// Modified to accept 4D noise.
vec3 noise_3x(vec4 p) {
	float s = noise(p);
	float s1 = noise(p + vec4(vec3(0.0), 1.7320508 * 2048.333333));
	float s2 = noise(p - vec4(vec3(0.0), 1.7320508 * 2048.333333));
	vec3 c = vec3(s, s1, s2);
	return c;
}

vec3 curl_3d(vec4 p, float c) {
	float epsilon = 0.001 + c;
	vec4 dx = vec4(epsilon, 0.0, 0.0, 0.0);
	vec4 dy = vec4(0.0, epsilon, 0.0, 0.0);
	vec4 dz = vec4(0.0, 0.0, epsilon, 0.0);
	vec3 x0 = noise_3x(p - dx).xyz;
	vec3 x1 = noise_3x(p + dx).xyz;
	vec3 y0 = noise_3x(p - dy).xyz;
	vec3 y1 = noise_3x(p + dy).xyz;
	vec3 z0 = noise_3x(p - dz).xyz;
	vec3 z1 = noise_3x(p + dz).xyz;
	float x = (y1.z - y0.z) - (z1.y - z0.y);
	float y = (z1.x - z0.x) - (x1.z - x0.z);
	float z = (x1.y - x0.y) - (y1.x - y0.x);
	return normalize(vec3(x, y, z));
}

vec3 get_noise_direction(vec3 pos) {
	float adj_contrast = max((turbulence_noise_strength - 1.0), 0.0) * 70.0;
	vec4 noise_time = TIME * vec4(turbulence_noise_speed, turbulence_noise_speed_random);
	vec4 noise_pos = vec4(pos * turbulence_noise_scale, 0.0);
	vec3 noise_direction = curl_3d(noise_pos + noise_time, adj_contrast);
	noise_direction = mix(0.9 * noise_direction, noise_direction, turbulence_noise_strength - 9.0);
	return noise_direction;
}
#endif

#ifdef APPLY_NOISE
// implementation of 2d improved perlin noise with murmur hash

int hash1(int x, int seed) {
	const int m = 0x5bd1e995;
	int hash = seed;

	int k = x;
	k *= m;
	k ^= k >> 24;
	k *= m;
	hash *= m;
	hash ^= k;

	hash ^= hash >> 13;
	hash *= m;
	hash ^= hash >> 15;
	return hash;
}

int hash2(ivec2 x, int seed){
    const int m = 0x5bd1e995;
    int hash = seed;

    int k = x.x;
    k *= m;
    k ^= k >> 24;
    k *= m;
    hash *= m;
    hash ^= k;

    k = x.y;
    k *= m;
    k ^= k >> 24;
    k *= m;
    hash *= m;
    hash ^= k;

    hash ^= hash >> 13;
    hash *= m;
    hash ^= hash >> 15;
    return hash;
}

float getGradientVal(vec2 uvw, int hash) {
	switch(hash & 0x3) {
		case 0x0: return  uvw.x + uvw.y;
		case 0x1: return -uvw.x + uvw.y;
		case 0x2: return  uvw.x - uvw.y;
		case 0x3: return -uvw.x - uvw.y;
		default: return 0.0;
	}
}

float interpolate(float v0, float v1, float v2, float v3, vec2 t) {
    return mix(mix(v0, v1, t.x), mix(v2, v3, t.x), t.y);
}

vec2 fade(vec2 t) {
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float perlinNoise1(vec2 pos, int seed) {
	vec2 floorPos = floor(pos);
	ivec2 gridPos = ivec2(floorPos);
	vec2 uvw = pos - floorPos;

	float v0 = getGradientVal(uvw, hash2(gridPos, seed));
	float v1 = getGradientVal(uvw - vec2(1, 0), hash2(gridPos + ivec2(1, 0), seed));
	float v2 = getGradientVal(uvw - vec2(0, 1), hash2(gridPos + ivec2(0, 1), seed));
	float v3 = getGradientVal(uvw - vec2(1, 1), hash2(gridPos + ivec2(1, 1), seed));
	return interpolate(v0, v1, v2, v3, fade(uvw));
}

float perlinNoise(vec2 pos, int seed) {
    float value = 0.0;
    float amplitude = 1.0;
    float cur_freq = noise_frequency;
    int currentSeed = seed;
    for (int i = 0; i < 3; i++) {
        currentSeed = hash1(currentSeed, 0);
        value += perlinNoise1(pos * cur_freq, currentSeed) * amplitude;
        amplitude *= noise_persistence;
        cur_freq *= noise_lacunarity;
    }
    return value;
}
#endif

#ifdef RANDOM_HUE
vec4 rotate_hue(vec4 current_color, float hue_rot_angle){
	float hue_rot_c = cos(hue_rot_angle);
	float hue_rot_s = sin(hue_rot_angle);
	mat4 hue_rot_mat = mat4(vec4(0.299, 0.587, 0.114, 0.0),
			vec4(0.299, 0.587, 0.114, 0.0),
			vec4(0.299, 0.587, 0.114, 0.0),
			vec4(0.000, 0.000, 0.000, 1.0)) +
		mat4(vec4(0.701, -0.587, -0.114, 0.0),
			vec4(-0.299, 0.413, -0.114, 0.0),
			vec4(-0.300, -0.588, 0.886, 0.0),
			vec4(0.000, 0.000, 0.000, 0.0)) * hue_rot_c +
		mat4(vec4(0.168, 0.330, -0.497, 0.0),
			vec4(-0.328, 0.035,  0.292, 0.0),
			vec4(1.250, -1.050, -0.203, 0.0),
			vec4(0.000, 0.000, 0.000, 0.0)) * hue_rot_s;
	return hue_rot_mat * current_color;
}
#endif

float rand_from_seed(inout uint seed) {
	int k;
	int s = int(seed);
	if (s == 0)
	s = 305420679;
	k = s / 127773;
	s = 16807 * (s - k * 127773) - 2836 * k;
	if (s < 0)
		s += 2147483647;
	seed = uint(s);
	return float(seed % uint(65536)) / 65535.0;
}

float rand_from_seed_m1_p1(inout uint seed) {
	return rand_from_seed(seed) * 2.0 - 1.0;
}

uint hash(uint x) {
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = (x >> uint(16)) ^ x;
	return x;
}

struct DisplayParameters{
	vec3 scale;
	float lifetime;
	vec4 color;

	#ifdef RANDOM_HUE
	float hue_rotation;
	#endif
};

struct DynamicsParameters{
	float angle;
	float initial_velocity_multiplier;

	#ifdef APPLY_ANGULAR_VELOCITY
	float angular_velocity;
	#endif

	#ifdef APPLY_RADIAL_VELOCITY
	float radial_velocity;
	#endif

	#ifdef APPLY_ORBIT_VELOCITY
	float orbit_velocity;
	#endif

	#ifdef APPLY_NOISE
	float noise_influence;
	#endif

	#ifdef APPLY_TURBULENCE
	float turb_influence;
	#endif
};

#if defined(APPLY_ACCELERATIONS) || defined(APPLY_DAMPING)
struct PhysicalParameters{
	#ifdef APPLY_ACCELERATIONS
	float linear_accel;
	float radial_accel;
	float tangent_accel;
	#endif

	#ifdef APPLY_DAMPING
	float damping;
	#endif
};
#endif

#if defined(APPLY_ACCELERATIONS) || defined(APPLY_DAMPING)
void calculate_initial_physical_params(inout PhysicalParameters params, inout uint alt_seed) {
	#ifdef APPLY_ACCELERATIONS
	params.linear_accel = mix(linear_accel_min, linear_accel_max, rand_from_seed(alt_seed));
	params.radial_accel = mix(radial_accel_min, radial_accel_max, rand_from_seed(alt_seed));
	params.tangent_accel = mix(tangent_accel_min, tangent_accel_max, rand_from_seed(alt_seed));
	#endif

	#ifdef APPLY_DAMPING
	params.damping = mix(damping_min, damping_max, rand_from_seed(alt_seed));
	#endif
}
#endif

void calculate_initial_dynamics_params(inout DynamicsParameters params, inout uint alt_seed){
	// -------------------- DO NOT REORDER OPERATIONS, IT BREAKS VISUAL COMPATIBILITY
	// -------------------- ADD NEW OPERATIONS AT THE BOTTOM

	params.angle = mix(initial_angle_min, initial_angle_max, rand_from_seed(alt_seed));

	params.initial_velocity_multiplier = mix(initial_linear_velocity_min, initial_linear_velocity_max,rand_from_seed(alt_seed));

	#ifdef APPLY_ANGULAR_VELOCITY
	params.angular_velocity = mix(angular_velocity_min, angular_velocity_max, rand_from_seed(alt_seed));
	#endif

	#ifdef APPLY_RADIAL_VELOCITY
	params.radial_velocity = mix(radial_velocity_min, radial_velocity_max,rand_from_seed(alt_seed));
	#endif

	#ifdef APPLY_ORBIT_VELOCITY
	params.orbit_velocity = mix(orbit_velocity_min, orbit_velocity_max,rand_from_seed(alt_seed));
	#endif

	#ifdef APPLY_NOISE
	params.noise_influence = mix(noise_influence_min,noise_influence_max,rand_from_seed(alt_seed));
	#endif

	#ifdef APPLY_TURBULENCE
	params.turb_influence = mix(turbulence_influence_min,turbulence_influence_max,rand_from_seed(alt_seed));
	#endif
}
void calculate_initial_display_params(inout DisplayParameters params,inout uint alt_seed){
	// -------------------- DO NOT REORDER OPERATIONS, IT BREAKS VISUAL COMPATIBILITY
	// -------------------- ADD NEW OPERATIONS AT THE BOTTOM

	params.scale = vec3(mix(scale_min, scale_max, rand_from_seed(alt_seed)));
	params.scale = sign(params.scale) * max(abs(params.scale), 0.001);

	params.lifetime = (1.0 - lifetime_randomness * rand_from_seed(alt_seed));
	params.color = color_value;

	#ifdef RANDOM_HUE
	params.hue_rotation =  PI * 2.0 * mix(hue_variation_min, hue_variation_max, rand_from_seed(alt_seed));
	#endif

	#ifdef RANDOM_RGB
	params.color.r = mix(color_value.r - random_r, color_value.r, rand_from_seed(alt_seed));
	params.color.g = mix(color_value.g - random_g, color_value.g, rand_from_seed(alt_seed));
	params.color.b = mix(color_value.b - random_b, color_value.b, rand_from_seed(alt_seed));
	#endif

	#ifdef RANDOM_ALPHA
	params.color.a = mix(color_value.a - random_a, color_value.a, rand_from_seed(alt_seed));
	#endif
}

void process_display_param(inout DisplayParameters parameters, float lifetime) {

	#ifdef APPLY_ALPHA_CURVE
	parameters.color.a *= texture(alpha_curve, vec2(lifetime)).r;
	#endif

	#ifdef RANDOM_HUE
	parameters.color = rotate_hue(parameters.color, parameters.hue_rotation);
	#endif
}

#ifdef EMISSION_SHAPE_RING
vec3 calculate_initial_position(inout uint alt_seed) {
	float ring_spawn_angle = rand_from_seed(alt_seed) * 2.0 * PI;
	float ring_random_radius = rand_from_seed(alt_seed) * (emission_ring_radius - emission_ring_inner_radius) + emission_ring_inner_radius;
	vec2 n = vec2(cos(ring_spawn_angle), sin(ring_spawn_angle));
	vec2 pos = ring_random_radius * n;
	return vec3(pos, 0.0);
}
#endif

#ifdef APPLY_ORBIT_VELOCITY
vec3 process_orbit_displacement(DynamicsParameters param, float lifetime, inout uint alt_seed, mat4 transform, mat4 emission_transform,float delta, float total_lifetime){
	if(abs(param.orbit_velocity) < 0.01 || delta < 0.001) {
		return vec3(0.0);
	}
	vec3 displacement = vec3(0.);
	float degree_to_rad = PI / 180.0;
	float orbit_amount = param.orbit_velocity;
	if (orbit_amount != 0.0) {
		vec3 pos = transform[3].xyz;
		vec3 org = emission_transform[3].xyz;
		vec3 diff = pos - org;
		float ang = orbit_amount * PI * 2.0 * delta;
		mat2 rot = mat2(vec2(cos(ang), -sin(ang)), vec2(sin(ang), cos(ang)));
		displacement.xy -= diff.xy;
		displacement.xy += rot * diff.xy;
	}
	return (emission_transform * vec4(displacement/delta, 0.0)).xyz;
}
#endif

vec3 get_random_direction_from_spread(inout uint alt_seed, float spread_angle){
	float degree_to_rad = PI / 180.0;
	vec3 velocity = vec3(0.);
	float spread_rad = spread_angle * degree_to_rad;
	float angle1_rad = rand_from_seed_m1_p1(alt_seed) * spread_rad;
	float angle2_rad = rand_from_seed_m1_p1(alt_seed) * spread_rad * (1.0 - flatness);
	vec3 direction_xz = vec3(sin(angle1_rad), 0.0, cos(angle1_rad));
	vec3 direction_yz = vec3(0.0, sin(angle2_rad), cos(angle2_rad));
	direction_yz.z = direction_yz.z / max(0.0001,sqrt(abs(direction_yz.z))); // better uniform distribution
	vec3 spread_direction = vec3(direction_xz.x * direction_yz.z, direction_yz.y, direction_xz.z * direction_yz.z);
	vec3 direction_nrm = length(direction) > 0.0 ? normalize(direction) : vec3(0.0, 0.0, 1.0);
	// rotate spread to direction
	vec3 binormal = cross(vec3(0.0, 1.0, 0.0), direction_nrm);
	if (length(binormal) < 0.0001) {
		// direction is parallel to Y. Choose Z as the binormal.
		binormal = vec3(0.0, 0.0, 1.0);
	}
	binormal = normalize(binormal);
	vec3 normal = cross(binormal, direction_nrm);
	spread_direction = binormal * spread_direction.x + normal * spread_direction.y + direction_nrm * spread_direction.z;
	return spread_direction;
}

#ifdef APPLY_RADIAL_VELOCITY
vec3 process_radial_displacement(DynamicsParameters param, float lifetime, inout uint alt_seed, mat4 transform, mat4 emission_transform, float delta){
	vec3 radial_displacement = vec3(0.0);
	if (delta < 0.001){
		return radial_displacement;
	}
	float radial_displacement_multiplier = 1.0;
	vec3 global_pivot = (emission_transform * vec4(velocity_pivot, 1.0)).xyz;
	if (length(transform[3].xyz - global_pivot) > 0.01) {
		radial_displacement = normalize(transform[3].xyz - global_pivot) * radial_displacement_multiplier * param.radial_velocity;
	}
	else {
		radial_displacement = get_random_direction_from_spread(alt_seed, 360.0)* param.radial_velocity;
	}
	if (radial_displacement_multiplier * param.radial_velocity < 0.0){
	// Prevent inwards velocity to flicker once the point is reached.		if (length(radial_displacement) > 0.01){
	radial_displacement = normalize(radial_displacement) * min(abs((radial_displacement_multiplier * param.radial_velocity)), length(transform[3].xyz - global_pivot) / delta);
	}
	return radial_displacement;
}
#endif

void start() {
	uint base_number = NUMBER;
	uint alt_seed = hash(base_number + uint(1) + RANDOM_SEED);
	DisplayParameters params;
	calculate_initial_display_params(params, alt_seed);

	DynamicsParameters dynamic_params;
	calculate_initial_dynamics_params(dynamic_params, alt_seed);

	#if defined(APPLY_ACCELERATIONS) || defined(APPLY_DAMPING)
	PhysicalParameters physics_params;
	calculate_initial_physical_params(physics_params, alt_seed);
	#endif

	process_display_param(params, 0.0);
	if (rand_from_seed(alt_seed) > AMOUNT_RATIO) {
		ACTIVE = false;
	}

	if (RESTART_CUSTOM){
		CUSTOM = vec4(0.);
		CUSTOM.w = params.lifetime;
		CUSTOM.x = dynamic_params.angle;

		#ifdef APPLY_PATH_FOLLOW
		USERDATA1.xy = path[0];
		USERDATA1.z = float(0);
		#endif
	}
	if (RESTART_COLOR){
		COLOR = params.color;
	}
	if (RESTART_ROT_SCALE) {
		TRANSFORM[0].xyz = vec3(1.0, 0.0, 0.0);
		TRANSFORM[1].xyz = vec3(0.0, 1.0, 0.0);
		TRANSFORM[2].xyz = vec3(0.0, 0.0, 1.0);
	}
	if (RESTART_POSITION) {
		#ifdef EMISSION_SHAPE_RING
		TRANSFORM[3].xyz = calculate_initial_position(alt_seed);
		#else
		TRANSFORM[3].xyz = vec3(0.0);
		#endif

		#ifdef APPLY_TURBULENCE
		float initial_turbulence_displacement = mix(turbulence_initial_displacement_min, turbulence_initial_displacement_max, rand_from_seed(alt_seed));
		vec3 noise_direction = get_noise_direction(TRANSFORM[3].xyz);
		TRANSFORM[3].xyz += noise_direction * initial_turbulence_displacement;
		#endif

		TRANSFORM = EMISSION_TRANSFORM * TRANSFORM;
	}
	if (RESTART_VELOCITY) {
		VELOCITY = get_random_direction_from_spread(alt_seed, spread) * dynamic_params.initial_velocity_multiplier;
	}
	process_display_param(params, 0.);
	VELOCITY = (EMISSION_TRANSFORM * vec4(VELOCITY, 0.0)).xyz;
	VELOCITY += EMITTER_VELOCITY * inherit_emitter_velocity_ratio;
	VELOCITY.z = 0.;
	TRANSFORM[3].z = 0.;
}

void process() {
	uint base_number = NUMBER;
	uint alt_seed = hash(base_number + uint(1) + RANDOM_SEED);
	DisplayParameters params;
	calculate_initial_display_params(params, alt_seed);
	DynamicsParameters dynamic_params;
	calculate_initial_dynamics_params(dynamic_params, alt_seed);

	#if defined(APPLY_ACCELERATIONS) || defined(APPLY_DAMPING)
	PhysicalParameters physics_params;
	calculate_initial_physical_params(physics_params, alt_seed);
	#endif

	float degree_to_rad = PI / 180.0;
	CUSTOM.y += DELTA / LIFETIME;
	CUSTOM.y = mix(CUSTOM.y, 1.0, INTERPOLATE_TO_END);
	float lifetime_percent = CUSTOM.y / params.lifetime;

	// will use this later to calculate final displacement and orient the particle.
	vec3 starting_position = TRANSFORM[3].xyz;
	vec3 controlled_displacement = vec3(0.0);

	#ifdef APPLY_ORBIT_VELOCITY
	controlled_displacement += process_orbit_displacement(dynamic_params, lifetime_percent, alt_seed, TRANSFORM, EMISSION_TRANSFORM, DELTA, params.lifetime * LIFETIME);
	#endif

	#ifdef  APPLY_RADIAL_VELOCITY
	controlled_displacement += process_radial_displacement(dynamic_params, lifetime_percent, alt_seed, TRANSFORM, EMISSION_TRANSFORM, DELTA);
	#endif

	{
		// copied from previous version
		vec3 pos = TRANSFORM[3].xyz;
		vec3 force = gravity;

		#ifdef APPLY_ACCELERATIONS
		// apply linear acceleration
		force += length(VELOCITY) > 0.0 ? normalize(VELOCITY) * physics_params.linear_accel : vec3(0.0);
		// apply radial acceleration
		vec3 org = EMISSION_TRANSFORM[3].xyz;
		vec3 diff = pos - org;
		force += length(diff) > 0.0 ? normalize(diff) * physics_params.radial_accel : vec3(0.0);
		// apply tangential acceleration;
		float tangent_accel_val = physics_params.tangent_accel;
		force += length(diff.yx) > 0.0 ? vec3(normalize(diff.yx * vec2(-1.0, 1.0)), 0.0) * tangent_accel_val : vec3(0.0);
		#endif

		#ifdef APPLY_DAMPING
		// apply damping
		if (physics_params.damping > 0.0) {
			float v = length(VELOCITY);
			v -= physics_params.damping * DELTA;
			if (v < 0.0) {
				VELOCITY = vec3(0.0);
			} else {
				VELOCITY = normalize(VELOCITY) * v;
			}
		}
		#endif

		#ifdef APPLY_NOISE
		{
			// apply Perlin noise displacement
			int noise_seed = int(use_random_seed) * int(alt_seed);
			float noise = perlinNoise(pos.xy + noise_speed * TIME, noise_seed);
			float theta = noise * PI;
			vec3 noise_direction = vec3(cos(theta), sin(theta), 0.0);
			float vel_mag = length(VELOCITY);
			float infl = dynamic_params.noise_influence;
			controlled_displacement += noise_direction * vel_mag * DELTA * infl * 100.0;
		}
		#endif

		#ifdef APPLY_TURBULENCE
		{
			// turbulence before limiting
			float turbulence_influence = 1.0;
			vec3 noise_direction = get_noise_direction(TRANSFORM[3].xyz);
			float vel_mag = length(VELOCITY);
			float vel_infl = clamp(dynamic_params.turb_influence * turbulence_influence, 0.0,1.0);
			VELOCITY = mix(VELOCITY, normalize(noise_direction) * vel_mag * (1.0 + (1.0 - vel_infl) * 0.2), vel_infl);
			vel_mag = length(controlled_displacement);
			controlled_displacement = mix(controlled_displacement, normalize(noise_direction) * vel_mag * (1.0 + (1.0 - vel_infl) * 0.2), vel_infl);
		}
		#endif

		#ifdef APPLY_TARGET_FOLLOW
		// handle player target mode (no point in calculating if target_follow_speed is 0)
		if (target_mode_active && target_follow_speed != 0.0) {
			vec2 target_direction = target_pos - pos.xy;
			float target_distance = length(target_direction);

			ACTIVE = target_distance >= min_target_distance;
			float a = target_follow_stiffness * DELTA;

			target_direction = SAFE_NORMALIZE_BRANCHLESS(target_direction, target_distance);
			target_direction = target_direction * a;

			vec2 cur_direction = VELOCITY.xy;
			float len_velocity = length(VELOCITY);
			cur_direction = SAFE_NORMALIZE_BRANCHLESS(cur_direction, len_velocity);
			cur_direction = cur_direction * (1.0 - a);

			vec2 sum = target_direction + cur_direction;
			float len_sum = length(sum);
			sum = SAFE_NORMALIZE_BRANCHLESS(sum, len_sum);
			VELOCITY.xy = sum * target_follow_speed;
		}
		#endif

		#ifdef APPLY_PATH_FOLLOW
		if (path_length > 0) {
			vec2 target_direction = USERDATA1.xy - pos.xy;
			float target_distance = length(target_direction);

			// branchless path idx update
			float t = point_distance_threshold;
			float d = target_distance;
			bool c = int(USERDATA1.z) + 1 < min(path_length, MAX_PATH_LENGTH);
			USERDATA1.z = USERDATA1.z * float(d > t || !c) + (USERDATA1.z + 1.0) * float(d <= t && c);
			USERDATA1.xy = path[int(USERDATA1.z)];

			// update target direction in case particle was within point_distance_threshold
			target_direction = USERDATA1.xy - pos.xy;
			target_distance = length(target_direction);
			target_direction = SAFE_NORMALIZE_BRANCHLESS(target_direction, target_distance);

			vec2 cur_direction = VELOCITY.xy;
			float len_velocity = length(cur_direction);
			cur_direction = SAFE_NORMALIZE_BRANCHLESS(cur_direction, len_velocity);

			float a = path_follow_stiffness * DELTA;
			cur_direction = cur_direction * (1.0 - a);
			target_direction = target_direction * a;

			vec2 sum = target_direction + cur_direction;
			float len_sum = length(sum);
			sum = SAFE_NORMALIZE_BRANCHLESS(sum, len_sum);
			VELOCITY.xy = sum * path_follow_speed;
		}
		#endif

		force.z = 0.;
		VELOCITY += force * DELTA;
	}

	vec3 final_velocity = controlled_displacement + VELOCITY;

	// limit velocity
	final_velocity.z = 0.;
	TRANSFORM[3].xyz += final_velocity * DELTA;
	process_display_param(params, lifetime_percent);

	float base_angle = dynamic_params.angle;

	#ifdef APPLY_ANGULAR_VELOCITY
	base_angle += CUSTOM.y * LIFETIME * dynamic_params.angular_velocity;
	#endif

	CUSTOM.x = base_angle * degree_to_rad;
	COLOR = params.color;
	TRANSFORM[0] = vec4(cos(CUSTOM.x), -sin(CUSTOM.x), 0.0, 0.0);
	TRANSFORM[1] = vec4(sin(CUSTOM.x), cos(CUSTOM.x), 0.0, 0.0);
	TRANSFORM[2] = vec4(0.0, 0.0, 1.0, 0.0);
	TRANSFORM[3].z = 0.0;

	TRANSFORM[0].xyz *= sign(params.scale.x) * max(abs(params.scale.x), 0.001);
	TRANSFORM[1].xyz *= sign(params.scale.y) * max(abs(params.scale.y), 0.001);
	TRANSFORM[2].xyz *= sign(params.scale.z) * max(abs(params.scale.z), 0.001);

	bool cond = true;

	if (CUSTOM.y > CUSTOM.w) {
		ACTIVE = false;
	}
}