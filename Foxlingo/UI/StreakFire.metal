#include <metal_stdlib>
using namespace metal;

struct FlameUniforms {
    float4 motion;     // time, streak intensity, seed, particle count
    float4 shape;      // speed, lifetime, height, base width
    float4 appearance; // particle size, turbulence, brightness, core heat
    float4 rectangle;  // normalized destination rectangle
    float4 evolution;  // growth, optical vertical alignment, color history count, reserved
};

float flameRandom(float seed) {
    // Integer mixing avoids sine-hash precision artifacts with large seeds.
    uint state = as_type<uint>(seed)*747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state)*277803737u;
    word = (word >> 22u) ^ word;
    return float(word & 0x00ffffffu)/16777216.0;
}
float flameNoise(float coordinate, float seed) {
    float cell = floor(coordinate);
    float f = fract(coordinate);
    return mix(flameRandom(cell + seed), flameRandom(cell + seed + 1), f*f*(3 - 2*f))*2 - 1;
}
float2 flameCorner(uint vertexID) {
    return float2(vertexID & 1, vertexID >> 1);
}
struct FlameParticle {
    float4 position [[position]];
    float2 local;
    float opacity;
    float3 color;
};

// One instanced quad per particle: trajectories and splats are entirely GPU work.
vertex FlameParticle streakParticleVertex(uint vertexID [[vertex_id]], uint instance [[instance_id]],
                                         constant FlameUniforms &u [[buffer(0)]],
                                         constant float2 *history [[buffer(1)]]) {
    float slot = float(instance) + u.motion.z;
    float lifetime = (1.05 + flameRandom(slot + 19)*0.8)*u.shape.y;
    float clock = u.motion.x*u.shape.x/lifetime + flameRandom(slot + 47);
    float age = fract(clock);
    float seed = slot*17 + floor(clock)*251;
    float spread = (flameRandom(seed + 1) + flameRandom(seed + 2) - 1)*u.shape.w;
    float bowl = sqrt(max(0.0, 1 - pow(spread/u.shape.w, 2.0)));
    float originY = 0.80 + bowl*0.095 + flameRandom(seed + 3)*0.018;
    float rise = (0.47 + flameRandom(seed + 4)*0.29)*pow(age, 1.15)*u.shape.z;
    float wind = flameNoise(u.motion.x*1.7 - rise*3, 71);
    float eddy = flameNoise(u.motion.x*3.4 - age*4, floor(spread*8) + 113);
    float curl = (wind*0.13 + eddy*0.055)*u.appearance.y;
    float2 center = float2(0.5 + spread*pow(1 - age, 0.7) + curl*pow(age, 1.2), originY - rise);
    float radius = (0.048 + flameRandom(seed + 5)*0.035)*(1 - age*0.68)*u.appearance.x;
    float2 local = flameCorner(vertexID)*2 - 1;
    // Match the original elliptical particles in the 34:42 badge aspect ratio.
    float2 p = center + local*float2(radius, radius*1.2*34.0/42.0);
    FlameParticle result;
    result.position = float4(p.x*2 - 1, 1 - p.y*2, 0, 1);
    result.local = local;
    float birth = u.motion.x - age*lifetime/max(0.01, u.shape.x);
    float stage = history[0].y;
    for (uint event = 1; event < uint(u.evolution.z); ++event) {
        if (history[event].x <= birth) stage = history[event].y;
    }
    if (stage < 0.5) result.color = float3(1, 0.18, 0.015);
    else if (stage < 1.5) result.color = float3(0.035, 1, 0.12);
    else if (stage < 2.5) result.color = float3(0.04, 0.32, 1);
    else {
        // Hue belongs to birth time, so a particle keeps it throughout its life.
        float hue = fract(birth/8.0);
        result.color = clamp(abs(fract(hue + float3(0, 2.0/3.0, 1.0/3.0))*6 - 3) - 1, 0.0, 1.0);
    }
    result.opacity = min(1.0, age/0.09)*min(1.0, (1 - age)/0.28)*(0.65 + flameRandom(seed + 6)*0.25);
    return result;
}
fragment float4 streakParticleDensity(FlameParticle particle [[stage_in]]) {
    float falloff = max(0.0, 1 - dot(particle.local, particle.local));
    float density = particle.opacity*falloff*falloff;
    return float4(particle.color*density, density);
}

struct FlameOutput {
    float4 position [[position]];
    float2 uv;
};
vertex FlameOutput streakFlameVertex(uint vertexID [[vertex_id]], constant FlameUniforms &u [[buffer(0)]]) {
    float2 uv = flameCorner(vertexID);
    float2 p = u.rectangle.xy + uv*u.rectangle.zw;
    FlameOutput result;
    result.position = float4(p.x*2 - 1, 1 - p.y*2, 0, 1);
    result.uv = uv;
    return result;
}
fragment half4 streakFlameLight(FlameOutput in [[stage_in]], constant FlameUniforms &u [[buffer(0)]],
                               texture2d<float> density [[texture(0)]]) {
    constexpr sampler linearSampler(filter::linear, address::clamp_to_edge);
    float2 uv = in.uv - float2(0, u.evolution.y);
    if (any(uv < 0.0) || any(uv > 1.0)) return half4(0);
    float4 accumulation = density.sample(linearSampler, uv);
    float heat = accumulation.a*u.appearance.z*mix(1.25, 1.0, u.evolution.x);
    float alpha = 1 - exp(-heat*1.8);
    float yellow = 1 - exp(-heat*0.42);
    float white = 1 - exp(-max(0.0, heat - 2)*0.22*u.appearance.w);
    float3 base = accumulation.rgb/max(0.0001, accumulation.a);
    // Accumulated particles make a luminous core while edges retain their hue.
    float3 color = mix(base, float3(1), white*0.8);
    color.g = mix(base.g, 1.0, max(white*0.8, yellow*0.80));
    return half4(half3(color*alpha), half(alpha));
}
