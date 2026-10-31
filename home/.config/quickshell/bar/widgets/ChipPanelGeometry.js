// Shared corner geometry; coordinates are physical logical-screen pixels.
.pragma library
function geometry(side,source,desired,viewport,progress,gap){
 var left=side==="left",edge=left?source.x+source.width:source.x;
 var available=Math.max(source.width,left?edge-gap:viewport.width-gap-edge);
 var targetWidth=Math.max(source.width,Math.min(desired.width,available));
 var top=Math.max(gap,Math.min(source.y,viewport.height-gap-source.height));
 var targetHeight=Math.max(source.height,Math.min(desired.height,viewport.height-gap-top));
 var width=source.width+(targetWidth-source.width)*progress;
 var height=source.height+(targetHeight-source.height)*progress;
 return {x:left?edge-width:edge,y:top,width:width,height:height,targetWidth:targetWidth,targetHeight:targetHeight,edge:edge};
}
