#include "/lib/core.glsl"

uniform layout(rgb10_a2) restrict writeonly image2D colorimg0;
uniform sampler2D tempColS, blendWeightS;
uniform vec2 pixSize;

#include "/lib/srgb.glsl"

void main() {
	immut ivec2 texel = ivec2(gl_GlobalInvocationID.xy);

	immut vec4 a = vec4(
		texelFetchOffset(blendWeightS, texel, 0, ivec2(1, 0)).w,
		texelFetchOffset(blendWeightS, texel, 0, ivec2(0, 1)).y,
		texelFetch(blendWeightS, texel, 0).zx
	);

	vec3 color;

	if (dot(a, vec4(1.0)) < 1.0e-5) {
		color = texelFetch(tempColS, texel, 0).rgb;
	} else {
		immut bool h = max(a.x, a.z) > max(a.y, a.w);

		immut vec4 blending_offset = h ? vec4(a.x, 0.0, a.z, 0.0) : vec4(0.0, a.y, 0.0, a.w);

		vec2 blending_weight = h ? a.xz : a.yw;
		blending_weight /= dot(blending_weight, vec2(1.0));

		immut vec4 blending_coord = fma(blending_offset, vec4(pixSize, -pixSize), ((gl_GlobalInvocationID.xy + 0.5) * pixSize).xyxy);

		color = blending_weight.x * textureLod(tempColS, blending_coord.xy, 0.0).rgb;
		color += blending_weight.y * textureLod(tempColS, blending_coord.zw, 0.0).rgb;
	}

	#if DEBUG_BW
		#if DEBUG_BW == 1
			#define DEBUG_BW_COMP xyz
		#else
			#define DEBUG_BW_COMP yzw
		#endif

		color = texelFetch(blendWeightS, texel, 0).DEBUG_BW_COMP;
	#endif

	imageStore(colorimg0, texel, vec4(srgb(color), 0.0));
}