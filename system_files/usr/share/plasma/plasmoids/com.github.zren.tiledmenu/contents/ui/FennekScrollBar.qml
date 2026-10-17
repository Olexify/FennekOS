import QtQuick
import QtQuick.Controls as QQC2

// Fennek OS: a thin scrollbar line, shown only while scrolling or under the pointer (no groove, no arrows).
QQC2.ScrollBar {
	id: bar
	hoverEnabled: true
	padding: 2
	minimumSize: 0.08
	implicitWidth: orientation == Qt.Vertical ? (hovered || pressed ? 10 : 7) : 0
	implicitHeight: orientation == Qt.Horizontal ? (hovered || pressed ? 10 : 7) : 0
	Behavior on implicitWidth { NumberAnimation { duration: 120 } }
	background: null
	contentItem: Rectangle {
		radius: Math.min(width, height) / 2
		color: "#f0eef5"   // light on the dark Start (see FlatButton)
		opacity: bar.pressed ? 0.6 : bar.hovered ? 0.45 : bar.active ? 0.3 : 0
		Behavior on opacity { NumberAnimation { duration: 250 } }
	}
}
