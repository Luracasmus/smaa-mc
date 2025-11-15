import aperture;

[format("rgb10a2")]
Sampler2D color0Tex;

[[shader("fragment")]]
float4 main(float2 pos : SV_Position) : SV_Target0 {
    return color0Tex[int2(pos)];
}
