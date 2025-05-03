A simple Iris shader pack implementing [Enhanced Subpixel Morphological Antialiasing 1x](https://github.com/iryoku/smaa) in Minecraft using only compute shaders

All it does is very slightly smooth diagonal edges to reduce staircase-like artifacts with minimal performance impact, while leaving color, lighting and large-scale geometry as identical as possible to Vanilla

## Requirements

* **[Iris](https://github.com/IrisShaders/Iris)** with [features](https://shaders.properties/current/reference/shadersproperties/flags/):
  * `COMPUTE_SHADERS`
  * `CUSTOM_IMAGES`
* **[GLSL](https://www.wikiwand.com/en/OpenGL_Shading_Language) 4.60+**

> This may require updating your graphics drivers
