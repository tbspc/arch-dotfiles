#version 440
layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;
layout(std140,binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 fillInk;
    vec4 sheenInk;
    vec2 boxSize;
    float power;
    float mirrored;
    float sheenReach;
    float joinOverlap;
};
void main(){
    vec2 uv=qt_TexCoord0;
    if(mirrored>.5)uv.x=1.0-uv.x;
    float edgeX=uv.x*boxSize.x-joinOverlap;
    uv.x=edgeX/max(boxSize.x-joinOverlap,.001);
    vec2 q=clamp(vec2(1.0)-uv,vec2(0.0),vec2(1.0));
    float n=clamp(power,1.0,8.0);
    float v=pow(q.x,n)+pow(q.y,n)-1.0;
    float aa=max(fwidth(v)*.5,.00001);
    float cover=joinOverlap>0.0 && edgeX<=0.0?1.0:smoothstep(-aa,aa,v);
    float light=sheenReach>0.0?clamp(1.0-uv.y*boxSize.y/sheenReach,0.0,1.0):0.0;
    vec4 sheen=sheenInk*light;
    vec4 pixel=sheen+fillInk*(1.0-sheen.a);
    fragColor=pixel*cover*qt_Opacity;
}
