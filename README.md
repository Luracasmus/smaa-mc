A **Vanilla shader resource pack** implementing anti-aliasing and sharpening using the end-of-frame post effect added in Minecraft 26.3 Snapshot 3. The technique is a modified [Enhanced Subpixel Morphological Antialiasing 1x](https://www.iryoku.com/smaa/) followed by a modified [FidelityFX Contrast Adaptive Sharpening 1.2](https://gpuopen.com/fidelityfx-cas/).

**The shaders require graphics drivers with support for GLSL 4.40**. If you have a decently modern non-macOS device, it probably supports this, but you might have to update your graphics drivers. If support is missing, the pack will fail to load.

When Minecraft is using the Vulkan graphics API, the shaders may use lower precision math to improve performance. The behavior of this feature depends on your GPU and graphics drivers. Try switching graphics API if you're experiencing issues with the shaders, and please report them on [the issue tracker](https://github.com/Luracasmus/smaa-mc/issues).

## Configuration

All configurable options are located in [assets/grindstone/shaders/include/config.glsl](assets/grindstone/shaders/include/config.glsl) inside the resource pack,
and can be modified with a text editor. The changes are applied when the pack is reloaded.
