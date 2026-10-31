#version 440
layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;
layout(std140,binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 ink;
    float charge;
    float fillOpacity;
    float emptyOpacity;
    float tipOpacity;
};
layout(binding=1) uniform sampler2D bodyMask;
layout(binding=2) uniform sampler2D tipMask;
void main(){
    float x=qt_TexCoord0.x*43.0;
    // Alpha only: no RGB shading or old charge edge can leak into the body.
    float body=texture(bodyMask,qt_TexCoord0).a;
    float tip=texture(tipMask,qt_TexCoord0).a;
    float aa=max(fwidth(x)*.5,.001);
    float edge=3.5+26.0*clamp(charge,0.0,1.0);
    float fill=1.0-smoothstep(edge-aa,edge+aa,x);
    float alpha=clamp(body*mix(emptyOpacity,fillOpacity,fill)+tip*tipOpacity,0.0,1.0)*ink.a*qt_Opacity;
    fragColor=vec4(ink.rgb*alpha,alpha);
}
