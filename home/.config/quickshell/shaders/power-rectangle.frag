#version 440
layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;
layout(std140,binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 fillInk;
    vec4 strokeInk;
    vec2 boxSize;
    vec4 radii;
    float power;
    float strokeWidth;
};
void main(){
    vec2 p=qt_TexCoord0*boxSize;
    bool right=p.x>boxSize.x*.5;
    bool bottom=p.y>boxSize.y*.5;
    float r=bottom?(right?radii.z:radii.w):(right?radii.y:radii.x);
    r=clamp(r,0.0,min(boxSize.x,boxSize.y)*.5);
    vec2 q=abs(p-boxSize*.5)-boxSize*.5+vec2(r);
    float d=max(q.x,q.y)-r;
    if(q.x>0.0&&q.y>0.0&&r>0.0){
        vec2 v=q/max(r,.001);
        float lp=pow(pow(v.x,power)+pow(v.y,power),1.0/power);
        vec2 grad=pow(v,vec2(max(0.0,power-1.0)))/pow(max(lp,.001),max(0.0,power-1.0));
        d=(lp-1.0)*r/max(length(grad),.001);
    }
    float aa=max(fwidth(d)*.5,.001);
    float outside=1.0-smoothstep(-aa,aa,d);
    float inside=1.0-smoothstep(-aa,aa,d+max(strokeWidth,0.0));
    vec4 pixel=fillInk*inside+strokeInk*max(0.0,outside-inside);
    fragColor=pixel*qt_Opacity;
}
