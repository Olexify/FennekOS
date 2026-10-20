import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
	id: tileItem
	x: modelData.x * cellBoxSize
	y: modelData.y * cellBoxSize
	width: modelData.w * cellBoxSize
	height: modelData.h * cellBoxSize
	z: appObj.isGroup ? 1 : 0   // a group's walls and corner grip stay on top of the tiles inside

	function fixCoordinateBindings() {
		x = Qt.binding(function(){ return modelData.x * cellBoxSize })
		y = Qt.binding(function(){ return modelData.y * cellBoxSize })
		z = appObj.isGroup ? 1 : 0
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
		// Fennek OS: a drag interrupted by the system (pointer grab lost) puts the tile back instead of freezing it.
		onCanceled: {
			Qt.callLater(tileGrid.resetDrag)
			Qt.callLater(tileItem.fixCoordinateBindings)
		}
		onClicked: function(mouse) {
			mouse.accepted = true
			tileGrid.resetDrag()
			if (mouse.button == Qt.LeftButton) {
				if (tileEditorView && tileEditorView.tile) {
					openTileEditor()
				} else if (modelData.tileType == "group") {
					tileGrid.headerClicked(index)   // Fennek OS: fold / unfold at once; double-click: rename
				} else if (modelData.url) {
					appsModel.tileGridModel.runApp(modelData.url)
				}
			} else if (mouse.button == Qt.RightButton) {
				contextMenu.open(mouse.x, mouse.y)
			}
		}
	}

	// Fennek OS: rename a group in place: double-click its name, type, Enter (Escape or clicking away keeps the old one).
	Loader {
		id: renameLoader
		active: tileGrid.renamingIndex === index
		z: 2
		x: 1
		y: 1
		width: tileItem.width - 2
		height: Math.min(tileItem.height - 2, cellSize * 0.5)
		sourceComponent: QQC2.TextField {
			text: appObj.labelText
			font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
			Component.onCompleted: { forceActiveFocus(); selectAll() }
			onAccepted: { var i = index, t = text; tileGrid.renamingIndex = -1; tileGrid.renameGroup(i, t) }
			Keys.onEscapePressed: tileGrid.renamingIndex = -1
			onActiveFocusChanged: if (!activeFocus && tileGrid.renamingIndex === index) tileGrid.renamingIndex = -1
		}
	}

	// Fennek OS: internal drag (tiles move inside the menu). "Automatic" handed the pointer to the system drag and
	// drop, so the tile stopped following and never saw the release: it froze half-way.
	Drag.dragType: Drag.Internal
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

	// Fennek OS: resize by dragging the bottom-right corner (shown on hover), in whole cells.
	MouseArea {
		id: resizeGrip
		visible: !appObj.isGroup && !plasmoid.configuration.tilesLocked && !dragActive
			&& (tileMouseArea.containsMouse || containsMouse || pressed)
		width: Math.max(16, Math.round(cellSize * 0.3))
		height: width
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.margins: cellMargin
		hoverEnabled: true
		preventStealing: true
		cursorShape: Qt.SizeFDiagCursor
		property point start
		property int startW
		property int startH
		property int previewW
		property int previewH
		// The size follows the pointer the whole way (an outline) and is saved when you let go. (Saving rebuilds
		// every tile, so saving on each step ended the drag after the first one.)
		onPressed: function(mouse) {
			start = mapToItem(tileGrid, mouse.x, mouse.y)
			startW = previewW = modelData.w
			startH = previewH = modelData.h
		}
		onPositionChanged: function(mouse) {
			if (!pressed) return
			var p = mapToItem(tileGrid, mouse.x, mouse.y)
			var f = tileGrid.fitTile(index, startW + Math.round((p.x - start.x) / cellBoxSize), startH + Math.round((p.y - start.y) / cellBoxSize))
			if (f) { previewW = f.w; previewH = f.h }
		}
		onReleased: {
			var i = index, w = previewW, h = previewH
			Qt.callLater(function () { tileGrid.resizeTile(i, w, h) })
		}
		Canvas {
			anchors.fill: parent
			opacity: parent.containsMouse || parent.pressed ? 0.9 : 0.55
			onPaint: {
				var c = getContext("2d")
				c.reset()
				c.strokeStyle = "white"
				c.lineWidth = 1.6
				c.lineCap = "round"
				for (var i = 1; i <= 2; i++) {
					var o = width * i / 3
					c.beginPath(); c.moveTo(width - 2, o); c.lineTo(o, height - 2); c.stroke()
				}
			}
		}
	}

	// Fennek OS: the new size while a tile's corner is dragged.
	Rectangle {
		visible: resizeGrip.pressed
		z: 3
		x: cellMargin
		y: cellMargin
		width: resizeGrip.previewW * cellBoxSize - cellMargin * 2
		height: resizeGrip.previewH * cellBoxSize - cellMargin * 2
		radius: 8
		color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.18)
		border.width: 2
		border.color: Kirigami.Theme.highlightColor
	}

	// Fennek OS: a folded group shows its apps as small tiles in the row under its name (click one to open it).
	Row {
		id: preview
		readonly property var group: modelData
		readonly property int groupIndex: index
		visible: appObj.isGroup && !!modelData.folded && !!modelData.previewRow
		y: modelData.h * cellBoxSize
		Repeater {
			model: parent.visible ? modelData.folded.slice(0, modelData.w) : []
			delegate: Item {
				id: mini
				required property var modelData
				required property int index
				readonly property var app: modelData.url ? appsModel.tileGridModel.getApp(modelData.url) : null
				readonly property int more: preview.group.folded.length - preview.group.w + 1
				width: cellBoxSize
				height: cellBoxSize
				Rectangle {
					anchors.fill: parent
					anchors.margins: cellMargin
					radius: 8
					color: config.defaultTileColor
					opacity: miniMouse.containsMouse ? 1 : 0.85
				}
				Kirigami.Icon {
					anchors.centerIn: parent
					width: Math.round(cellSize * 0.55)
					height: width
					visible: !moreLabel.visible
					source: mini.modelData.icon || (mini.app ? mini.app.decoration : "") || mini.modelData.url.replace(/\.desktop$/, "")
				}
				QQC2.Label {
					id: moreLabel
					anchors.centerIn: parent
					visible: mini.index == preview.group.w - 1 && mini.more > 1
					text: "+" + mini.more
					font.weight: Font.DemiBold
				}
				MouseArea {
					id: miniMouse
					anchors.fill: parent
					hoverEnabled: true
					property point down
					onPressed: function(mouse) { down = Qt.point(mouse.x, mouse.y) }
					onPositionChanged: function(mouse) {   // dragging a small tile opens the group: its tiles move from there
						if (pressed && Math.abs(mouse.x - down.x) + Math.abs(mouse.y - down.y) > Qt.styleHints.startDragDistance) {
							var g = preview.groupIndex
							Qt.callLater(function () { tileGrid.setGroupFolded(g, false) })
						}
					}
					onClicked: moreLabel.visible ? tileGrid.setGroupFolded(preview.groupIndex, false) : appsModel.tileGridModel.runApp(mini.modelData.url)
					QQC2.ToolTip.visible: containsMouse
					QQC2.ToolTip.text: moreLabel.visible ? i18n("Show all") : (mini.modelData.label || (mini.app ? mini.app.display : ""))
				}
			}
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

	// Fennek OS: a group's walls, always shown (clearer on hover), with handles on the right wall, the bottom wall and the corner to move them.
	Loader {
		id: groupEffectLoader
		active: appObj.isGroup && appObj.groupRect && appObj.groupRect.h > 0   // folded: around its row of small tiles
		sourceComponent: Rectangle {
			id: groupOutline
			property bool dragging: false
			property int previewW
			property int previewRows
			readonly property bool hot: groupHover.hovered || tileMouseArea.containsMouse || dragging
			color: "transparent"   // above the tiles (so the grip is reachable): an outline only
			border.width: Math.max(1, Math.round(1 * Screen.devicePixelRatio))   // a hint of the walls; clearer on hover
			border.color: Qt.rgba(config.menuTextColor.r, config.menuTextColor.g, config.menuTextColor.b, hot ? 0.16 : 0.04)
			radius: 12
			x: 1
			y: 1   // wraps the name too
			width: (dragging ? previewW : appObj.groupRect.w) * cellBoxSize - 2
			height: (modelData.h + (dragging ? previewRows : appObj.groupRect.h)) * cellBoxSize - 2
			Behavior on border.color { ColorAnimation { duration: 120 } }
			HoverHandler { id: groupHover }
			// Handles: the right wall (width), the bottom wall (rows), the corner (both). Wide grab strips that
			// straddle the wall, snapping at half a cell.
			Repeater {
				model: plasmoid.configuration.tilesLocked ? [] : (modelData.folded ? [[1, 0]] : [[1, 0], [0, 1], [1, 1]])
				MouseArea {
					id: handle
					required property var modelData
					readonly property int sx: modelData[0]
					readonly property int sy: modelData[1]
					readonly property int strip: Math.max(12, Math.round(cellSize * 0.18))
					readonly property bool corner: sx && sy
					x: sx ? groupOutline.width - (corner ? width - strip / 2 : strip / 2) : 0
					y: sy ? groupOutline.height - (corner ? height - strip / 2 : strip / 2) : 0
					width: corner ? Math.round(cellSize * 0.5) : (sx ? strip : groupOutline.width - Math.round(cellSize * 0.5))
					height: corner ? Math.round(cellSize * 0.5) : (sy ? strip : groupOutline.height - Math.round(cellSize * 0.5))
					z: corner ? 1 : 0
					hoverEnabled: true
					preventStealing: true
					cursorShape: corner ? Qt.SizeFDiagCursor : (sx ? Qt.SizeHorCursor : Qt.SizeVerCursor)
					property point start
					property int startW
					property int startRows
					onPressed: function(mouse) {
						start = mapToItem(tileGrid, mouse.x, mouse.y)
						startW = groupOutline.previewW = appObj.groupRect.w
						startRows = groupOutline.previewRows = appObj.groupRect.h
						groupOutline.dragging = true
					}
					// The walls follow the pointer the whole way; the size is saved when you let go.
					onReleased: {
						var i = index, w = groupOutline.previewW, r = groupOutline.previewRows
						groupOutline.dragging = false
						Qt.callLater(function () { tileGrid.resizeGroup(i, w, r) })
					}
					onCanceled: groupOutline.dragging = false
					onPositionChanged: function(mouse) {
						if (!pressed) return
						var p = mapToItem(tileGrid, mouse.x, mouse.y)
						var f = tileGrid.fitGroup(index, startW + sx * Math.round((p.x - start.x) / cellBoxSize),
							startRows + sy * Math.round((p.y - start.y) / cellBoxSize))
						if (f) { groupOutline.previewW = f.w; groupOutline.previewRows = f.rows }   // folded: fitGroup keeps its one row
					}
					// the wall being grabbed lights up
					Rectangle {
						visible: !handle.corner
						color: config.menuTextColor
						opacity: handle.containsMouse || handle.pressed ? 0.6 : 0
						radius: 1.5
						x: handle.sx ? (parent.width - width) / 2 : 12
						y: handle.sy ? (parent.height - height) / 2 : 12
						width: handle.sx ? 3 : parent.width - 24
						height: handle.sy ? 3 : parent.height - 24
						Behavior on opacity { NumberAnimation { duration: 100 } }
					}
					Canvas {
						visible: handle.corner
						width: Math.round(cellSize * 0.32)
						height: width
						x: parent.width - width - handle.strip / 2 + 3
						y: parent.height - height - handle.strip / 2 + 3
						opacity: handle.containsMouse || handle.pressed ? 0.95 : (groupOutline.hot ? 0.55 : 0)   // only when the group is hovered
						onPaint: {
							var c = getContext("2d")
							c.reset()
							c.strokeStyle = config.menuTextColor
							c.lineWidth = 1.6
							c.lineCap = "round"
							for (var i = 1; i <= 2; i++) {
								var o = width * i / 3
								c.beginPath(); c.moveTo(width - 1, o); c.lineTo(o, height - 1); c.stroke()
							}
						}
					}
				}
			}
		}
	}

	AppContextMenu {
		id: contextMenu
		tileIndex: index
		onPopulateMenu: function(menu) {
			if (!plasmoid.configuration.tilesLocked && modelData.tileType == "group") {
				var removeGroup = menu.newMenuItem()   // Fennek OS: the group goes; its tiles stay where they are
				removeGroup.text = i18n("Remove group")
				removeGroup.icon = "list-remove"
				removeGroup.clicked.connect(function() { tileGrid.setGroupFolded(index, false); tileGrid.removeIndex(index) })   // tucked tiles come back first
				menu.addMenuItem(removeGroup)
			} else if (!plasmoid.configuration.tilesLocked) {
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

			// Fennek OS: group header: fold / unfold, rename (the tile editor), all in plain words.
			if (modelData.tileType == "group" && !plasmoid.configuration.tilesLocked) {
				var foldItem = menu.newMenuItem()
				foldItem.text = modelData.folded ? i18n("Unfold group") : i18n("Fold group")
				foldItem.icon = modelData.folded ? "go-down" : "go-up"
				foldItem.clicked.connect(function() { tileGrid.setGroupFolded(index, !tileGrid.tileModel[index].folded) })
				menu.addMenuItem(foldItem)
				var renameItem = menu.newMenuItem()
				renameItem.text = i18n("Rename group…")
				renameItem.icon = "edit-rename"
				renameItem.clicked.connect(function() { tileItem.openTileEditor() })
				menu.addMenuItem(renameItem)
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
				// ...and what it may do outside its box (Settings > App permissions, opened on it).
				var permItem = menu.newMenuItem()
				permItem.text = i18n("App permissions")
				permItem.icon = "fennek-set-permissions"
				permItem.clicked.connect(function() {
					Qt.openUrlExternally("fennek-permissions:" + modelData.url.replace(/\.desktop$/, ""))
				})
				menu.addMenuItem(permItem)
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
