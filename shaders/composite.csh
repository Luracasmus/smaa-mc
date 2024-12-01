#include "/lib/core.glsl"

uniform sampler2D colortex0;
uniform layout(rg8) restrict writeonly image2D edge;
uniform layout(rgb10_a2) restrict writeonly image2D tempCol;

#include "/lib/srgb.glsl"

void main() {
	immut ivec2 texel = ivec2(gl_GlobalInvocationID.xy);

	const float local_contrast_adaption_factor = 2.0;

	vec4 delta;
	immut vec3 color = linear(texelFetch(colortex0, texel, 0).rgb);
	imageStore(tempCol, texel, vec4(color, 0.0));

	immut vec3 left = linear(texelFetchOffset(colortex0, texel, 0, ivec2(-1, 0)).rgb);
	vec3 t = abs(color - left);
	delta.x = max(max(t.r, t.g), t.b);

	immut vec3 top = linear(texelFetchOffset(colortex0, texel, 0, ivec2(0, -1)).rgb);
	t = abs(color - top);
	delta.y = max(max(t.r, t.g), t.b);

	immut vec2 edges = step(SMAA_THRESHOLD, delta.xy);

	vec4 detected_edges = vec4(0.0);

	if (dot(edges, vec2(1.0)) != 0.0) {
		immut vec3 right = linear(texelFetchOffset(colortex0, texel, 0, ivec2(1, 0)).rgb);
		t = abs(color - right);
		delta.z = max(max(t.r, t.g), t.b);

		immut vec3 bottom = linear(texelFetchOffset(colortex0, texel, 0, ivec2(0, 1)).rgb);
		t = abs(color - bottom);
		delta.w = max(max(t.r, t.g), t.b);

		vec2 delta_max = max(delta.xy, delta.zw);

		immut vec3 left_2 = linear(texelFetchOffset(colortex0, texel, 0, ivec2(-2, 0)).rgb);
		t = abs(color - left_2);
		delta.z = max(max(t.r, t.g), t.b);

		immut vec3 top_2 = linear(texelFetchOffset(colortex0, texel, 0, ivec2(0, -2)).rgb);
		t = abs(color - top_2);
		delta.w = max(max(t.r, t.g), t.b);

		delta_max = max(delta_max.xy, delta.zw);

		detected_edges.xy = edges * step(max(delta_max.x, delta_max.y), local_contrast_adaption_factor * delta.xy);
	}

	imageStore(edge, texel, detected_edges);
}