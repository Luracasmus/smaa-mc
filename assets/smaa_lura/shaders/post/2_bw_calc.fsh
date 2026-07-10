/*
	SMAA 1x Blending Weight Calculation
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

#version 450

#define SMAA_SEARCH 112 // [8 16 32 48 64 80 96 112]
#define SMAA_SEARCH_DIAG 20 // [0 4 8 12 16 20]
#define SMAA_CORNER 25 // [0 25 50 75 100]

#define immut

layout(depth_unchanged) out lowp float gl_FragDepth;

uniform sampler2D AreaSampler, EdgeSampler, SearchSampler;

layout(std140) uniform SamplerInfo {
	lowp vec2 OutSize; // Unused.
	lowp vec2 AreaSize; // Unused.
	highp vec2 EdgeSize;
	lowp vec2 SearchSize; // Unused.
};

out vec4 fragColor;

vec2 saturate(vec2 v) { return clamp(v, 0.0, 1.0); }

#if SMAA_SEARCH_DIAG
	vec2 decode_diag_bilinear_access(vec2 e) {
		e.x *= abs(fma(e.x, 5.0, -3.75));
		return roundEven(e);
	}

	vec4 decode_diag_bilinear_access(vec4 e) {
		e.xz *= abs(fma(e.xz, vec2(5.0), vec2(-3.75)));
		return roundEven(e);
	}

	vec2 area_diag(vec2 dist, vec2 e) {
		vec2 tex_coord = fma(fma(vec2(20.0), e, dist), 1.0 / vec2(160.0, 560.0), 0.5 / vec2(160.0, 560.0));
		tex_coord.x += 0.5;

		return textureLod(AreaSampler, saturate(tex_coord), 0.0).rg;
	}

	vec2 search_diag_1(vec2 pix_size, vec2 coord, vec2 dir, out vec2 end) {
		float w = 1.0;
		int z;
		for (z = -1; z < SMAA_SEARCH_DIAG - 1 && w > 0.9; ++z) {
			coord.xy += dir * pix_size;

			end = textureLod(EdgeSampler, coord.xy, 0.0).rg;
			w = dot(end, vec2(0.5));
		}
		return vec2(z, w);
	}

	vec2 search_diag_2(vec2 pix_size, vec2 coord, vec2 dir, out vec2 end) {
		coord.x += 0.25 * pix_size.x;

		float w = 1.0;
		int z;
		for (z = -1; z < SMAA_SEARCH_DIAG - 1 && w > 0.9; ++z) {
			coord.xy += dir * pix_size;

			end = textureLod(EdgeSampler, coord.xy, 0.0).rg;
			end = decode_diag_bilinear_access(end);

			w = dot(end, vec2(0.5));
		}
		return vec2(z, w);
	}

	vec2 calculate_diag_weights(vec2 pix_size, lowp ivec2 texel, vec2 coord, bool e_x) {
		vec2 weights = vec2(0.0);

		vec4 d;
		vec2 end;
		if (e_x) {
			d.xz = search_diag_1(pix_size, coord, ivec2(-1, 1), end);
			d.x += float(end.y > 0.9);
		} else d.xz = vec2(0.0);

		d.yw = search_diag_1(pix_size, coord, ivec2(1, -1), end);

		if (d.x + d.y > 2.0) {
			immut vec4 offset_coord = fma(vec4(0.25 - d.x, d.x, d.y, -d.y - 0.25), pix_size.xyxy, coord.xyxy);
			vec4 c = vec4(
				textureLodOffset(EdgeSampler, offset_coord.xy, 0.0, ivec2(-1, 0)).rg,
				textureLodOffset(EdgeSampler, offset_coord.zw, 0.0, ivec2(1, 0)).rg
			);
			c.yxwz = decode_diag_bilinear_access(c);

			weights += area_diag(d.xy, mix(fma(vec2(2.0), c.xz, c.yw), vec2(0.0), bvec2(step(0.9, d.zw))));
		}

		d.xz = search_diag_2(pix_size, coord, vec2(-1.0), end);

		if (texelFetchOffset(EdgeSampler, texel, 0, ivec2(1, 0)).r > 0.0) {
			d.yw = search_diag_2(pix_size, coord, vec2(1.0), end);
			d.y += float(end.y > 0.9);
		} else d.yw = vec2(0.0);

		if (d.x + d.y > 2.0) {
			immut vec4 offset_coord = fma(vec4(-d.xx, d.yy), pix_size.xyxy, coord.xyxy);
			immut vec4 c = vec4(
				textureLodOffset(EdgeSampler, offset_coord.xy, 0.0, ivec2(-1, 0)).g,
				textureLodOffset(EdgeSampler, offset_coord.xy, 0.0, ivec2(0, -1)).r,
				textureLodOffset(EdgeSampler, offset_coord.zw, 0.0, ivec2(1, 0)).gr
			);
			weights += area_diag(d.xy, mix(fma(vec2(2.0), c.xz, c.yw), vec2(0.0), bvec2(step(0.9, d.zw)))).yx;
		}

		return weights;
	}
#endif

vec2 area(vec2 dist, float e1, float e2) {
	return textureLod(AreaSampler, saturate(fma(
		fma(roundEven(4.0 * vec2(e1, e2)), vec2(16.0), dist),
		1.0 / vec2(160.0, 560.0),
		0.5 / vec2(160.0, 560.0)
	)), 0.0).rg;
}

float search_length(vec2 e, float offset) {
	return texelFetch(SearchSampler, clamp(ivec2(fma(e, vec2(32.0, -32.0), vec2(fma(offset, 66.0, 0.5), 32.5))), ivec2(0), ivec2(63, 15)), 0).r;
}

float search_x_left(vec2 pix_size, vec2 coord, float end) {
	vec2 e = vec2(0.0, 1.0);

	while (coord.x > end && e.y > 0.8281 && e.x == 0.0) {
		e = textureLod(EdgeSampler, coord, 0.0).rg;
		coord.x = fma(pix_size.x, -2.0, coord.x);
	}
	return fma(fma(search_length(e, 0.0), -255.0/127.0, 3.25), pix_size.x, coord.x);
}

float search_x_right(vec2 pix_size, vec2 coord, float end) {
	vec2 e = vec2(0.0, 1.0);

	while (coord.x < end && e.y > 0.8281 && e.x == 0.0) {
		e = textureLod(EdgeSampler, coord, 0.0).rg;
		coord.x = fma(pix_size.x, 2.0, coord.x);
	}
	return fma(fma(search_length(e, 0.5), 255.0/127.0, -3.25), pix_size.x, coord.x);
}

float search_y_up(vec2 pix_size, vec2 coord, float end) {
	vec2 e = vec2(1.0, 0.0);

	while (coord.y > end && e.x > 0.8281 && e.y == 0.0) {
		e = textureLod(EdgeSampler, coord, 0.0).rg;
		coord.y -= 2.0 * pix_size.y;
	}
	return fma(fma(search_length(e.yx, 0.0), -255.0/127.0, 3.25), pix_size.y, coord.y);
}

float search_y_down(vec2 pix_size, vec2 coord, float end) {
	vec2 e = vec2(1.0, 0.0);

	while (coord.y < end && e.x > 0.8281 && e.y == 0.0) {
		e = textureLod(EdgeSampler, coord, 0.0).rg;
		coord.y += 2.0 * pix_size.y;
	}
	return fma(fma(search_length(e.yx, 0.5), 255.0/127.0, -3.25), pix_size.y, coord.y);
}

#if SMAA_CORNER
	vec2 corner_rounding(vec2 d) {
		immut vec2 left_right = step(d, d.yx);
		return (1.0 - float(SMAA_CORNER) / 100.0) * left_right / (left_right.x + left_right.y);
	}

	vec2 detect_horizontal_corner_pattern(vec3 coord, vec2 d) {
		immut vec2 rounding = corner_rounding(d);

		return clamp(1.0 - vec2(
			dot(rounding, vec2(
				textureLodOffset(EdgeSampler, coord.xy, 0.0, ivec2(0, 1)).r,
				textureLodOffset(EdgeSampler, coord.zy, 0.0, ivec2(1, 1)).r
			)),
			dot(rounding, vec2(
				textureLodOffset(EdgeSampler, coord.xy, 0.0, ivec2(0, -2)).r,
				textureLodOffset(EdgeSampler, coord.zy, 0.0, ivec2(1, -2)).r
			))
		), 0.0, 1.0);
	}

	vec2 detect_vertical_corner_pattern(vec3 coord, vec2 d) {
		immut vec2 rounding = corner_rounding(d);

		return clamp(1.0 - vec2(
			dot(rounding, vec2(
				textureLodOffset(EdgeSampler, coord.xy, 0.0, ivec2(1, 0)).g,
				textureLodOffset(EdgeSampler, coord.zy, 0.0, ivec2(1, 1)).g
			)),
			dot(rounding, vec2(
				textureLodOffset(EdgeSampler, coord.xy, 0.0, ivec2(-2, 0)).g,
				textureLodOffset(EdgeSampler, coord.zy, 0.0, ivec2(-2, 1)).g
			))
		), 0.0, 1.0);
	}
#endif

void main() {
	immut vec2 pix_size = 1.0 / EdgeSize;
	immut lowp ivec2 texel = ivec2(gl_FragCoord.xy);
	bvec2 e = greaterThanEqual(texelFetch(EdgeSampler, texel, 0).rg, vec2(0.5));

	vec4 weights = vec4(0.0);

	if (any(e)) {
		immut vec2 coord = gl_FragCoord.xy * pix_size;

		immut vec4 offsets_0 = fma(pix_size.xyxy, vec4(-0.250, -0.125, 1.250, -0.125), coord.xyxy);
		immut vec4 offsets_1 = fma(pix_size.xyxy, vec4(-0.125, -0.250, -0.125, 1.250), coord.xyxy);
		immut vec4 offsets_2 = fma(pix_size.xxyy, vec4(ivec4(-2, 2, -2, 2) * SMAA_SEARCH), vec4(offsets_0.xz, offsets_1.yw));

		if (e.y) {
			#if SMAA_SEARCH_DIAG
				weights.xy = calculate_diag_weights(pix_size, texel, coord, e.x);

				if (weights.x == -weights.y) {
			#endif
					immut vec3 offset_coord = vec3(search_x_left(pix_size, offsets_0.xy, offsets_2.x), offsets_1.y, search_x_right(pix_size, offsets_0.zw, offsets_2.y));

					immut float e1 = textureLod(EdgeSampler, offset_coord.xy, 0.0).r;
					immut float e2 = textureLodOffset(EdgeSampler, offset_coord.zy, 0.0, ivec2(1, 0)).r;
					immut vec2 dist = abs(roundEven(fma(offset_coord.xz, EdgeSize.xx, -gl_FragCoord.xy.xx)));

					weights.xy = area(sqrt(dist), e1, e2);

					#if SMAA_CORNER
						weights.xy *= detect_horizontal_corner_pattern(vec3(offset_coord.x, coord.y, offset_coord.z), dist);
					#endif
			#if SMAA_SEARCH_DIAG
				} else e.x = false;
			#endif
		}

		if (e.x) {
			immut vec3 offset_coord = vec3(offsets_0.x, search_y_up(pix_size, offsets_1.xy, offsets_2.z), search_y_down(pix_size, offsets_1.zw, offsets_2.w));

			immut float e1 = textureLod(EdgeSampler, offset_coord.xy, 0.0).g;
			immut float e2 = textureLodOffset(EdgeSampler, offset_coord.xz, 0.0, ivec2(0, 1)).g;
			immut vec2 dist = abs(roundEven(fma(offset_coord.yz, EdgeSize.yy, -gl_FragCoord.xy.yy)));

			weights.zw = area(sqrt(dist), e1, e2);

			#if SMAA_CORNER
				weights.zw *= detect_vertical_corner_pattern(vec3(coord.x, offset_coord.yz), dist);
			#endif
		}
	}

	fragColor = weights;
}
