/*
	Copyright (C) 2024-2026 Luracasmus

	All rights reserved unless explicitly stated.
*/

lowp vec3 linear(lowp vec3 srgb) {
	return mix(
		pow((srgb + 0.055) / 1.055, vec3(2.4)),
		srgb / 12.92,
		lessThanEqual(srgb, vec3(0.04045))
	);
}

lowp vec3 srgb(lowp vec3 linear) {
	return mix(
		1.055 * pow(linear, vec3(1.0/2.4)) - 0.055,
		12.92 * linear,
		lessThanEqual(linear, vec3(0.0031308))
	);
}
