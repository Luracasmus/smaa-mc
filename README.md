A **Vanilla shader resource pack** implementing anti-aliasing and sharpening using the end-of-frame post effect added in Minecraft 26.3 Snapshot 3. The technique is a modified [Enhanced Subpixel Morphological Antialiasing 1x](https://www.iryoku.com/smaa/) followed by a modified [FidelityFX Contrast Adaptive Sharpening 1.2](https://gpuopen.com/fidelityfx-cas/).

**The shaders require graphics drivers with support for GLSL 4.40**. If you have a decently modern non-macOS device, it probably supports this, but you might have to update your graphics drivers. If support is missing, the pack will fail to load.

When Minecraft is using the Vulkan graphics API, the shaders may use lower precision math to improve performance. The behavior of this feature depends on your GPU and graphics drivers. Try switching graphics API if you're experiencing issues with the shaders, and please report them on [the issue tracker](https://github.com/Luracasmus/grindstone/issues).

## Configuration

All configurable options are located in [`assets/grindstone/shaders/include/config.glsl`](assets/grindstone/shaders/include/config.glsl) inside the resource pack,
and can be modified with a text editor. The changes are applied when the pack is reloaded.

## Older versions (named SMAA-MC)

Versions older than v2.0 are written as Iris shader packs rather than vanilla resource packs, and can be used with some Minecraft versions older than 26.3. They only implement SMAA 1x, with no sharpening, and re-implement vanilla-like rendering using code from [Base-460C](https://github.com/Luracasmus/Base-460C).

### Requirements for versions older than v2.0

> If you have a decently modern non-macOS device it probably supports everything you need, but you might have to update your Iris and graphics drivers

* **Iris** with support for features:
  * `COMPUTE_SHADERS`
  * `CUSTOM_IMAGES`
  * `ENTITY_TRANSLUCENT`
* **Graphics drivers** with support for **GLSL 4.60.8+**.
* **Minecraft** of a version that is listed as supported by the release.
