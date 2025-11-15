import aperture;
import lib.core;

extern static const float SMAA_THRESHOLD;

[format("rgb10a2")]
Sampler2D<float3> color0Tex;

[format("rgba16")]
WTexture2D<float3> color1Img;

[format("rg8")]
WTexture2D<float2> smaaEdgeImg;

float redmean(float3 a, float3 b) {
	const float r = step(0.5, lerp(a.r, b.r, 0.5));
	const float3 d = a - b;

	return sqrt(dot(d*d, float3(
		2.0 + r,
		4.0,
		3.0 - r
	)));
}

[[shader("compute")]]
[numthreads(16, 16, 1)]
void smaaEdgeDetect(uint3 pos : SV_DispatchThreadID) {
	const int2 texel = int2(pos.xy);

	const float3 color = color0Tex[texel];

	color1Img.Store(texel, linear(color));

	const float3 left = color0Tex.Load(int3(texel, 0), int2(-1, 0));
	const float3 top = color0Tex.Load(int3(texel, 0), int2(0, -1));

	float4 delta;
	delta.xy = float2(
		redmean(color, left),
		redmean(color, top)
	);

	const bool2 edges = delta.xy >= SMAA_THRESHOLD;

	if (any(edges)) {
		delta.zw = float2(
			redmean(color, color0Tex.Load(int3(texel, 0), int2(1, 0))), // right
			redmean(color, color0Tex.Load(int3(texel, 0), int2(0, 1))) // bottom
		);

		float2 delta_max = max(delta.xy, delta.zw);

		delta.zw = float2(
			redmean(left, color0Tex.Load(int3(texel, 0), int2(-2, 0))), // left-left
			redmean(top, color0Tex.Load(int3(texel, 0), int2(0, -2))) // top-top
		);

		delta_max = max(delta_max.xy, delta.zw);

		const float local_contrast_adaptation_factor = 2.0;
		const bool2 temp = delta.xy >= (max(delta_max.x, delta_max.y) / local_contrast_adaptation_factor).xx;
		const bool2 result = edges && temp;

		if (any(result)) {
			smaaEdgeImg.Store(texel, float2(result));
		}
	}
}
