#include "/prelude/core.glsl"

/* RENDERTARGETS: 0 */
#ifdef ALPHA_BLEND
	layout(location = 0) out vec4 colortex0;
#else
	layout(location = 0) out vec3 colortex0;
#endif

#ifdef TEXTURE
	uniform sampler2D gtexture;

	#ifdef ALPHA_CHECK
		uniform float alphaTestRef;
	#endif
#endif

in VertexData {
	#ifdef TINT_ALPHA
		layout(location = 0, component = 0) vec4 tint;
	#else
		layout(location = 0, component = 0) vec3 tint;
	#endif

	#ifdef TEXTURE
		layout(location = 1, component = 0) vec2 coord;
	#endif
} v;

#ifdef FOG
	uniform float far, fogStart, fogEnd, viewHeight, viewWidth;
	uniform vec3 fogColor;
	uniform mat4 gbufferModelViewInverse, gbufferProjectionInverse;

	float linear_step(float edge0, float edge1, float x) {
		return clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
	}
#endif

void main() {
	#ifdef TEXTURE
		#if defined ALPHA_CHECK || defined ALPHA_BLEND
			vec4 tex = texture(gtexture, v.coord);
		#else
			vec3 tex = texture(gtexture, v.coord).rgb;
		#endif

		#ifdef ALPHA_CHECK
			if (tex.a < alphaTestRef) discard;
		#endif

		tex.rgb *= v.tint.rgb;

		#ifdef ALPHA_BLEND
			colortex0 = tex;
		#else
			colortex0 = tex.rgb;
		#endif
	#else
		colortex0 = v.tint;
	#endif

	#ifdef FOG
		immut vec3 ndc = fma(gl_FragCoord.xyz, vec3(2.0 / vec2(viewWidth, viewHeight), 2.0), vec3(-1.0));
		immut vec3 view = proj_inv(gbufferProjectionInverse, ndc);
		immut vec3 pe = mat3(gbufferModelViewInverse) * view;

		immut float dist = length(pe);

		#ifdef CLOUD_FOG
			immut float visibility = linear_step(float(CLOUD_FOG_END * 16), 0.0, dist);
			colortex0.a *= visibility;
		#else
			immut float cyl_dist = max(length(pe.xz), abs(pe.y));
			immut float fog = max(
				linear_step(fogStart, fogEnd, dist), // Spherical environment fog
				linear_step(far + float(BORDER_FOG_REL_START), far, cyl_dist) // Cylidrical border fog
			);

			colortex0.rgb = mix(colortex0.rgb, fogColor, fog);
		#endif
	#endif
}
