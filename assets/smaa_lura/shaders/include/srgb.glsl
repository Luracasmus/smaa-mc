/*
	Copyright (C) 2024-2026 Luracasmus

	All rights reserved unless explicitly stated.
*/

// Good approximations of sRGB <-> linear conversion,
// utilizing the fact that the linear function is smaller/greater than the power function
// almost exactly in the part of the input range where it should be used.
//
// See: https://www.desmos.com/calculator/fgh5rvycuo

lowp float linear(lowp float srgb) {
	return min(
		pow(fma(srgb, 1.0/1.055, 0.055/1.055), 2.4),
		srgb / 12.92
	);
}

lowp vec3 linear(lowp vec3 srgb) {
	return min(
		pow(fma(srgb, vec3(1.0/1.055), vec3(0.055/1.055)), vec3(2.4)),
		srgb / 12.92
	);
}

lowp float srgb(lowp float linear) {
	return max(
		fma(pow(linear, 1.0/2.4), 1.055, -0.055),
		linear * 12.92
	);
}

lowp vec3 srgb(lowp vec3 linear) {
	return max(
		fma(pow(linear, vec3(1.0/2.4)), vec3(1.055), vec3(-0.055)),
		linear * 12.92
	);
}
