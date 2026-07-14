#version 440

#extension GL_AMD_shader_trinary_minmax : enable

#moj_import <smaa_lura:config.glsl>

#define immut

#moj_import <smaa_lura:srgb.glsl>

layout(depth_unchanged) out lowp float gl_FragDepth;

uniform lowp sampler2D SwapSampler;

out lowp vec4 fragColor;

#ifdef GL_AMD_shader_trinary_minmax
	#define cas_min3(a, b, c) min3(a, b, c)
	#define cas_max3(a, b, c) max3(a, b, c)
#else
	// These without the `cas_`-prefixes seem to collide with built-in functions somehow on Vulkan on AMD+Mesa.
	lowp float cas_min3(lowp float a, lowp float b, lowp float c) { return min(a, min(b, c)); }
	lowp float cas_max3(lowp float a, lowp float b, lowp float c) { return max(a, max(b, c)); }
#endif

#define saturate(v) clamp(v, 0.0, 1.0)

void main() {
	immut lowp ivec2 texel = ivec2(gl_FragCoord.xy);

	// a b c
	// d e f
	// g h i
	immut lowp vec3 b = linear(texelFetchOffset(SwapSampler, texel, 0, ivec2(0, -1)).rgb);
	immut lowp vec3 d = linear(texelFetchOffset(SwapSampler, texel, 0, ivec2(-1, 0)).rgb);
	immut lowp vec3 e = linear(texelFetch(SwapSampler, texel, 0).rgb);
	immut lowp vec3 f = linear(texelFetchOffset(SwapSampler, texel, 0, ivec2(1, -1)).rgb);
	immut lowp vec3 h = linear(texelFetchOffset(SwapSampler, texel, 0, ivec2(0, 1)).rgb);

	// Soft min. and max.
	//  a b c             b
	//  d e f * 0.5  +  d e f * 0.5
	//  g h i             h
	// These are 2.0x bigger (factored out the extra multiply).
	lowp float minimum = cas_min3(cas_min3(d.g, e.g, f.g), b.g, h.g);
	lowp float maximum = cas_max3(cas_max3(d.g, e.g, f.g), b.g, h.g);

	#ifdef CAS_BETTER_DIAGONALS
		immut lowp float a = texelFetchOffset(SwapSampler, texel, 0, ivec2(-1, -1)).g;
		immut lowp float c = texelFetchOffset(SwapSampler, texel, 0, ivec2(1, -1)).g;
		immut lowp float g = texelFetchOffset(SwapSampler, texel, 0, ivec2(-1, 1)).g;
		immut lowp float i = texelFetchOffset(SwapSampler, texel, 0, ivec2(1, 1)).g;

		// Converting to linear after the min/max here is correct,
		// since the sRGB -> linear function is increasing over [0, 1].

		minimum += min(minimum, linear(min(cas_min3(a, c, g), i)));
		maximum += max(maximum, linear(max(cas_max3(a, c, g), i)));
	#endif

	// Smooth minimum distance to signal limit divided by smooth max.
	immut lowp float amplify = sqrt(saturate(min(minimum, 2.0 - maximum) / maximum));

	// Filter shape:
	// 0 w 0
	// w 1 w
	// 0 w 0
	const lowp float sharpness = -1.0 / mix(8.0, 5.0, CAS_SHARPNESS);
	immut lowp float weight = sharpness * amplify;
	immut lowp float rcp_rcp_weight = fma(weight, 4.0, 1.0); // This naming is cursed.

	fragColor = vec4(srgb(saturate(
		((b + d + f + h) * weight + e) / rcp_rcp_weight
	)), 0.0);
}
