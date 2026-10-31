#version 440
layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;
layout(std140,binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float gain;
    float maskEnabled;
    vec4 shadowInk;
    float falloffPower;
};
layout(binding=1) uniform sampler2D source;
layout(binding=2) uniform sampler2D maskSource;
void main(){
    float a=clamp(pow(clamp(texture(source,qt_TexCoord0).a,0.0,1.0),max(.1,falloffPower))*gain,0.0,1.0);
    if(maskEnabled>.5)a*=1.0-clamp(texture(maskSource,qt_TexCoord0).a,0.0,1.0);
    fragColor=vec4(shadowInk.rgb*a,a)*qt_Opacity;
}
