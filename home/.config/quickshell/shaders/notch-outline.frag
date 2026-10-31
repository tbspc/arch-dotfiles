#version 440
layout(location=0) in vec2 qt_TexCoord0;
layout(location=0) out vec4 fragColor;
layout(std140,binding=0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 ink;
    vec2 boxSize;
    vec4 bounds;
    float corner;
    float lowerPower;
    float upperPower;
    float inset;
};
float powerDistance(vec2 q,float r,float n){
    vec2 v=max(q/max(r,.001),vec2(0.0));
    float lp=pow(pow(v.x,n)+pow(v.y,n),1.0/n);
    vec2 grad=pow(v,vec2(max(0.0,n-1.0)))/pow(max(lp,.001),max(0.0,n-1.0));
    return (lp-1.0)*r/max(length(grad),.001);
}
void main(){
    vec2 p=qt_TexCoord0*boxSize;
    float L=bounds.x,R=bounds.y,H=bounds.z,f=bounds.w,r=corner;
    float d=max(max(L-p.x,p.x-R),p.y-H);
    if(f>0.0 && p.y<f){
        if(p.x<(L+R)*.5)d=max(p.y-H,-powerDistance(vec2(p.x-(L-f),f-p.y),f,upperPower));
        else d=max(p.y-H,-powerDistance(vec2(R+f-p.x,f-p.y),f,upperPower));
    }
    if(r>0.0 && p.y>H-r){
        if(p.x<L+r)d=powerDistance(vec2(L+r-p.x,p.y-(H-r)),r,lowerPower);
        else if(p.x>R-r)d=powerDistance(vec2(p.x-(R-r),p.y-(H-r)),r,lowerPower);
    }
    float line=abs(d+inset+.5);
    float aa=max(fwidth(d)*.5,.001);
    float alpha=1.0-smoothstep(.5-aa,.5+aa,line);
    fragColor=ink*alpha*qt_Opacity;
}
