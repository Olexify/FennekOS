import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

QQC2.ToolButton {
	id: flatButton

	icon.name: ""
	// Fennek OS: colours from the panel theme, not the app colour scheme (dark Start + light apps would
	// otherwise draw dark icons, e.g. Power, on the dark menu).
	icon.color: config.menuTextColor
	property bool expanded: true
	text: ""
	display: expanded ? QQC2.AbstractButton.TextBesideIcon : QQC2.AbstractButton.IconOnly
	property string label: expanded ? text : ""
	property bool labelVisible: text != ""
	property color backgroundColor: config.flatButtonBgColor
	property color backgroundHoverColor: config.flatButtonBgHoverColor
	property color backgroundPressedColor: config.flatButtonBgPressedColor
	property color checkedColor: config.flatButtonCheckedColor
	property bool zoomOnPush: true

	// http://doc.qt.io/qt-5/qt.html#Edge-enum
	property int checkedEdge: 0 // 0 = all edges
	property int checkedEdgeWidth: 2 * Screen.devicePixelRatio

	property int buttonHeight: config.flatButtonSize
	property int iconSize: config.flatButtonIconSize
	readonly property int _iconSize: Math.min(buttonHeight, iconSize)
	implicitHeight: buttonHeight

	// Fennek OS: draw icon and label ourselves in the panel theme's text colour (the desktop button style
	// tinted symbolic icons, e.g. Power, with the light app scheme's dark text: invisible on the dark menu).
	contentItem: RowLayout {
		spacing: Kirigami.Units.largeSpacing
		Kirigami.Icon {
			source: flatButton.icon.name || flatButton.icon.source
			// Monochrome icons drawn in the menu's own text colour (Plasma would tint them from the app colour scheme,
			// which can differ from the menu's: dark symbols on a dark menu).
			isMask: String(source).indexOf("-symbolic") >= 0
			color: isMask ? config.menuTextColor : "transparent"
			Layout.preferredWidth: flatButton._iconSize
			Layout.preferredHeight: flatButton._iconSize
			Layout.alignment: flatButton.display === QQC2.AbstractButton.IconOnly ? Qt.AlignCenter : Qt.AlignVCenter
		}
		PlasmaComponents3.Label {
			visible: flatButton.display !== QQC2.AbstractButton.IconOnly && flatButton.text !== ""
			text: flatButton.text
			color: config.menuTextColor
			elide: Text.ElideRight
			Layout.fillWidth: true
		}
	}

	// contentItem: RowLayout {
	// 	id: labelRowLayout
	// 	// spacing: Kirigami.Units.smallSpacing
	// 	spacing: 0
	// 	scale: control.zoomOnPush && control.pressed ? (height-5) / height : 1
	// 	Behavior on scale { NumberAnimation { duration: 200 } }

	// 	Item {
	// 		id: iconContainer
	// 		Layout.fillHeight: true
	// 		implicitWidth: height
	// 		visible: !!icon.source

	// 		Kirigami.Icon {
	// 			id: icon
	// 			source: control.icon.name
	// 			implicitWidth: control._iconSize
	// 			implicitHeight: control._iconSize
	// 			anchors.centerIn: parent
	// 			// colorGroup: Kirigami.Theme.Button
	// 		}

	// 		// Rectangle { border.color: "#f00"; anchors.fill: parent; border.width: 1; color: "transparent"; }
	// 	}

	// 	Item {
	// 		id: spacingItem
	// 		Layout.fillHeight: true
	// 		implicitWidth: 4 * Screen.devicePixelRatio
	// 		visible: control.labelVisible

	// 		// Rectangle { border.color: "#f00"; anchors.fill: parent; border.width: 1; color: "transparent"; }
	// 	}

	// 	PlasmaComponents3.Label {
	// 		id: label
	// 		text: QtQuickControlsPrivate.StyleHelpers.stylizeMnemonics(control.text)
	// 		font: control.font || Kirigami.Theme.defaultFont
	// 		visible: control.labelVisible
	// 		horizontalAlignment: Text.AlignLeft
	// 		verticalAlignment: Text.AlignVCenter
	// 		Layout.fillWidth: true

	// 		// Rectangle { border.color: "#f00"; anchors.fill: parent; border.width: 1; color: "transparent"; }
	// 	}

	// 	Item {
	// 		id: rightPaddingItem
	// 		Layout.fillHeight: true
	// 		property int iconMargin: (iconContainer.width - icon.width)/2
	// 		property int iconPadding: icon.width * (16-12)/16
	// 		implicitWidth: iconMargin + iconPadding
	// 		visible: control.labelVisible

	// 		// Rectangle { border.color: "#f00"; anchors.fill: parent; border.width: 1; color: "transparent"; }
	// 	}
	// }

	// background: Item {
	// 	Rectangle {
	// 		id: background
	// 		anchors.fill: parent
	// 		color: flatButton.backgroundColor
	// 	}

	// 	Rectangle {
	// 		id: checkedOutline
	// 		color: flatButton.checkedColor
	// 		visible: control.checked
	// 		anchors.left: parent.left
	// 		anchors.top: parent.top
	// 		anchors.right: parent.right
	// 		anchors.bottom: parent.bottom

	// 		states: [
	// 			State {
	// 				when: control.checkedEdge === 0
	// 				PropertyChanges {
	// 					target: checkedOutline
	// 					anchors.fill: checkedOutline.parent
	// 					color: "transparent"
	// 					border.color: flatButton.checkedColor
	// 				}
	// 			},
	// 			State {
	// 				when: control.checkedEdge == Qt.TopEdge
	// 				PropertyChanges {
	// 					target: checkedOutline
	// 					anchors.bottom: undefined
	// 					height: control.checkedEdgeWidth
	// 				}
	// 			},
	// 			State {
	// 				when: control.checkedEdge == Qt.LeftEdge
	// 				PropertyChanges {
	// 					target: checkedOutline
	// 					anchors.right: undefined
	// 					width: control.checkedEdgeWidth
	// 				}
	// 			},
	// 			State {
	// 				when: control.checkedEdge == Qt.RightEdge
	// 				PropertyChanges {
	// 					target: checkedOutline
	// 					anchors.left: undefined
	// 					width: control.checkedEdgeWidth
	// 				}
	// 			},
	// 			State {
	// 				when: control.checkedEdge == Qt.BottomEdge
	// 				PropertyChanges {
	// 					target: checkedOutline
	// 					anchors.top: undefined
	// 					height: control.checkedEdgeWidth
	// 				}
	// 			}
	// 		]
	// 	}

	// 	states: [
	// 		State {
	// 			name: "hovering"
	// 			when: !control.pressed && control.hovered
	// 			PropertyChanges {
	// 				target: background
	// 				color: flatButton.backgroundHoverColor
	// 			}
	// 		},
	// 		State {
	// 			name: "pressed"
	// 			when: control.pressed
	// 			PropertyChanges {
	// 				target: background
	// 				color: flatButton.backgroundPressedColor
	// 			}
	// 		}
	// 	]

	// 	transitions: [
	// 		Transition {
	// 			to: "hovering"
	// 			ColorAnimation { duration: 200 }
	// 		},
	// 		Transition {
	// 			to: "pressed"
	// 			ColorAnimation { duration: 100 }
	// 		}
	// 	]
	// }
}
