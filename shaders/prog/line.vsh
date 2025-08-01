#include "/prelude/core.glsl"

uniform float viewHeight, viewWidth;
uniform vec3 chunkOffset;
uniform mat4 modelViewMatrix, projectionMatrix;

in vec3 vaNormal, vaPosition;
in vec4 vaColor;

out VertexData {
	layout(location = 0, component = 0) vec4 tint;
} v;

void main() {
	v.tint = vaColor;

	immut vec3 model = vaPosition + chunkOffset;

	const float view_shrink = 1.0 - (1.0 / 256.0);
	immut vec4 start_clip = proj_mmul(projectionMatrix, view_shrink * rot_trans_mmul(modelViewMatrix, model));
	immut vec4 end_clip = proj_mmul(projectionMatrix, view_shrink * rot_trans_mmul(modelViewMatrix, model + vaNormal));

	vec3 start_ndc = start_clip.xyz / start_clip.w;
	immut vec3 end_ndc = end_clip.xyz / end_clip.w;

	const float line_width = 6.0; // todo!() make sure this matches Vanilla

	immut vec2 view_size = vec2(viewWidth, viewHeight);
	immut vec2 dir_screen = normalize((end_ndc.xy - start_ndc.xy) * view_size);
	vec2 offset_ndc = line_width / view_size * vec2(-dir_screen.y, dir_screen.x);

	start_ndc.xy += ((gl_VertexID & 1) == 0 ^^ offset_ndc.x < 0.0) ? -offset_ndc : offset_ndc;

	gl_Position = vec4(start_ndc * start_clip.w, start_clip.w);
}
