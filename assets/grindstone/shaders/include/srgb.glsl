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
