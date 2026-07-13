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

// Swap buffer color encoding (square root of linear sRGB encoded as R11G11B10 stored in a RGBA8 buffer) that should be faster than sRGB but not cause any differences to the final color during the conversion:
// sRGB RGBA8 -> linear float -> this -> linear float -> sRGB RGBA8
// (the encoding should not cause distortion that causes the later linear float to round to a different sRGB unorm8 value)
//
// See: https://www.desmos.com/calculator/cln6hdgkjj

lowp vec4 encode_swap(lowp vec3 color) {
	immut highp uvec3 scaled = uvec3(fma(sqrt(color), vec3(2047.0, 2047.0, 1023.0), vec3(0.5)));

	return unpackUnorm4x8(
		bitfieldInsert(bitfieldInsert(scaled.r, scaled.g, 11, 11), scaled.b, 22, 10)
	);
}

lowp vec3 decode_swap(lowp vec4 encoded) {
	immut lowp uvec4 scaled = uvec4(encoded * 255.0);

	// Transmute the [u8, u8, u8, u8] above into [u11, u11, u10] and scale down to normalized range.
	immut lowp vec3 square_root = vec3(
		bitfieldInsert(scaled.r, scaled.g, 8, 3),
		bitfieldInsert(scaled.g >> 3u, scaled.b, 5, 6),
		bitfieldInsert(scaled.b >> 6u, scaled.a, 2, 8)
	) / vec3(2047.0, 2047.0, 1023.0);

	return square_root * square_root;
}

highp uint pack_unorm8(lowp vec4 v) {
	immut highp uvec4 scaled = uvec4(fma(v, vec4(255.0), vec4(0.5)));

	return bitfieldInsert(bitfieldInsert(bitfieldInsert(scaled.r, scaled.g, 8, 8), scaled.b, 16, 8), scaled.a, 24, 8);
}
