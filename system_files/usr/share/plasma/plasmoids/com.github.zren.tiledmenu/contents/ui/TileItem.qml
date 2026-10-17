import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.core as PlasmaCore

Item {
	id: tileItem
	x: modelData.x * cellBoxSize
	y: modelData.y * cellBoxSize
	width: modelData.w * cellBoxSize
	height: modelData.h * cellBoxSize

	function fixCoordinateBindings() {
		x = Qt.binding(function(){ return modelData.x * cellBoxSize })
		y = Qt.binding(function(){ return modelData.y * cellBoxSize })
		z = 0
	}

	AppObject {
		id: appObj
		tile: modelData
	}
	readonly property alias app: appObj.app

	readonly property bool faded: tileGrid.editing || tileMouseArea.isLeftPressed
	readonly property int fadedWidth: width - cellPushedMargin
	opacity: faded ? 0.75 : 1
	scale: faded ? fadedWidth / width : 1
	Behavior on opacity { NumberAnimation { duration: 200 } }
	Behavior on scale { NumberAnimation { duration: 200 } }

	//--- View Start
	TileItemView {
		id: tileItemView
		anchors.fill: parent
		anchors.margins: cellMargin
		width: modelData.w * cellBoxSize
		height: modelData.h * cellBoxSize
		readonly property int minSize: Math.min(width, height)
		readonly property int maxSize: Math.max(width, height)
		hovered: tileMouseArea.containsMouse
	}

	HoverOutlineEffect {
		id: hoverOutlineEffect
		anchors.fill: parent
		anchors.margins: cellMargin
		hoverRadius: {
			if (appObj.isGroup) {
				return tileItemView.maxSize
			} else {
				return tileItemView.minSize
			}
		}
		hoverOutlineSize: tileGrid.hoverOutlineSize
		mouseArea: tileMouseArea
	}
	//--- View End

	MouseArea {
		id: tileMouseArea
		anchors.fill: parent
		hoverEnabled: true
		acceptedButtons: Qt.LeftButton | Qt.RightButton
		cursorShape: editing ? Qt.ClosedHandCursor : Qt.ArrowCursor
		readonly property bool isLeftPressed: pressedButtons & Qt.LeftButton

		property int pressX: -1
		property int pressY: -1
		onPressed: function(mouse) {
			pressX = mouse.x
			pressY = mouse.y
		}

		drag.target: plasmoid.configuration.tilesLocked ? undefined : tileItem
		// drag.onActiveChanged: console.log('drag.active', drag.active)

		// This MouseArea will spam "QQuickItem::ungrabMouse(): Item is not the mouse grabber."
		// but there's no other way of having a clickable drag area.
		onClicked: function(mouse) {
			mouse.accepted = true
			tileGrid.resetDrag()
			if (mouse.button == Qt.LeftButton) {
				if (tileEditorView && tileEditorView.tile) {
					openTileEditor()
				} else if (modelData.url) {
					appsModel.tileGridModel.runApp(modelData.url)
				}
			} else if (mouse.button == Qt.RightButton) {
				contextMenu.open(mouse.x, mouse.y)
			}
		}
	}

	Drag.dragType: Drag.Automatic
	Drag.proposedAction: Qt.MoveAction

	// We use this drag pattern to use the internal drag with events.
	// https://stackoverflow.com/a/24729837/947742
	readonly property bool dragActive: tileMouseArea.drag.active
	// Fennek OS: property-change handlers get no argument in Qt 6; a "dragActive" parameter was always undefined,
	// so a drag never started and every tile jumped back. The property itself is read instead.
	onDragActiveChanged: {
		if (dragActive) {
			// console.log("drag started")
			// console.log('onDragStarted', JSON.stringify(modelData), index, tileModel.length)
			tileGrid.startDrag(index)
			// tileGrid.dropOffsetX = 0
			// tileGrid.dropOffsetY = 0
			tileItem.z = 1
			Drag.start()
		} else {
			// console.log("drag finished")
			// console.log('DragArea.onDrop', draggedItem)
			Qt.callLater(tileGrid.resetDrag)
			Qt.callLater(tileItem.fixCoordinateBindings)
			Drag.drop() // Breaks QML context.
			// We need to use callLater to call functions after Drag.drop().
		}
	}

	QQC2.ToolTip {
		id: control
		visible: tileItemView.hovered && !(dragActive || contextMenu.opened) && appObj.tile.w == 1 && appObj.tile.h == 1
		text: appObj.labelText
		delay: 0
		x: parent.width + rightPadding
		y: (parent.height - height) / 2
	}

	Loader {
		id: groupEffectLoader
		visible: tileMouseArea.containsMouse
		active: appObj.isGroup && visible
		sourceComponent: Rectangle {
			id: groupOutline
			color: "transparent"
			border.width: Math.max(1, Math.round(1 * Screen.devicePixelRatio))
			border.color: "#33ffffff"   // Fennek OS: a faint rounded outline, not a hard square
			radius: 10
			y: modelData.h * cellBoxSize
			z: 100
			width: appObj.groupRect.w * cellBoxSize
			height: appObj.groupRect.h * cellBoxSize
		}
	}

	AppContextMenu {
		id: contextMenu
		tileIndex: index
		onPopulateMenu: function(menu) {
			if (!plasmoid.configuration.tilesLocked) {
				menu.addPinToMenuAction(modelData.url)
			}

			// Fennek OS: quick resize, like the classic Start menu (Small / Medium / Wide / Large).
			if (!plasmoid.configuration.tilesLocked && modelData.tileType != "group") {
				var resizeTitle = menu.newMenuItem()
				resizeTitle.text = i18n("Resize")
				resizeTitle.section = true
				menu.addMenuItem(resizeTitle)
				var sizes = [[i18n("Small"), 1, 1], [i18n("Medium"), 2, 2], [i18n("Wide"), 4, 2], [i18n("Large"), 4, 4]]
				sizes.forEach(function(size) {
					var sizeItem = menu.newMenuItem()
					sizeItem.text = size[0]
					sizeItem.checkable = true
					sizeItem.checked = modelData.w == size[1] && modelData.h == size[2]
					sizeItem.clicked.connect(function() {
						var tile = tileGrid.tileModel[index]
						tile.w = size[1]
						tile.h = size[2]
						tileGrid.tileModelChanged()
					})
					menu.addMenuItem(sizeItem)
				})
				menu.addMenuItem(menu.newSeperator())
			}

			appObj.addActionList(menu)

			// Fennek OS: like the classic Start menu, show the app's shortcut in Files.
			if (/^[A-Za-z0-9_-][A-Za-z0-9._-]*\.desktop$/.test(modelData.url)) {
				var locationItem = menu.newMenuItem()
				locationItem.text = i18n("Open file location")
				locationItem.icon = "folder-open"
				locationItem.clicked.connect(function() {
					widget.run("/usr/libexec/fennek-open-location " + modelData.url)
				})
				menu.addMenuItem(locationItem)
			}

			if (!plasmoid.configuration.tilesLocked) {
				if (modelData.tileType == "group") {
					var menuItem = menu.newMenuItem()
					menuItem.text = i18n("Sort Tiles")
					menuItem.icon = 'sort-name'
					menuItem.onClicked.connect(function(){
						tileGrid.sortGroupTiles(modelData)
					})
				}
				var menuItem = menu.newMenuItem()
				menuItem.text = i18n("Edit Tile")
				menuItem.icon = 'rectangle-shape'
				menuItem.onClicked.connect(function(){
					tileItem.openTileEditor()
				})
			}
		}
	}

	function openTileEditor() {
		tileGrid.editTile(tileGrid.tileModel[index])
	}
	function closeTileEditor() {

	}
}
