#version 440
#extension GL_ARB_separate_shader_objects : require

#include <grindstone:config.glsl>

out lowp float gl_FragDepth;

uniform lowp sampler2D MainSampler;

layout(location = 0) out lowp vec4 fragColor;

// https://en.wikipedia.org/wiki/Color_difference#sRGB
lowp float redmean(lowp vec3 a, lowp vec3 b) {
	const lowp float r = step(0.5, mix(a.r, b.r, 0.5));
	const lowp vec3 d = a - b;

	return sqrt(dot(d*d, vec3(
		2.0 + r,
		4.0,
		3.0 - r
	)));
}

void main() {
	const lowp ivec2 texel = ivec2(gl_FragCoord.xy);

	const lowp vec3 color = texelFetch(MainSampler, texel, 0).rgb;

	const lowp vec3 left = texelFetchOffset(MainSampler, texel, 0, ivec2(-1, 0)).rgb;
	const lowp vec3 top = texelFetchOffset(MainSampler, texel, 0, ivec2(0, -1)).rgb;

	lowp vec4 delta;
	delta.xy = vec2(
		redmean(color, left),
		redmean(color, top)
	);

	const bvec2 edges = greaterThanEqual(delta.xy, vec2(SMAA_THRESHOLD));

	if (any(edges)) {
		delta.zw = vec2(
			redmean(color, texelFetchOffset(MainSampler, texel, 0, ivec2(1, 0)).rgb), // Right.
			redmean(color, texelFetchOffset(MainSampler, texel, 0, ivec2(0, 1)).rgb) // Bottom.
		);

		lowp vec2 delta_max = max(delta.xy, delta.zw);

		delta.zw = vec2(
			redmean(left, texelFetchOffset(MainSampler, texel, 0, ivec2(-2, 0)).rgb), // Left-left.
			redmean(top, texelFetchOffset(MainSampler, texel, 0, ivec2(0, -2)).rgb) // Top-top.
		);

		delta_max = max(delta_max.xy, delta.zw);

		const lowp float local_contrast_adaptation_factor = 2.0;
		const bvec2 temp = greaterThanEqual(delta.xy, (max(delta_max.x, delta_max.y) / local_contrast_adaptation_factor).xx);

		fragColor = vec4(
			vec2(edges.x && temp.x, edges.y && temp.y), // This is required instead of `result && temp` on AMD :(
			0.0, 0.0
		);
	} else {
		discard;
	}
}
