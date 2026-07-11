A **Vanilla shader resource pack** implementing anti-aliasing and sharpening using the end-of-frame post effect added in Minecraft 26.3 Snapshot 3. The technique is a modified [Enhanced Subpixel Morphological Antialiasing 1x](https://github.com/iryoku/smaa) followed by a modified [FidelityFX Contrast Adaptive Sharpening 1.2](https://gpuopen.com/manuals/fidelityfx_sdk/techniques/contrast-adaptive-sharpening/).

**The shaders require graphics drivers with support for GLSL 4.40**. If you have a decently modern non-macOS device, it probably supports this, but you might have to update your graphics drivers. If support is missing, the pack will fail to load.

## Configuration

All configurable options are located in [assets/smaa_lura/shaders/include/config.glsl](assets/smaa_lura/shaders/include/config.glsl) inside the resource pack,
and can be modified with a text editor. The changes are applied when the pack is reloaded.

## License

*See [LICENSE.txt](LICENSE.txt) and each individual file.*

The resource pack contains some files licensed "All rights reserved unless explicitly stated." and some under more permissive licenses (the ones deemed more likely useful for inclusion in other projects). This is to prevent unmodified or barely modified copies of the pack from being distributed without permission. Please contact me if you want to use the files for anything not permitted by the licenses.
