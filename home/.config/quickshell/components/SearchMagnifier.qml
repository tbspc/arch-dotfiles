import QtQuick
import QtQuick.Shapes
Item {
    id:root
    property color ink:"#8e8b7d"
    implicitWidth:16;implicitHeight:16
    Shape {
        width:16;height:16;scale:root.width/16;transformOrigin:Item.TopLeft
        preferredRendererType:Shape.CurveRenderer
        ShapePath{strokeWidth:1.3;strokeColor:root.ink;fillColor:"transparent";capStyle:ShapePath.RoundCap
            startX:11;startY:11;PathLine{x:14.2;y:14.2}
        }
        ShapePath{strokeWidth:1.3;strokeColor:root.ink;fillColor:"transparent"
            PathAngleArc{centerX:6.6;centerY:6.6;radiusX:4.8;radiusY:4.8;startAngle:0;sweepAngle:360}
        }
    }
}
