#version 460 core

#define VERSION v // [v]

#define SMAA_THRESHOLD 0.1 // [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]
#define SMAA_SEARCH 112 // [8 16 32 48 64 80 96 112]
#define SMAA_SEARCH_DIAG 20 // [0 4 8 12 16 20]
#define SMAA_CORNER 25 // [0 25 50 75 100]

#define DEBUG_BW 0 // [0 1 2]
#define CONST_IMMUT 1 // [0 1 2]

#if (CONST_IMMUT == 1 && defined MC_GL_VENDOR_NVIDIA) || CONST_IMMUT == 2
	#define immut const
#else
	#define immut
#endif

/*
	// Clear needs to be enabled in dimensions where the sky geometry isn't rendered, such as in the nether
	// we currently don't disable it in any dimension, even though it should be safe in the overworld and the end,
	// as it would make the shader pack too complex, and possibly risk breaking some mods
	const bool colortex0Clear = true;
	const int colortex0Format = RGBA8;
*/

// Specialized efficient matrix multiplication functions

vec2 rot_trans_mmul(mat4 rot_trans_mat, vec2 vec) {
	return mat2(rot_trans_mat) * vec + rot_trans_mat[3].xy;
}

vec3 rot_trans_mmul(mat4 rot_trans_mat, vec3 vec) {
	return mat3(rot_trans_mat) * vec + rot_trans_mat[3].xyz;
}

vec4 proj_mmul(mat4 proj_mat, vec3 view) {
	return vec4(
		vec2(proj_mat[0].x, proj_mat[1].y) * view.xy,
		fma(proj_mat[2].z, view.z, proj_mat[3].z),
		proj_mat[2].w * view.z
	);
}

vec3 proj_inv(mat4 inv_proj_mat, vec3 ndc) {
	immut vec4 view_undiv = vec4(
		vec2(inv_proj_mat[0].x, inv_proj_mat[1].y) * ndc.xy,
		inv_proj_mat[3].z,
		fma(inv_proj_mat[2].w, ndc.z, inv_proj_mat[3].w)
	);

	return view_undiv.xyz / view_undiv.w;
}

vec3 linear(vec3 srgb) {
	return mix(
		pow((srgb + 0.055) / 1.055, vec3(2.4)),
		srgb / 12.92,
		lessThanEqual(srgb, vec3(0.04045))
	);
}

vec3 srgb(vec3 linear) {
	return mix(
		1.055 * pow(linear, vec3(1.0/2.4)) - 0.055,
		12.92 * linear,
		lessThanEqual(linear, vec3(0.0031308))
	);
}
