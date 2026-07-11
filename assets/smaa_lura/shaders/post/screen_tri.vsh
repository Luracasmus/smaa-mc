/*
	Copyright (C) 2026 Luracasmus

	All rights reserved unless explicitly stated.
*/

#version 440

#define immut

out gl_PerVertex { vec4 gl_Position; };

void main() {
	immut lowp uint id = uint(
		#ifdef VULKAN
			gl_VertexIndex
		#else
			gl_VertexID
		#endif
	);
	immut highp vec2 uv = vec2(uvec2(id << 1u, id) & 2u);

	gl_Position = vec4(fma(uv, vec2(2.0), vec2(-1.0)), 0.0, 1.0);
}
