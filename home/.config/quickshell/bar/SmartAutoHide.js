.pragma library

// All coordinates are Hyprland logical desktop coordinates. The area stays
// fixed at the resting bar size, so hiding the bar never changes this test.
function overlaps(client, area, workspace, monitor) {
    if(!client || client.mapped===false || client.hidden===true)return false;
    if(client.monitor!==undefined && client.monitor!==monitor)return false;
    if(!client.pinned && client.workspace?.id!==workspace)return false;
    if((client.fullscreen||0)>0)return true;
    const at=client.at||[], size=client.size||[];
    if(at.length<2 || size.length<2 || size[0]<=0 || size[1]<=0)return false;
    return at[0]<area.x+area.width && at[0]+size[0]>area.x
        && at[1]<area.y+area.height && at[1]+size[1]>area.y;
}
