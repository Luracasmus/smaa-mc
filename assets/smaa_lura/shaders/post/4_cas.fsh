/*
	FidelityFX Contrast Adaptive Sharpening 1.2
	https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK/blob/v1.1.4/sdk/include/FidelityFX/gpu/cas/ffx_cas.h#L107

	Copyright (C) 2024 Advanced Micro Devices, Inc.
	Copyright (C) 2024-2026 Luracasmus

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files(the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and /or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions :

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
*/

#version 450

#define CAS_SHARPNESS 0.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define immut

#moj_import <smaa_lura:srgb.glsl>

layout(depth_unchanged) out lowp float gl_FragDepth;

uniform lowp sampler2D SwapSampler;

layout(std140) uniform SamplerInfo {
	lowp vec2 OutSize; // Unused.
	highp vec2 SwapSize;
};

out lowp vec4 fragColor;

lowp vec3 saturate(lowp vec3 v) { return clamp(v, 0.0, 1.0); }

lowp vec3 min3(lowp vec3 a, lowp vec3 b, lowp vec3 c) { return min(a, min(b, c)); }
lowp vec3 max3(lowp vec3 a, lowp vec3 b, lowp vec3 c) { return max(a, max(b, c)); }

lowp float luminance(lowp vec3 color) { return dot(color, vec3(0.299, 0.587, 0.114)); }

void main() {
	immut lowp ivec2 texel = ivec2(gl_FragCoord.xy);

	// a b c
	// d e f
	// g h i
	immut lowp vec3[3][3] cas_nbh = vec3[3][3](vec3[3](
		linear(texelFetchOffset(SwapSampler, texel, 0, ivec2(-1, -1)).rgb),
		linear(texelFetchOffset(SwapSampler, texel, 0, ivec2(-1, 0)).rgb),
		linear(texelFetchOffset(SwapSampler, texel, 0, ivec2(-1, 1)).rgb)
	), vec3[3](
		linear(texelFetchOffset(SwapSampler, texel, 0, ivec2(0, -1)).rgb),
		linear(texelFetch(SwapSampler, texel, 0).rgb),
		linear(texelFetchOffset(SwapSampler, texel, 0, ivec2(0, 1)).rgb)
	), vec3[3](
		linear(texelFetchOffset(SwapSampler, texel, 0, ivec2(1, -1)).rgb),
		linear(texelFetchOffset(SwapSampler, texel, 0, ivec2(1, 0)).rgb),
		linear(texelFetchOffset(SwapSampler, texel, 0, ivec2(1, 1)).rgb)
	));

	// Soft min. and max.
	//  a b c             b
	//  d e f * 0.5  +  d e f * 0.5
	//  g h i             h
	// These are 2.0x bigger (factored out the extra multiply).
	lowp vec3 minimum = min3(min3(cas_nbh[0][1], cas_nbh[1][1], cas_nbh[2][1]), cas_nbh[1][0], cas_nbh[1][2]);
	minimum += min3(min3(minimum, cas_nbh[0][0], cas_nbh[2][0]), cas_nbh[0][2], cas_nbh[2][2]);

	lowp vec3 maximum = max3(max3(cas_nbh[0][1], cas_nbh[1][1], cas_nbh[2][1]), cas_nbh[1][0], cas_nbh[1][2]);
	maximum += max3(max3(maximum, cas_nbh[0][0], cas_nbh[2][0]), cas_nbh[0][2], cas_nbh[2][2]);

	// Smooth minimum distance to signal limit divided by smooth max.
	immut lowp vec3 amplify = sqrt(saturate(min(minimum, 2.0 - maximum) / maximum));

	// Filter shape:
	// 0 w 0
	// w 1 w
	// 0 w 0
	const lowp float sharpness = -1.0 / mix(8.0, 5.0, CAS_SHARPNESS);
	immut lowp float weight = sharpness * luminance(amplify);
	immut lowp float rcp_rcp_weight = fma(weight, 4.0, 1.0); // This naming is cursed.

	fragColor = vec4(srgb(saturate(((cas_nbh[1][0] + cas_nbh[0][1] + cas_nbh[2][1] + cas_nbh[1][2]) * weight + cas_nbh[1][1]) / rcp_rcp_weight)), 0.0);
}
