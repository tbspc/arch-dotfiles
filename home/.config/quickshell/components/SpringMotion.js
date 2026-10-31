.pragma library
function step(seconds,damping,frequency) {
    if(seconds<=0)return 0
    const z=Math.max(.15,Math.min(.99,damping/100)),w=Math.max(1,frequency),q=Math.sqrt(1-z*z)
    return 1-Math.exp(-z*w*seconds)*(Math.cos(w*q*seconds)+z/q*Math.sin(w*q*seconds))
}
function velocity(seconds,damping,frequency) {
    const z=Math.max(.15,Math.min(.99,damping/100)),w=Math.max(1,frequency),q=Math.sqrt(1-z*z)
    return w/q*Math.exp(-z*w*seconds)*Math.sin(w*q*seconds)
}
function sample(seconds,durationMs,damping,frequency) {
    const total=Math.max(.001,durationMs/1000)
    if(seconds<=0)return 0
    if(seconds>=total)return 1
    return step(seconds,damping,frequency)/Math.max(.001,step(total,damping,frequency))
}
function delayed(seconds,delayMs,durationMs,damping,frequency) {
    const total=Math.max(.001,durationMs/1000),delay=Math.min(total*.7,Math.max(0,delayMs/1000))
    return sample((seconds-delay)*total/(total-delay),durationMs,damping,frequency)
}
// Eight Hermite segments retain the measured spring while avoiding long-spline
// corruption in the installed Qt easing implementation.
function curve(durationMs,damping,frequency) {
    const total=Math.max(.001,durationMs/1000),normal=Math.max(.001,step(total,damping,frequency)),values=[],count=8
    for(let i=0;i<count;i++) {
        const a=i/count,b=(i+1)/count,dx=b-a
        const ya=i===0?0:step(a*total,damping,frequency)/normal
        const yb=i===count-1?1:step(b*total,damping,frequency)/normal
        const da=i===0?0:velocity(a*total,damping,frequency)*total/normal
        const db=i===count-1?0:velocity(b*total,damping,frequency)*total/normal
        values.push(a+dx/3,ya+da*dx/3,b-dx/3,yb-db*dx/3,b,yb)
    }
    return values
}
