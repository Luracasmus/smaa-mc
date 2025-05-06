#include "/lib/core.glsl"

uniform sampler2D colortex0;
uniform layout(rg8) restrict writeonly image2D edge;
uniform layout(rgba16) restrict writeonly image2D tempCol;

#include "/lib/srgb.glsl"

// https://www.wikiwand.com/en/articles/Color_difference
float redmean(vec3 a, vec3 b) {
	immut float r = step(0.5, mix(a.r, b.r, 0.5));
	immut vec3 d = a - b;

	return sqrt(dot(d*d, vec3(
		2.0 + r,
		4.0,
		3.0 - r
	)));
}

void main() {
	immut ivec2 texel = ivec2(gl_GlobalInvocationID.xy);

	immut vec3 color = texelFetch(colortex0, texel, 0).rgb;
	imageStore(tempCol, texel, vec4(linear(color), 0.0));

	immut vec3 left = texelFetchOffset(colortex0, texel, 0, ivec2(-1, 0)).rgb;
	immut vec3 top = texelFetchOffset(colortex0, texel, 0, ivec2(0, -1)).rgb;

	vec4 delta;
	delta.xy = vec2(
		redmean(color, left),
		redmean(color, top)
	);

	immut bvec2 edges = greaterThanEqual(delta.xy, vec2(SMAA_THRESHOLD));

	if (any(edges)) {
		delta.zw = vec2(
			redmean(color, texelFetchOffset(colortex0, texel, 0, ivec2(1, 0)).rgb), // right
			redmean(color, texelFetchOffset(colortex0, texel, 0, ivec2(0, 1)).rgb) // bottom
		);

		vec2 delta_max = max(delta.xy, delta.zw);

		delta.zw = vec2(
			redmean(left, texelFetchOffset(colortex0, texel, 0, ivec2(-2, 0)).rgb), // left-left
			redmean(top, texelFetchOffset(colortex0, texel, 0, ivec2(0, -2)).rgb) // top-top
		);

		delta_max = max(delta_max.xy, delta.zw);

		const float local_contrast_adaptation_factor = 2.0;
		immut bvec2 temp = greaterThanEqual(delta.xy, (max(delta_max.x, delta_max.y) / local_contrast_adaptation_factor).xx);
		immut bvec2 result = bvec2(edges.x && temp.x, edges.y && temp.y); // gotta do this instead of result && temp on AMD :(

		if (any(result)) imageStore(edge, texel, vec4(
			result, 0.0, 0.0
		));
	}
}
