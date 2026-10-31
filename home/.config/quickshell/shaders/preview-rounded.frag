#version 440
layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;
layout(std140,binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 boxSize;
    float cornerRadius;
    float lineWidth;
    vec4 fillInk;
    vec4 rimInk;
};
layout(binding=1) uniform sampler2D source;
void main(){
    vec2 halfSize=boxSize*.5;
    float r=clamp(cornerRadius,0.,min(halfSize.x,halfSize.y));
    vec2 q=abs(qt_TexCoord0*boxSize-halfSize)-(halfSize-vec2(r));
    float d=length(max(q,vec2(0.)))+min(max(q.x,q.y),0.)-r;
    float aa=max(fwidth(d)*.5,.001);
    float cover=1.-smoothstep(-aa,aa,d);
    float inside=1.-smoothstep(-aa,aa,d+lineWidth);
    vec4 tex=texture(source,qt_TexCoord0);
    vec4 image=tex+fillInk*(1.-tex.a);
    fragColor=mix(rimInk,image,inside)*cover*qt_Opacity;
}
