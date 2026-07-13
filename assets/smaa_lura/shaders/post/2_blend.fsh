/*
	SMAA 1x Color Edge Detection
	https://www.iryoku.com/smaa/
	https://github.com/iryoku/smaa

	Copyright (C) 2013 Jorge Jimenez (jorge@iryoku.com)
	Copyright (C) 2013 Jose I. Echevarria (joseignacioechevarria@gmail.com)
	Copyright (C) 2013 Belen Masia (bmasia@unizar.es)
	Copyright (C) 2013 Fernando Navarro (fernandn@microsoft.com)
	Copyright (C) 2013 Diego Gutierrez (diegog@unizar.es)
	Copyright (C) 2024-2026 Luracasmus

	Permission is hereby granted, free of charge, to any person obtaining a copy
	this software and associated documentation files (the "Software"), to deal in
	the Software without restriction, including without limitation the rights to
	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
	the Software, and to permit persons to whom the Software is furnished to do so,
	subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software. As clarification, there is no
	requirement that the copyright notice and permission be included in binary
	distributions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
	FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
	IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#version 440

#moj_import <smaa_lura:config.glsl>

#define immut

#moj_import <smaa_lura:srgb.glsl>

layout(depth_unchanged) out lowp float gl_FragDepth;

uniform lowp sampler2D BlendWeightSampler, MainSampler;

out lowp vec4 fragColor;

// Manual bilinearly filtered sample that actually gets interpolation right,
// since the texture is in sRGB.
lowp vec3 bilinearSampleMain(
	highp vec2 lower_texel_coord, // Texel space coordinates of the current texel minus `0.5`.
	highp vec2 blending_offset // Texel space offset.
) {
	immut highp vec2 offset_texel_coord = lower_texel_coord + blending_offset;
	highp vec2 texel_f32;
	immut lowp vec2 a = modf(offset_texel_coord, texel_f32);
	immut lowp ivec2 texel = ivec2(texel_f32);

	return mix(
		mix(linear(texelFetch(MainSampler, texel, 0).rgb), linear(texelFetchOffset(MainSampler, texel, 0, ivec2(1, 0)).rgb), a.x),
		mix(linear(texelFetchOffset(MainSampler, texel, 0, ivec2(0, 1)).rgb), linear(texelFetchOffset(MainSampler, texel, 0, ivec2(1, 1)).rgb), a.x),
		a.y
	);
}

void main() {
	immut lowp ivec2 texel = ivec2(gl_FragCoord.xy);

	immut lowp vec4 a = vec4(
		texelFetchOffset(BlendWeightSampler, texel, 0, ivec2(1, 0)).w,
		texelFetchOffset(BlendWeightSampler, texel, 0, ivec2(0, 1)).y,
		texelFetch(BlendWeightSampler, texel, 0).zx
	);

	lowp vec3 color;

	if (dot(a, vec4(1.0)) < 1.0e-5) {
		color = texelFetch(MainSampler, texel, 0).rgb;
	} else {
		immut bool h = max(a.x, a.z) > max(a.y, a.w);

		immut highp vec4 blending_offset = h ? vec4(a.x, 0.0, a.z, 0.0) : vec4(0.0, a.y, 0.0, a.w);

		lowp vec2 blending_weight = h ? a.xz : a.yw;
		blending_weight /= dot(blending_weight, vec2(1.0));

		immut highp vec2 lower_texel_coord = gl_FragCoord.xy - 0.5;

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
