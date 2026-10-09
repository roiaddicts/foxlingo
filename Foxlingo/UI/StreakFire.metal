#include <metal_stdlib>
using namespace metal;

// Advected value noise: each frame samples a new part of the field rather than
// replaying a sequence of silhouettes.
float fireHash(float2 p) { return fract(sin(dot(p,float2(127.1,311.7)))*43758.5453); }
float fireNoise(float2 p) {
    float2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(fireHash(i),fireHash(i+float2(1,0)),f.x),
               mix(fireHash(i+float2(0,1)),fireHash(i+1.0),f.x),f.y);
}
float fireField(float2 p) {
    float value=0.0, amplitude=0.5;
    for (int i=0;i<4;i++) {value+=amplitude*fireNoise(p);p=p*2.03+float2(7.1,3.7);amplitude*=0.5;}
    return value;
}
[[ stitchable ]] half4 streakFire(float2 position, half4 color, float2 size, float time, float intensity) {
    float2 uv=position/size;
    float y=1.0-uv.y;
    float height=0.64+0.29*intensity;
    float speed=1.3+intensity;
    float noise=fireField(float2(uv.x*5.0,y*5.5-time*speed));
    float curl=(fireNoise(float2(y*4.0,time*0.7))-0.5)*(0.06+y*0.24);
    float rise=y+(noise-0.5)*0.22*y;
    float x=uv.x-0.5+curl;
    float base=smoothstep(0.0,0.16,y);
    float central=0.24*pow(max(0.0,1.0-rise/height),0.7)*base-abs(x);
    float left=0.13*pow(max(0.0,1.0-rise/(height*0.76)),0.8)*base-abs(x+0.17);
    float right=0.12*pow(max(0.0,1.0-rise/(height*0.63)),0.8)*base-abs(x-0.17);
    float edge=max(central,max(left,right))+(noise-0.48)*0.12*y;
    float alpha=smoothstep(-0.018,0.018,edge)*smoothstep(0.0,0.06,y);
    float heat=clamp((edge*3.8+0.2+intensity*0.06)*(1.0-y*0.6)+noise*0.17,0.0,1.0);
    float3 rgb=mix(float3(1.0,0.15,0.015),float3(1.0,0.7,0.05),smoothstep(0.1,0.65,heat));
    rgb=mix(rgb,float3(1.0,0.96,0.66),smoothstep(0.55,0.95,heat));
    return half4(half3(rgb*alpha),half(alpha))*color.a;
}
