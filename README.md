A simple Iris shader pack implementing [Enhanced Subpixel Morphological Antialiasing 1x](https://github.com/iryoku/smaa) with improved edge detection using [redmean color difference](https://www.wikiwand.com/en/articles/Color_difference#sRGB)

It intelligently smoothes diagonal edges to reduce staircase-like artifacts with minimal performance impact, while leaving color, lighting and large-scale geometry as identical as possible to vanilla Minecraft. It includes the highly optimized implementation of vanilla-like rendering from [Base-460C](https://github.com/Luracasmus/Base-460C)

## Requirements

> If you have a decently modern non-macOS device it probably supports everything you need, but you might have to update your Iris and graphics drivers

* **[Iris](https://github.com/IrisShaders/Iris)** with [features](https://shaders.properties/current/reference/shadersproperties/flags/):
  * `COMPUTE_SHADERS`
  * `CUSTOM_IMAGES`
  * `ENTITY_TRANSLUCENT`
* **[GLSL](https://www.wikiwand.com/en/OpenGL_Shading_Language) 4.60.8+**
