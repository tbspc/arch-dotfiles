#version 440
layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;
layout(std140,binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 ink;
    float charge;
};
layout(binding=1) uniform sampler2D referenceImage;
void main(){
    vec2 p=qt_TexCoord0*vec2(43.0,26.0);
    // Reference has a partly depleted body. Undo that column shading to get
    // its complete silhouette, then apply the real live battery charge.
    float referenceLevel=mix(1.0,0.86,smoothstep(22.5,23.5,p.x));
    referenceLevel=mix(referenceLevel,0.235,smoothstep(23.5,24.5,p.x));
    float sampleLevel=texture(referenceImage,qt_TexCoord0).b*(255.0/194.0);
    float body=clamp(sampleLevel/referenceLevel,0.0,1.0);
    float aa=max(fwidth(p.x)*0.5,0.001);
    float fill=1.0-smoothstep(3.5+26.0*clamp(charge,0.0,1.0)-aa,3.5+26.0*clamp(charge,0.0,1.0)+aa,p.x);
    float level=p.x<29.5?body*mix(0.235,1.0,fill):sampleLevel;
    float a=clamp(level,0.0,1.0)*ink.a*qt_Opacity;
    fragColor=vec4(ink.rgb*a,a);
}
