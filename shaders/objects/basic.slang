import aperture;
import lib.core;

extern static const bool FOG;

struct VertexOutput {
    float4 position : SV_Position;
    float2 uv;
    float4 color;
    float2 light;
    float distance;
};

[[shader("vertex")]]
VertexOutput vertexMain(Vertex input) {
    VertexOutput output;

    float3 modelPos = input.pos().xyz;

    output.position = proj_mmul(input.projectionMatrix(), rot_trans_mmul(input.viewMatrix(), modelPos));
    output.uv = input.uv();
    output.color = input.color() * input.ao();
    output.light = input.light();
    output.distance = length(modelPos);

    if (let overlayColor = input.overlayColor()) {
        output.color = lerp(output.color, overlayColor, overlayColor.a);
    }

    return output;
}

[[shader("fragment")]]
float4 fragmentMain(VertexOutput input) : SV_Target0 {
    float4 color = albedoTex.Sample(input.uv) * input.color;

    color.rgb *= lightmap.Sample(input.light).rgb;

    iris_discardIfNeeded(color);

    if (FOG) {
        float mixValue = (input.distance - ap.world.fogStart) / (ap.world.fogEnd - ap.world.fogStart);

        float renderDistanceFogStart = clamp(ap.world.renderDistance / 10.0, 4.0, 64.0);
        mixValue = max(mixValue, (input.distance - renderDistanceFogStart) / (ap.world.renderDistance - renderDistanceFogStart));

        color = lerp(color, ap.world.fogColor, clamp(mixValue, 0.0, 1.0));
    }

    return color;
}
