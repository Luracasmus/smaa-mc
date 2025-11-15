// calc is short for calculation, btw

// Why is this needed?
#define SampleLevelZero(x, y) SampleLevel(x, 0.0, y)
#define SampleLevelZero1(x) SampleLevel(x, 0.0)

import aperture;

extern static const int SMAA_SEARCH;
extern static const int SMAA_SEARCH_DIAG;
extern static const int SMAA_CORNER;

extern static const float RCP_SCREEN_W;
extern static const float RCP_SCREEN_H;

const static float2 rcp_screen = float2(RCP_SCREEN_W, RCP_SCREEN_H);

[format("rg8")]
Sampler2D<float2> smaaAreaTex;

[format("r8")]
Sampler2D<float> smaaSearchTex;

[format("rg8")]
Sampler2D<float2> smaaEdgeTex;

[format("rgba8")]
WTexture2D<float4> smaaBWImg;

[[shader("compute")]]
[numthreads(16, 16, 1)]
void smaaBWCalc(uint3 pos : SV_DispatchThreadID) {
	const int2 texel = int2(pos.xy);
	bool2 e = smaaEdgeTex.Load(int3(texel, 0)) >= float2(0.5);

	if (any(e)) {
		const float2 texel_coord = pos.xy + 0.5;
		const float2 coord = texel_coord * rcp_screen;

		const float4 offsets_0 = fma(rcp_screen.xyxy, float4(-0.250, -0.125, 1.250, -0.125), coord.xyxy);
		const float4 offsets_1 = fma(rcp_screen.xyxy, float4(-0.125, -0.250, -0.125, 1.250), coord.xyxy);
		const float4 offsets_2 = fma(rcp_screen.xxyy, float4(int4(-2, 2, -2, 2) * SMAA_SEARCH), float4(offsets_0.xz, offsets_1.yw));

		float4 weights = float4(0.0);

		if (e.y) {
			if (SMAA_SEARCH_DIAG != 0) {
				weights.xy = calculate_diag_weights(texel, coord, e.x);
			}

				if (SMAA_SEARCH_DIAG == 0 || weights.x == -weights.y) {
					const float3 offset_coord = float3(search_x_left(offsets_0.xy, offsets_2.x), offsets_1.y, search_x_right(offsets_0.zw, offsets_2.y));

					const float e1 = smaaEdgeTex.SampleLevelZero1(offset_coord.xy).r;
					const float e2 = smaaEdgeTex.SampleLevelZero(offset_coord.zy, int2(1, 0)).r;
					const float2 dist = abs(rint(fma(offset_coord.xz, float2(1.0 / rcp_screen.x), -texel_coord.xx)));

					weights.xy = area(sqrt(dist), e1, e2);

					if (SMAA_CORNER != 0) {
						weights.xy *= detect_horizontal_corner_pattern(float3(offset_coord.x, coord.y, offset_coord.z), dist);
					}
				} else if (SMAA_SEARCH_DIAG != 0) {
					e.x = false;
				}
		}

		if (e.x) {
			const float3 offset_coord = float3(offsets_0.x, search_y_up(offsets_1.xy, offsets_2.z), search_y_down(offsets_1.zw, offsets_2.w));

			const float e1 = smaaEdgeTex.SampleLevelZero1(offset_coord.xy).g;
			const float e2 = smaaEdgeTex.SampleLevelZero(offset_coord.xz, int2(0, 1)).g;
			const float2 dist = abs(rint(fma(offset_coord.yz, float2(1.0 / rcp_screen.y), -texel_coord.yy)));

			weights.zw = area(sqrt(dist), e1, e2);

			if (SMAA_CORNER != 0) {
				weights.zw *= detect_vertical_corner_pattern(float3(coord.x, offset_coord.yz), dist);
			}
		}

		smaaBWImg.Store(texel, weights);
	}
}

// #if SMAA_SEARCH_DIAG != 0
	float2 decode_diag_bilinear_access(float2 e) {
		e.x *= abs(fma(e.x, 5.0, -3.75));
		return rint(e);
	}

	float4 decode_diag_bilinear_access(float4 e) {
		e.xz *= abs(fma(e.xz, float2(5.0), float2(-3.75)));
		return rint(e);
	}

	float2 area_diag(float2 dist, float2 e) {
		float2 tex_coord = fma(fma(float2(20.0), e, dist), 1.0 / float2(160.0, 560.0), 0.5 / float2(160.0, 560.0));
		tex_coord.x += 0.5;

		return smaaAreaTex.SampleLevelZero1(tex_coord);
	}

	float2 search_diag_1(float2 coord, float2 dir, out float2 end) {
		float w = 1.0;
		int z;
		for (z = -1; z < SMAA_SEARCH_DIAG - 1 && w > 0.9; ++z) {
			coord.xy += dir * rcp_screen;

			end = smaaEdgeTex.SampleLevelZero1(coord.xy);
			w = dot(end, float2(0.5));
		}
		return float2(z, w);
	}

	float2 search_diag_2(float2 coord, float2 dir, out float2 end) {
		coord.x += 0.25 * rcp_screen.x;

		float w = 1.0;
		int z;
		for (z = -1; z < SMAA_SEARCH_DIAG - 1 && w > 0.9; ++z) {
			coord.xy += dir * rcp_screen;

			end = smaaEdgeTex.SampleLevelZero1(coord.xy);
			end = decode_diag_bilinear_access(end);

			w = dot(end, float2(0.5));
		}
		return float2(z, w);
	}

	float2 calculate_diag_weights(int2 texel, float2 coord, bool e_x) {
		float2 weights = float2(0.0);

		float4 d;
		float2 end;
		if (e_x) {
			d.xz = search_diag_1(coord, int2(-1, 1), end);
			d.x += float(end.y > 0.9);
		} else d.xz = float2(0.0);

		d.yw = search_diag_1(coord, int2(1, -1), end);

		if (d.x + d.y > 2.0) {
			const float4 offset_coord = fma(float4(0.25 - d.x, d.x, d.y, -d.y - 0.25), rcp_screen.xyxy, coord.xyxy);
			float4 c = float4(
				smaaEdgeTex.SampleLevelZero(offset_coord.xy, int2(-1, 0)),
				smaaEdgeTex.SampleLevelZero(offset_coord.zw, int2(1, 0))
			);
			c.yxwz = decode_diag_bilinear_access(c);

			weights += area_diag(d.xy, select(bool2(step(0.9, d.zw)), float2(0.0), fma(float2(2.0), c.xz, c.yw)));
		}

		d.xz = search_diag_2(coord, float2(-1.0), end);

		if (smaaEdgeTex.Load(int3(texel, 0), int2(1, 0)).r > 0.0) {
			d.yw = search_diag_2(coord, float2(1.0), end);
			d.y += float(end.y > 0.9);
		} else d.yw = float2(0.0);

		if (d.x + d.y > 2.0) {
			const float4 offset_coord = fma(float4(-d.xx, d.yy), rcp_screen.xyxy, coord.xyxy);
			const float4 c = float4(
				smaaEdgeTex.SampleLevelZero(offset_coord.xy, int2(-1, 0)).g,
				smaaEdgeTex.SampleLevelZero(offset_coord.xy, int2(0, -1)).r,
				smaaEdgeTex.SampleLevelZero(offset_coord.zw, int2(1, 0)).gr
			);
			weights += area_diag(d.xy, select(bool2(step(0.9, d.zw)), float2(0.0), fma(float2(2.0), c.xz, c.yw))).yx;
		}

		return weights;
	}
