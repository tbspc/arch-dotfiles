#version 440
layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;
layout(std140,binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 ink;
    float charge;
};
float roundedBox(vec2 p,vec2 centre,vec2 halfSize,float radius){
    vec2 q=abs(p-centre)-halfSize+vec2(radius);
    return length(max(q,0.0))+min(max(q.x,q.y),0.0)-radius;
}
float coverage(float distance){
    float aa=max(fwidth(distance)*0.5,0.001);
    return 1.0-smoothstep(-aa,aa,distance);
}
void main(){
    vec2 p=qt_TexCoord0*vec2(43.0,26.0);
    // An analytic capsule: curves and AA are evaluated at the final rendered size.
    float body=coverage(roundedBox(p,vec2(16.5,12.5),vec2(13.0,6.5),4.0));
    float cap=coverage(roundedBox(p,vec2(31.0,12.5),vec2(1.0,3.0),1.0));
    float cut=3.5+26.0*clamp(charge,0.0,1.0);
    float aa=max(fwidth(p.x)*0.5,0.001);
    float fill=1.0-smoothstep(cut-aa,cut+aa,p.x);
    float a=clamp(body*mix(0.18,1.0,fill)+cap*0.32,0.0,1.0)*ink.a*qt_Opacity;
    fragColor=vec4(ink.rgb*a,a);
}
