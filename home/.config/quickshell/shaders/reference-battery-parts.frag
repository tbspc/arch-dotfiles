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
layout(binding=1) uniform sampler2D referenceImage;
void main(){
    vec2 p=qt_TexCoord0*vec2(43.0,26.0);
    // The source includes an old charge boundary near its right edge.
    // Mirror its clean left half to recover the body without that baked seam.
    float cleanX=p.x>16.5?33.0-p.x:p.x;
    float body=clamp(texture(referenceImage,vec2(cleanX/43.0,qt_TexCoord0.y)).b*(255.0/194.0),0.0,1.0);
    float sampleLevel=texture(referenceImage,qt_TexCoord0).b*(255.0/194.0);
    float aa=max(fwidth(p.x)*0.5,0.001);
    float fill=1.0-smoothstep(3.5+26.0*clamp(charge,0.0,1.0)-aa,3.5+26.0*clamp(charge,0.0,1.0)+aa,p.x);
    float level=p.x<29.5?body*mix(emptyOpacity,fillOpacity,fill):sampleLevel/0.32*tipOpacity;
    float a=clamp(level,0.0,1.0)*ink.a*qt_Opacity;
    fragColor=vec4(ink.rgb*a,a);
}
