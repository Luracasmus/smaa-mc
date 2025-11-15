#define SampleLevelZero(x) SampleLevel(x, 0.0)

import aperture;
import lib.core;

extern static const float RCP_SCREEN_W;
extern static const float RCP_SCREEN_H;

const static float2 RCP_SCREEN = float2(RCP_SCREEN_W, RCP_SCREEN_H);

[format("rgba8")]
Sampler2D<float4> smaaBWTex;

[format("rgba16")]
Sampler2D<float3> color1Tex;

[format("rgb10a2")]
WTexture2D<float3> color0Img;

[[shader("compute")]]
[numthreads(16, 16, 1)]
void smaaBlend(uint3 pos : SV_DispatchThreadID) {
	const int2 texel = int2(pos.xy);

	const float4 a = float4(
		smaaBWTex.Load(int3(texel, 0), int2(1, 0)).w,
		smaaBWTex.Load(int3(texel, 0), int2(0, 1)).y,
		smaaBWTex.Load(int3(texel, 0)).zx
	);

	float3 color;

	if (dot(a, float4(1.0)) < 1.0e-5) {
		color = color1Tex.Load(int3(texel, 0));
	} else {
		const bool h = max(a.x, a.z) > max(a.y, a.w);

		const float4 blending_offset = h ? float4(a.x, 0.0, a.z, 0.0) : float4(0.0, a.y, 0.0, a.w);

		float2 blending_weight = h ? a.xz : a.yw;
		blending_weight /= dot(blending_weight, float2(1.0));

		const float2 coord = fma(float2(texel), RCP_SCREEN, 0.5 * RCP_SCREEN);

		color = blending_weight.x * color1Tex.SampleLevelZero(fma(blending_offset.xy, RCP_SCREEN, coord));
		color += blending_weight.y * color1Tex.SampleLevelZero(fma(blending_offset.zw, -RCP_SCREEN, coord));
	}

	color0Img.Store(texel, srgb(color));
}
