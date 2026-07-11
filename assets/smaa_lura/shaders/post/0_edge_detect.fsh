/*
	SMAA 1x Color Edge Detection
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

#define SMAA_THRESHOLD 0.05 // [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]

#define immut

layout(depth_unchanged) out lowp float gl_FragDepth;

uniform lowp sampler2D MainSampler;

out lowp vec4 fragColor;

// https://en.wikipedia.org/wiki/Color_difference#sRGB
lowp float redmean(lowp vec3 a, lowp vec3 b) {
	immut lowp float r = step(0.5, mix(a.r, b.r, 0.5));
	immut lowp vec3 d = a - b;

	return sqrt(dot(d*d, vec3(
		2.0 + r,
		4.0,
		3.0 - r
	)));
}

void main() {
	immut lowp ivec2 texel = ivec2(gl_FragCoord.xy);

	immut lowp vec3 color = texelFetch(MainSampler, texel, 0).rgb;

	immut lowp vec3 left = texelFetchOffset(MainSampler, texel, 0, ivec2(-1, 0)).rgb;
	immut lowp vec3 top = texelFetchOffset(MainSampler, texel, 0, ivec2(0, -1)).rgb;

	lowp vec4 delta;
	delta.xy = vec2(
		redmean(color, left),
		redmean(color, top)
	);

	immut bvec2 edges = greaterThanEqual(delta.xy, vec2(SMAA_THRESHOLD));

	lowp vec2 result_value;

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
		immut bvec2 temp = greaterThanEqual(delta.xy, (max(delta_max.x, delta_max.y) / local_contrast_adaptation_factor).xx);
		immut bvec2 result = bvec2(edges.x && temp.x, edges.y && temp.y); // This is required instead of `result && temp` on AMD :(

		result_value = any(result) ? vec2(result) : vec2(0.0);
	} else {
		result_value = vec2(0.0);
	}

	fragColor = vec4(result_value, 0.0, 0.0);
}
