#version 460 core

#define VERSION v // [v]

#define SMAA_THRESHOLD 0.02 // [0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1]
#define SMAA_SEARCH 112 // [8 16 32 48 64 80 96 112]
#define SMAA_SEARCH_DIAG 20 // [0 4 8 12 16 20]
#define SMAA_CORNER 25 // [0 25 50 75 100]

#define DEBUG_BW 0 // [0 1 2]
#define CONST_IMMUT 1 // [0 1 2]

#if (CONST_IMMUT == 1 && (defined MC_GL_VENDOR_NVIDIA || defined MC_GL_DRIVER_GEFORCE)) || CONST_IMMUT == 2
	#define immut const
#else
	#define immut
#endif

#define TILE 16
layout(local_size_x = TILE, local_size_y = TILE, local_size_z = 1) in;

const vec2 workGroupsRender = vec2(1.0, 1.0);

/*
	const bool colortex0Clear = false;
	const int colortex0Format = RGB16_A2;
*/