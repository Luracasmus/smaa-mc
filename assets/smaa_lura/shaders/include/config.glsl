/*
	Copyright (C) 2024-2026 Luracasmus

	All rights reserved unless explicitly stated.
*/

// The threshold used in color-based SMAA edge detection.
// Lower values cause more edges to be anti-aliased.
#define SMAA_THRESHOLD 0.05 // [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]

// The maximum amount of steps in vertical and horizontal SMAA pattern searches.
// Distance searched in pixels is double this value.
#define SMAA_SEARCH 112 // [8 16 32 48 64 80 96 112]

// The maximum amount of diagonal steps/pixels searched in SMAA pattern searches.
// `0` disables diagonal processing.
#define SMAA_SEARCH_DIAG 20 // [0 4 8 12 16 20]

// SMAA corner rounding.
// `0` disables corner processing.
#define SMAA_CORNER 25 // [0 25 50 75 100]

// SMAA blending weights visualization.
// `0` disables the feature.
// `1` and `2` visualize different components of the blending weights texture.
#define DEBUG_BW 0 // [0 1 2]

// CAS sharpness from low to high.
// The effect is still visible at `0.0`.
#define CAS_SHARPNESS 0.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

// Force all variables to use high precision on Vulkan.
// This may impact performance negatively,
// but can work around bugs that occur due to how graphics drivers handle relaxed precision.
// Please report any problems that are solved by this!
// Uncomment the line below (remove `//`) to enable the option:
// #define lowp highp
