export function configureRenderer(renderer: RendererConfig): void {
	renderer.mergedHandDepth = true;
	renderer.ambientOcclusionLevel = 1.0;
	renderer.disableShade = false;
	renderer.render.entityShadow = true;
}

export function configurePipeline(pipeline: PipelineConfig): void {
	let color0Tex = pipeline
		.createImageTexture("color0Tex", "color0Img")
		.width(screenWidth)
		.height(screenHeight)
		.clear(false)
		.format(Format.RGB10_A2)
		.build();

	let color1Tex = pipeline
		.createImageTexture("color1Tex", "color1Img")
		.width(screenWidth)
		.height(screenHeight)
		.clear(false)
		.format(Format.RGBA16)
		.build();

	let smaaEdgeTex = pipeline
		.createImageTexture("smaaEdgeTex", "smaaEdgeImg")
		.width(screenWidth)
		.height(screenHeight)
		.clear(true)
		.format(Format.RG8)
		.build();

	let smaaBWTex = pipeline
		.createImageTexture("smaaBWTex", "smaaBWImg")
		.width(screenWidth)
		.height(screenHeight)
		.clear(true)
		.format(Format.RGBA8)
		.build();

	let smaaAreaTex = pipeline
		.importRawTexture("smaaAreaTex", "tex/smaa_area.bin")
		.width(160)
		.height(560)
		.depth(1)
		.blur(true)
		.clamp(true)
		.type(PixelType.UNSIGNED_BYTE)
		.format(Format.RG8);

	let smaaSearchTex = pipeline
		.importRawTexture("smaaSearchTex", "tex/smaa_search.bin")
		.width(64)
		.height(16)
		.depth(1)
		.blur(false)
		.clamp(true)
		.type(PixelType.UNSIGNED_BYTE)
		.format(Format.R8);

	pipeline
		.createObjectShader("basic", Usage.BASIC)
		.location("objects/basic")
		.target(0, color0Tex)
		.exportBool("FOG", true)
		.compile();

	pipeline
		.createObjectShader("sky", Usage.SKY_TEXTURES)
		.location("objects/basic")
		.target(0, color0Tex)
		.exportBool("FOG", false)
		.compile();

	let postRender = pipeline.forStage(Stage.POST_RENDER);

	postRender
		.createCompute("smaa_edge_detect")
		.location("post/smaa_edge_detect", "smaaEdgeDetect")
		.workGroups(
			Math.ceil(screenWidth / 16.0),
			Math.ceil(screenHeight / 16.0),
			1,
		)
		.exportFloat("SMAA_THRESHOLD", 0.1)
		.compile();

	postRender
		.createCompute("smaa_bw_calc")
		.location("post/smaa_bw_calc", "smaaBWCalc")
		.workGroups(
			Math.ceil(screenWidth / 16.0),
			Math.ceil(screenHeight / 16.0),
			1,
		)
		.exportInt("SMAA_SEARCH", 112)
		.exportInt("SMAA_SEARCH_DIAG", 20)
		.exportInt("SMAA_CORNER", 25)
		.exportFloat("RCP_SCREEN_W", 1.0 / screenWidth)
		.exportFloat("RCP_SCREEN_H", 1.0 / screenHeight)
		.compile();

	postRender
		.createCompute("smaa_blend")
		.location("post/smaa_blend", "smaaBlend")
		.workGroups(
			Math.ceil(screenWidth / 16.0),
			Math.ceil(screenHeight / 16.0),
			1,
		)
		.exportFloat("RCP_SCREEN_W", 1.0 / screenWidth)
		.exportFloat("RCP_SCREEN_H", 1.0 / screenHeight)
		.compile();

	postRender.end();

	pipeline.createCombinationPass("post/combination").compile();
}

// export function beginFrame(state: WorldState): void {}
