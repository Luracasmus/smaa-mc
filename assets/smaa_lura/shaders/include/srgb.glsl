/*
	Copyright (C) 2024-2026 Luracasmus

	All rights reserved unless explicitly stated.
*/

lowp float linear(lowp float srgb) {
	return (srgb > 0.04045)
		? pow(fma(srgb, 1.0/1.055, 0.055/1.055), 2.4)
		: (srgb / 12.92);
}

lowp vec3 linear(lowp vec3 srgb) {
	return vec3(
		linear(srgb.r),
		linear(srgb.g),
		linear(srgb.b)
	);
}

lowp float srgb(lowp float linear) {
	return (linear > 0.0031308)
		? fma(pow(linear, 1.0/2.4), 1.055, -0.055)
		: (linear * 12.92);
}

lowp vec3 srgb(lowp vec3 linear) {
	return vec3(
		srgb(linear.r),
		srgb(linear.g),
		srgb(linear.b)
	);
}

// Swap buffer color encoding that should be faster than sRGB but not cause any differences to the final color during the conversion:
// sRGB RGBA8 -> linear RGB32F -> this RGBA8 -> linear RGB32F -> sRGB RGBA8
// (the encoding should not cause distortion that causes the later linear f32 to round to a different sRGB unorm8 value)
//
// See: https://www.desmos.com/calculator/cln6hdgkjj

lowp vec4 encode_swap(lowp vec3 color) {
	immut highp uvec3 scaled = uvec3(fma(sqrt(color), vec3(2047.0, 2047.0, 1023.0), vec3(0.5)));

	return unpackUnorm4x8(
		bitfieldInsert(bitfieldInsert(scaled.r, scaled.g, 11, 11), scaled.b, 22, 10)
	);
}

lowp vec3 decode_swap(lowp vec4 encoded) {
	immut highp uint packed_color = packUnorm4x8(encoded);
	immut lowp vec3 square_root = vec3(
		packed_color & 2047u,
		bitfieldExtract(packed_color, 11, 11),
		packed_color >> 22u
	) / vec3(2047.0, 2047.0, 1023.0);

	return square_root * square_root;
}
