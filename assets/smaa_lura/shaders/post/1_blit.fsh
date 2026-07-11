/*
	Copyright (C) 2026 Luracasmus

	All rights reserved unless explicitly stated.
*/

#version 440

layout(depth_unchanged) out lowp float gl_FragDepth;

uniform lowp sampler2D MainSampler;

out lowp vec4 fragColor;

void main(){
	fragColor = vec4(texelFetch(MainSampler, ivec2(gl_FragCoord.xy), 0).rgb, 0.0);
}
