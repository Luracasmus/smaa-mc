A simple, post-processing only Iris shader pack implementing [Enhanced Subpixel Morphological Antialiasing 1x](https://github.com/iryoku/smaa) with improved edge detection using [redmean color difference](https://www.wikiwand.com/en/articles/Color_difference#sRGB)

All it does is very slightly smooth diagonal edges to reduce staircase-like artifacts with minimal performance impact, while leaving color, lighting and large-scale geometry as identical as possible to vanilla Minecraft

## Requirements

* **[Iris](https://github.com/IrisShaders/Iris)** with [features](https://shaders.properties/current/reference/shadersproperties/flags/):
  * `COMPUTE_SHADERS`
  * `CUSTOM_IMAGES`
* **[GLSL](https://www.wikiwand.com/en/OpenGL_Shading_Language) 4.60+**

> This may require updating your Iris version and graphics drivers