// #endif

float2 area(float2 dist, float e1, float e2) {
	return smaaAreaTex.SampleLevelZero1(fma(
		fma(rint(4.0 * float2(e1, e2)), float2(16.0), dist),
		1.0 / float2(160.0, 560.0),
		0.5 / float2(160.0, 560.0)
	));
}

float search_length(float2 e, float offset) {
	return smaaSearchTex.Load(int3(int2(fma(e, float2(32.0, -32.0), float2(fma(offset, 66.0, 0.5), 32.5))), 0)).r;
}

float search_x_left(float2 coord, float end) {
	float2 e = float2(0.0, 1.0);

	while (coord.x > end && e.y > 0.8281 && e.x == 0.0) {
		e = smaaEdgeTex.SampleLevelZero1(coord);
		coord.x = fma(rcp_screen.x, -2.0, coord.x);
	}
	return fma(fma(search_length(e, 0.0), -255.0/127.0, 3.25), rcp_screen.x, coord.x);
}

float search_x_right(float2 coord, float end) {
	float2 e = float2(0.0, 1.0);

	while (coord.x < end && e.y > 0.8281 && e.x == 0.0) {
		e = smaaEdgeTex.SampleLevelZero1(coord);
		coord.x = fma(rcp_screen.x, 2.0, coord.x);
	}
	return fma(fma(search_length(e, 0.5), 255.0/127.0, -3.25), rcp_screen.x, coord.x);
}

float search_y_up(float2 coord, float end) {
	float2 e = float2(1.0, 0.0);

	while (coord.y > end && e.x > 0.8281 && e.y == 0.0) {
		e = smaaEdgeTex.SampleLevelZero1(coord);
		coord.y -= 2.0 * rcp_screen.y;
	}
	return fma(fma(search_length(e.yx, 0.0), -255.0/127.0, 3.25), rcp_screen.y, coord.y);
}

float search_y_down(float2 coord, float end) {
	float2 e = float2(1.0, 0.0);

	while (coord.y < end && e.x > 0.8281 && e.y == 0.0) {
		e = smaaEdgeTex.SampleLevelZero1(coord);
		coord.y += 2.0 * rcp_screen.y;
	}
	return fma(fma(search_length(e.yx, 0.5), 255.0/127.0, -3.25), rcp_screen.y, coord.y);
}

// #if SMAA_CORNER
	float2 corner_rounding(float2 d) {
		const float2 left_right = step(d, d.yx);
		return (1.0 - float(SMAA_CORNER) / 100.0) * left_right / (left_right.x + left_right.y);
	}

	float2 detect_horizontal_corner_pattern(float3 coord, float2 d) {
		const float2 rounding = corner_rounding(d);

		return clamp(1.0 - float2(
			dot(rounding, float2(
				smaaEdgeTex.SampleLevelZero(coord.xy, int2(0, 1)).r,
				smaaEdgeTex.SampleLevelZero(coord.zy, int2(1, 1)).r
			)),
			dot(rounding, float2(
				smaaEdgeTex.SampleLevelZero(coord.xy, int2(0, -2)).r,
				smaaEdgeTex.SampleLevelZero(coord.zy, int2(1, -2)).r
			))
		), 0.0, 1.0);
	}

	float2 detect_vertical_corner_pattern(float3 coord, float2 d) {
		const float2 rounding = corner_rounding(d);

		return clamp(1.0 - float2(
			dot(rounding, float2(
				smaaEdgeTex.SampleLevelZero(coord.xy, int2(1, 0)).g,
				smaaEdgeTex.SampleLevelZero(coord.zy, int2(1, 1)).g
			)),
			dot(rounding, float2(
				smaaEdgeTex.SampleLevelZero(coord.xy, int2(-2, 0)).g,
				smaaEdgeTex.SampleLevelZero(coord.zy, int2(-2, 1)).g
			))
		), 0.0, 1.0);
	}
// #endif
