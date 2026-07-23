#version 440
#extension GL_ARB_separate_shader_objects : require

#include <grindstone:config.glsl>
#include <grindstone:srgb.glsl>

layout(depth_unchanged) out lowp float gl_FragDepth;

uniform lowp sampler2D BlendWeightSampler, MainSampler;

layout(location = 0) out lowp vec4 fragColor;

// Manual bilinearly filtered sample that actually gets interpolation right,
// since the texture is in sRGB.
lowp vec3 bilinearSampleMain(
	highp vec2 lower_texel_coord, // Texel space coordinates of the current texel minus `0.5`.
	highp vec2 blending_offset // Texel space offset.
) {
	const highp vec2 offset_texel_coord = lower_texel_coord + blending_offset;
	highp vec2 texel_f32;
	const lowp vec2 a = modf(offset_texel_coord, texel_f32);
	const lowp ivec2 texel = ivec2(texel_f32);

	return mix(
		mix(linear(texelFetch(MainSampler, texel, 0).rgb), linear(texelFetchOffset(MainSampler, texel, 0, ivec2(1, 0)).rgb), a.x),
		mix(linear(texelFetchOffset(MainSampler, texel, 0, ivec2(0, 1)).rgb), linear(texelFetchOffset(MainSampler, texel, 0, ivec2(1, 1)).rgb), a.x),
		a.y
	);
}

void main() {
	const lowp ivec2 texel = ivec2(gl_FragCoord.xy);

	const lowp vec4 a = vec4(
		texelFetchOffset(BlendWeightSampler, texel, 0, ivec2(1, 0)).w,
		texelFetchOffset(BlendWeightSampler, texel, 0, ivec2(0, 1)).y,
		texelFetch(BlendWeightSampler, texel, 0).zx
	);

	lowp vec3 color;

	if (dot(a, vec4(1.0)) < 1.0e-5) {
		color = texelFetch(MainSampler, texel, 0).rgb;
	} else {
		const bool h = max(a.x, a.z) > max(a.y, a.w);

		const highp vec4 blending_offset = h ? vec4(a.x, 0.0, a.z, 0.0) : vec4(0.0, a.y, 0.0, a.w);

		lowp vec2 blending_weight = h ? a.xz : a.yw;
		blending_weight /= dot(blending_weight, vec2(1.0));

		const highp vec2 lower_texel_coord = gl_FragCoord.xy - 0.5;

		color = blending_weight.x * bilinearSampleMain(lower_texel_coord, blending_offset.xy);
		color += blending_weight.y * bilinearSampleMain(lower_texel_coord, blending_offset.zw);
		color = srgb(color);
	}

	#if DEBUG_BW
		#if DEBUG_BW == 1
			#define DEBUG_BW_COMP xyz
		#else
			#define DEBUG_BW_COMP yzw
		#endif

		color = texelFetch(BlendWeightSampler, texel, 0).DEBUG_BW_COMP;
	#endif

	fragColor = vec4(color, 0.0);
}
