import QtQuick
import QtQuick.Controls

import org.qfield
import org.qgis
import Theme

import "qrc:/qml" as QFieldItems

Item {
  id: plugin

  property var mainWindow: iface.mainWindow()
  property var mapCanvas: iface.findItemByObjectName('mapCanvas')
  property var overlayFeatureFormDrawer: iface.findItemByObjectName('overlayFeatureFormDrawer')
  property var locatorItem: iface.mainWindow().contentItem.children[4].children[9]
  property var searchFieldRect: iface.mainWindow().contentItem.children[4].children[9].children[0]
  property var resultBox: iface.mainWindow().contentItem.children[4].children[9].children[5]

  Component.onCompleted: {
    locatorAddressItem.parent = locatorItem
    mapCanvas.children.forEach(item => {
  })
}

QFieldItems.GeometryHighlighter {
  id: resultRenderer
  parent: mapCanvas
  geometryWrapper.crs: mapCanvas.mapSettings.destinationCrs
}

Rectangle {
  id: locatorAddressItem
  z: 1
  width: searchFieldRect.width - 24
  height: searchFieldRect.visible ? 30+32 : 0
  anchors.top: resultBox.bottom
  anchors.left: searchFieldRect.left
  anchors.topMargin: resultBox.height == 0 ? 24 : 0
  color: Theme.mainBackgroundColor
  visible: searchFieldRect.visible && searchFieldRect.children[0].displayText !== ''
  clip: true

  Rectangle {
    id:rectTitle
    height:30
    width:parent.width
    anchors.top:parent.top
    color: Theme.mainColor
    opacity: 0.95

    Text {
      id: nameCell
      anchors.left: parent.left
      anchors.right: parent.right
      text: 'Search for location address'
      leftPadding: 5
      topPadding: 8
      font.bold: false
      font.pointSize: Theme.resultFont.pointSize
      color: "white"
      elide: Text.ElideRight
      horizontalAlignment: Text.AlignLeft
    }
  }
  Rectangle {
    anchors.left: parent.left
    anchors.top: rectTitle.bottom
    height:32
    width:parent.width
    color: Theme.mainBackgroundColor

    Text {
      id: addressCell
      anchors.left: parent.left
      anchors.right: parent.right
      text: 'Got to '+ searchFieldRect.children[0].displayText + ' location'
      leftPadding: 5
      topPadding: 8
      font.bold: false
      font.pointSize: Theme.resultFont.pointSize
      color: Theme.mainTextColor
    }
  }

  MouseArea {
    id: mouseArea
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right

    onClicked: {
      fetchGeocoder(searchFieldRect.children[0].displayText)
    }
  }
}

function fetchGeocoder(location)
{
  let request = new XMLHttpRequest();

  request.onreadystatechange = function() {
  if (request.readyState === XMLHttpRequest.DONE)
  {
    var responseObject = JSON.parse(request.response)
    for (const obj of responseObject) {
      var displayPoint = GeometryUtils.reprojectPoint(GeometryUtils.point(obj.lon, obj.lat), CoordinateReferenceSystemUtils.wgs84Crs(), mapCanvas.mapSettings.destinationCrs);
      var temp = [GeometryUtils.reprojectPoint(GeometryUtils.point(obj.boundingbox[2], obj.boundingbox[0]), CoordinateReferenceSystemUtils.wgs84Crs(), mapCanvas.mapSettings.destinationCrs),
      GeometryUtils.reprojectPoint(GeometryUtils.point(obj.boundingbox[3], obj.boundingbox[1]), CoordinateReferenceSystemUtils.wgs84Crs(), mapCanvas.mapSettings.destinationCrs)
    ]
    mapCanvas.mapSettings.setExtentFromPoints(temp, 125, true)
    locatorItem.state = 'off'

    if (obj.geojson && obj.geojson.type == 'Polygon')
    {
      let str = 'POLYGON (('
      for (const coord of obj.geojson.coordinates[0]) {
        var point = GeometryUtils.reprojectPoint(GeometryUtils.point(coord[0], coord[1]), CoordinateReferenceSystemUtils.wgs84Crs(), mapCanvas.mapSettings.destinationCrs);
        str += point.x +' ' + point.y + ', '
      }
      str = str.substring(0, str.length - 2)
      str += '))'
      let geom = GeometryUtils.createGeometryFromWkt(str)
      resultRenderer.geometryWrapper.qgsGeometry = geom
      resultRenderer.geometryWrapper.crs = mapCanvas.mapSettings.destinationCrs
    } else {
    let str = 'POINT (' + displayPoint.x + ' ' + displayPoint.y+')'
    let geom = GeometryUtils.createGeometryFromWkt(str)
    resultRenderer.geometryWrapper.qgsGeometry = geom
    resultRenderer.geometryWrapper.crs = mapCanvas.mapSettings.destinationCrs
  }
  mainWindow.displayToast(obj.display_name)
  break

}

}
}
request.open("GET", "https://nominatim.openstreetmap.org/search.php?q="+location+"&polygon_geojson=1&format=jsonv2")
request.setRequestHeader('User-Agent', 'FAKE-USER-AGENT');
request.send();
}
}
