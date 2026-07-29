#version 440
#extension GL_ARB_separate_shader_objects : require
#extension GL_AMD_shader_trinary_minmax : enable

#include <grindstone:config.glsl>

#ifndef GL_AMD_shader_trinary_minmax
	#define max3(a, b, c) max(a, max(b, c))
#endif

out lowp float gl_FragDepth;

uniform lowp sampler2D MainSampler;

layout(location = 0) out lowp vec4 fragColor;

// Squared redmean color difference.
//
// We square the contrast threshold and LCA factor to compensate for this being squared,
// making the actual color difference metric regular redmean.
//
// https://en.wikipedia.org/wiki/Color_difference#sRGB
lowp float sq_redmean(lowp vec3 a, lowp vec3 b) {
	const lowp float r = step(0.5, mix(a.r, b.r, 0.5));
	const lowp vec3 d = a - b;

	return dot(d*d, vec3(
		2.0 + r,
		4.0,
		3.0 - r
	));
}

void main() {
	const lowp ivec2 texel = ivec2(gl_FragCoord.xy);

	const lowp vec3 color = texelFetch(MainSampler, texel, 0).rgb;
	const lowp vec3 left = texelFetchOffset(MainSampler, texel, 0, ivec2(-1, 0)).rgb;
	const lowp vec3 top = texelFetchOffset(MainSampler, texel, 0, ivec2(0, -1)).rgb;

	const lowp vec2 delta = vec2(
		sq_redmean(color, left),
		sq_redmean(color, top)
	);

	const bvec2 edges = greaterThanEqual(delta, (SMAA_THRESHOLD*SMAA_THRESHOLD).xx);

	if (any(edges)) {
		const lowp vec2 delta_max = max3(
			delta,
			vec2(
				sq_redmean(color, texelFetchOffset(MainSampler, texel, 0, ivec2(1, 0)).rgb), // Right.
				sq_redmean(color, texelFetchOffset(MainSampler, texel, 0, ivec2(0, 1)).rgb) // Bottom.
			),
			vec2(
				sq_redmean(left, texelFetchOffset(MainSampler, texel, 0, ivec2(-2, 0)).rgb), // Left-left.
				sq_redmean(top, texelFetchOffset(MainSampler, texel, 0, ivec2(0, -2)).rgb) // Top-top.
			)
		);

		const bvec2 temp = greaterThanEqual(delta, (max(delta_max.x, delta_max.y) / (SMAA_LCA*SMAA_LCA)).xx);
		const bvec2 result = bvec2(edges.x && temp.x, edges.y && temp.y); // This is required instead of `result && temp` on AMD :(

		if (any(result)) {
			fragColor = vec4(vec2(result), 0.0, 0.0);
		} else {
			discard;
		}
	} else {
		discard;
	}
}
