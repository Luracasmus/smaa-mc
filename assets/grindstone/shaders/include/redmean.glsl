/*
	Modified, based on "Colour metric" (https://www.compuphase.com/cmetric.htm),
	Copyright (c) 2019–2026 Thiadmer Riemersma,
	licensed under CC BY-SA 3.0 (https://creativecommons.org/licenses/by-sa/3.0/).

	This file is also licensed under CC BY‑SA 3.0.
	Modifications Copyright (c) 2026 Luracasmus.
*/

// Squared redmean color difference.
lowp float sq_redmean(lowp vec3 a, lowp vec3 b) {
	const lowp float r = mix(a.r, b.r, 0.5) * 0.99609375;
	const lowp vec3 d = a - b;

	return dot(d*d, vec3(
		2.0 + r,
		4.0,
		2.99609375 - r
	));
}
