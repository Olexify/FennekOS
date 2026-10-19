import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
import "Utils.js" as Utils

DropArea {
	id: tileGrid

	property int cellSize: 60 * Screen.devicePixelRatio
	property real cellMargin: 3 * Screen.devicePixelRatio
	property real cellPushedMargin: 6 * Screen.devicePixelRatio
	property int cellBoxSize: cellMargin + cellSize + cellMargin
	property int hoverOutlineSize: 2 * Screen.devicePixelRatio

	property int minColumns: Math.floor(width / cellBoxSize)
	property int minRows: Math.floor(height / cellBoxSize)

	property int maxColumn: 0
	property int maxRow: 0
	property int maxWidth: 0
	property int maxHeight: 0
	property int columns: Math.max(minColumns, maxColumn)
	property int rows: Math.max(minRows, maxRow)


	//--- Drag and Drop properties
	property bool isDragging: false
	property var addedItem: null
	readonly property bool adding: addedItem
	property int draggedIndex: -1
	readonly property var draggedItem: draggedIndex >= 0 ? tileModel[draggedIndex] : null
	property bool editing: isDragging && draggedItem || adding
	property int dropHoverX: -1
	property int dropHoverY: -1
	property int dropOffsetX: 0
	property int dropOffsetY: 0
	readonly property int dropWidth: draggedItem ? draggedItem.w : addedItem ? addedItem.w : 0
	readonly property int dropHeight: draggedItem ? draggedItem.h : addedItem ? addedItem.h : 0
	property bool canDrop: false
	readonly property bool hasDrag: tileGrid.editing && dropHoverX >= 0 && dropHoverY >= 0
	readonly property bool isDraggingGroup: hasDrag && draggedItem && draggedItem.tileType == "group"
	readonly property var draggedGroupRect: {
		if (isDraggingGroup) {
			return getGroupAreaRect(draggedItem)
		} else {
			return null
		}
	}

	//--- Drag and Drop events
	// onContainsDragChanged: console.log('containsDrag', containsDrag)
	onEntered: function (drag) {   // the event (with the dropped app's address), not the DropArea's own drag property
		// console.log('onEntered', drag)
		dragTick(drag)
	}
	onPositionChanged: function (drag) {
		// console.log('onPositionChanged', drag)
		dragTick(drag)
	}
	onExited: {
		// console.log('onExited')
		resetDragHover()
	}
	onDropped: function (drop) {
		// console.log('onDropped', drop)
		if (draggedItem) {
			// Fennek OS: on a taken spot (shown red while dragging) the tile goes to the nearest free spot below in the
			// same column, never on top of another tile; no free spot nearby: it goes back.
			var freeY = dropHoverY
			var needH = footprintHeight()
			while (!canDrop && freeY < dropHoverY + 24 && hits(dropHoverX, freeY, dropWidth, needH)) freeY++
			if (canDrop || !hits(dropHoverX, freeY, dropWidth, needH)) tileGrid.moveTile(draggedItem, dropHoverX, freeY)
			tileGrid.resetDrag()
			// event.accept(Qt.MoveAction)
		} else if (addedItem) {
			addedItem.x = dropHoverX
			addedItem.y = dropHoverY
			tileGrid.tileModel.push(addedItem)
			tileGrid.tileModelChanged()
			tileGrid.resetDrag()
		}
	}

	// Drag and Drop functions
	function resetDragHover() {
		dropHoverX = -1
		dropHoverY = -1
		scrollUpArea.containsDrag = false
		scrollDownArea.containsDrag = false
		addedItem = null
	}
	function resetDrag() {
		resetDragHover()
		isDragging = false
		draggedIndex = -1
	}
	function startDrag(index) {
		draggedIndex = index
		dropHoverX = draggedItem.x
		dropHoverY = draggedItem.y
		isDragging = true
	}

	function tileWithin(tile, x1, y1, x2, y2) {
		var tileX2 = tile.x + tile.w - 1
		var tileY2 = tile.y + tile.h - 1
		return (x1 <= tileX2
			&& tile.x <= x2
			&& y1 <= tileY2
			&& tile.y <= y2
		)
	}

	function getGroupAreaRect(groupTile) {
		var x1 = groupTile.x
		var x2 = groupTile.x + groupTile.w - 1
		var y1 = groupTile.y + groupTile.h
		var y2 = 2000000 // maxint

		// Scan for other groups below this group
		// and adjust y2 to above that group.
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			if (tile.tileType == "group"
				&& tileWithin(tile, x1, y1, x2, y2)
			) {
				// We effectively use Math.min() here as we shrink the box tileWithin uses.
				y2 = tile.y - 1
				// console.log('group found at y =', tile.y, 'y2 set to', y2)
			}
		}

		// Fennek OS: a group has its own walls (rows under its name, set by dragging its corner); it never grows to
		// swallow tiles below it. Folded: only the row with its small tiles. Old groups without walls get them once
		// (fixGroupRows), around the tiles they had.
		if (groupTile.folded) {
			y2 = y1 + (groupTile.previewRow ? 1 : 0) - 1
			return { x1: x1, y1: y1, x2: x2, y2: y2, w: x2 - x1 + 1, h: y2 - y1 + 1 }
		}
		if (typeof groupTile.rows === "number") {
			y2 = Math.min(y2, y1 + Math.max(1, groupTile.rows) - 1)
			return { x1: x1, y1: y1, x2: x2, y2: y2, w: x2 - x1 + 1, h: y2 - y1 + 1 }
		}

		var lowestTileY = y1
		// console.log('lowestTileY start at y = ', lowestTileY)
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			if (tileWithin(tile, x1, y1, x2, y2)) {
				lowestTileY = Math.max(lowestTileY, tile.y + tile.h - 1)
				// console.log('lowestTileY set to', lowestTileY, JSON.stringify(tile))
			}
		}

		y2 = Math.min(lowestTileY, y2)

		return {
			x1: x1,
			y1: y1,
			x2: x2,
			y2: y2,
			w: x2 - x1 + 1,
			h: y2 - y1 + 1,
		}
	}

	// Fennek OS: rows a drop needs; a group needs its header plus the tiles under it.
	function footprintHeight() {
		return draggedItem && draggedItem.tileType == "group" ? dropHeight + getGroupAreaRect(draggedItem).h : dropHeight
	}

	// Fennek OS: fold a group (its tiles tucked away, the tiles below in its columns move up) and unfold it again.
	// The folded tiles are kept in the group, at their place relative to the header.
	// Takes the group's index: the real entry in tileModel. (A delegate's modelData is a copy: folding that copy
	// once kept the tucked tiles on the copy while removing the real ones, and they were lost.)
	// Fennek OS: a group's name, changed in place (double-click the header).
	function renameGroup(index, name) {
		var g = tileModel[index]
		name = String(name).trim()
		if (!g || g.tileType != "group" || !name || g.label === name) return
		g.label = name
		tileModelChanged()
	}

	function setGroupFolded(groupIndex, fold) {
		var group = tileModel[groupIndex]
		if (!group || group.tileType != "group" || !!group.folded === fold) return
		var x1 = group.x, x2 = group.x + group.w - 1, top = group.y + group.h
		var below = function (t, fromY) { return t !== group && t.y >= fromY && t.x <= x2 && t.x + t.w - 1 >= x1 }
		if (fold) {
			var area = getGroupAreaRect(group)
			var inside = tileModel.filter(function (t) { return tileWithin(t, area.x1, area.y1, area.x2, area.y2) })
			group.folded = inside.map(function (t) { var c = JSON.parse(JSON.stringify(t)); c.x -= group.x; c.y -= top; return c })
			group.foldedH = area.h
			group.previewRow = inside.length ? 1 : 0   // one row stays: the group's apps as small tiles
			for (var i = tileModel.length - 1; i >= 0; i--) if (inside.indexOf(tileModel[i]) >= 0) tileModel.splice(i, 1)   // in place: the list is bound to the saved settings
			tileModel.forEach(function (t) { if (below(t, area.y2 + 1)) t.y -= area.h - group.previewRow })
		} else {
			var h = (group.foldedH || 0) - (group.previewRow || 0)
			tileModel.forEach(function (t) { if (below(t, top + (group.previewRow || 0))) t.y += h })
			group.folded.forEach(function (c) { c.x += group.x; c.y += top; tileModel.push(c) })
			delete group.folded
			delete group.foldedH
			delete group.previewRow
		}
		tileGrid.tileModelChanged()
	}

	function moveGroup(groupTile, deltaX, deltaY) {
		var area = getGroupAreaRect(groupTile)

		// Move tiles below group label
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			if (tileWithin(tile, area.x1, area.y1, area.x2, area.y2)) {
				tile.x += deltaX
				tile.y += deltaY
			}
		}

		// We call this in moveTile so no need to duplicate work.
		// tileGrid.tileModelChanged()
	}

	function moveTile(tile, cellX, cellY) {
		if (tile.tileType == "group") {
			moveGroup(tile, cellX - tile.x, cellY - tile.y)
		}
		tile.x = cellX
		tile.y = cellY
		tileGrid.tileModelChanged()
	}

	// QQuickDropEvent
	// https://github.com/qt/qtdeclarative/blob/a4aa8d9ade44d75cb5a1d84bd7c1773fadc73095/src/quick/items/qquickdroparea_p.h#L63
	function dragTick(event) {
		// console.log('dragTick', event.x, event.y)
		var dragX = event.x + scrollView.flickableItem.contentX - dropOffsetX
		var dragY = event.y + scrollView.flickableItem.contentY - dropOffsetY
		var modelX = Math.floor(dragX / cellBoxSize)
		var modelY = Math.floor(dragY / cellBoxSize)
		var globalPoint = popup.mapFromItem(tileGrid, event.x, event.y)
		// console.log('onDragMove', event.x, event.y, modelX, modelY, globalPoint)
		scrollUpArea.checkContains(event)
		scrollDownArea.checkContains(event)

		if (draggedItem) {
		} else if (addedItem) {
		} else if (event && event.hasUrls && event.urls) {
			if (event.keys && event.keys.indexOf('favoriteId') >= 0) {
				var url = event.getDataAsString('favoriteId')
				url = Utils.parseDropUrl(url)
			} else {
				var url = event.urls[0]
				// console.log('new addedItem', event.urls, url)
				url = Utils.parseDropUrl(url)
			}
			// console.log('new addedItem')
			// console.log('\t', 'urls', event.urls)
			// console.log('\t', 'url', url)
			// console.log('\t', 'keys', event.keys)
			// for (var i = 0; i < event.keys.length; i++) {
			// 	var key = event.keys[i]
			// 	var value = event.getDataAsString(key)
			// 	console.log('\t', 'mimeData', key, value)
			// }

			addedItem = newTile(url)
			dropHoverX = modelX
			dropHoverY = modelY

			// Firefox/Chromium url dropped
			if (event.keys.indexOf('_NETSCAPE_URL') >= 0) {
				var netscapeUrl = event.getDataAsString('_NETSCAPE_URL')
				var tokens = netscapeUrl.split('\n')
				if (tokens.length >= 2) {
					var title = tokens[1].trim()
					if (title) {
						addedItem.label = title
						addedItem.icon = 'internet-web-browser'
					}
				}
			}
		} else {
			return
		}

		dropHoverX = Math.max(0, Math.min(modelX, columns - dropWidth))
		dropHoverY = Math.max(0, modelY)
		canDrop = !hits(dropHoverX, dropHoverY, dropWidth, footprintHeight())
	}

	property var hitBox: [] // hitBox[y][x]
	function updateSize() {
		var c = 0;
		var r = 0;
		var w = 1;
		var h = 1;
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			c = Math.max(c, tile.x + tile.w)
			r = Math.max(r, tile.y + tile.h + (tile.previewRow || 0))
			w = Math.max(w, tile.w)
			h = Math.max(h, tile.h)
		}
		// Add extra rows when dragging so we can drop scrolled down
		if (draggedItem) {
			// c += draggedItem.w
			r += draggedItem.h
		}

		// Rebuild hitBox
		var hbColumns = Math.max(minColumns, c)
		var hbRows = Math.max(minRows, r)
		var hb = new Array(hbRows)
		for (var i = 0; i < hbRows; i++) {
			hb[i] = new Array(hbColumns)
		}
		// Fennek OS: a dragged group carries its tiles along, so they don't block it either.
		var ownArea = draggedItem && draggedItem.tileType == "group" ? getGroupAreaRect(draggedItem) : null
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			if (i == draggedIndex || (ownArea && tileWithin(tile, ownArea.x1, ownArea.y1, ownArea.x2, ownArea.y2))) {
				continue;
			}
			for (var j = tile.y; j < tile.y + tile.h + (tile.previewRow || 0); j++) {   // a folded group's small tiles too
				for (var k = tile.x; k < tile.x + tile.w; k++) {
					hb[j][k] = true
				}
			}
		}

		// Update Properties
		hitBox = hb
		maxColumn = c
		maxRow = r
		maxWidth = w
		maxHeight = h
	}
	// Old groups (no walls yet): walls around the tiles they hold now, saved once.
	function fixGroupRows() {
		var changed = false
		for (var i = 0; i < tileModel.length; i++) {
			var g = tileModel[i]
			if (g.tileType == "group" && !g.folded && typeof g.rows !== "number") {
				g.rows = getGroupAreaRect(g).h
				changed = true
			}
		}
		return changed
	}

	// Drag a group's walls: they move in whole cells. Never smaller than the tiles inside, never over another group.
	// A folded group changes only its width (how many small tiles its row shows).
	// fitGroup: the size it may have (clamped), or null when that would overlap another group.
	function fitGroup(index, w, rows) {
		var g = tileModel[index]
		if (!g || g.tileType != "group") return null
		var minW = 1, minRows = 1
		if (g.folded) {
			rows = g.previewRow || 0
		} else {
			getTilesInArea(getGroupAreaRect(g)).forEach(function (t) {
				if (t === g) return
				minW = Math.max(minW, t.x + t.w - g.x)
				minRows = Math.max(minRows, t.y + t.h - (g.y + g.h))
			})
			rows = limit(minRows, rows, 40)
		}
		w = limit(Math.max(1, minW), w, columns - g.x)
		var top = g.y, bottom = g.y + g.h + Math.max(rows, 1) - 1, left = g.x, right = g.x + w - 1
		for (var i = 0; i < tileModel.length; i++) {
			var o = tileModel[i]
			if (i == index || o.tileType != "group") continue
			var oa = getGroupAreaRect(o)
			var oTop = o.y, oBottom = Math.max(o.y + o.h - 1, oa.y2), oLeft = o.x, oRight = o.x + o.w - 1
			if (left <= oRight && oLeft <= right && top <= oBottom && oTop <= bottom) return null
		}
		if (g.folded) {   // its row of small tiles must not run over plain tiles either
			for (var j = 0; j < tileModel.length; j++) {
				var p = tileModel[j]
				if (j != index && p.tileType != "group" && tileWithin(p, g.x + g.w, g.y, right, bottom)) return null
			}
		}
		return { w: w, rows: rows }
	}
	function resizeGroup(index, w, rows) {
		var g = tileModel[index], f = fitGroup(index, w, rows)
		if (!f || (f.w == g.w && (g.folded || f.rows == g.rows))) return
		g.w = f.w
		if (!g.folded) g.rows = f.rows
		tileModelChanged()
	}

	function update() {
		if (fixGroupRows()) {   // saved; this runs again
			tileModelChanged()
			return
		}
		var urlList = []
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			if (tile.url) {
				urlList.push(tile.url)
			}
			;(tile.folded || []).forEach(function (t) { if (t.url) urlList.push(t.url) })   // folded: shown as small tiles
		}
		appsModel.tileGridModel.favorites = urlList
		updateSize()
	}
	onDraggedItemChanged: update()
	onTileModelChanged: update()
	property var tileModel: []


	function hits(x, y, w, h) {
		// console.log('hits', [columns,rows], [x,y,w,h], hitBox)
		for (var j = y; j < y + h; j++) {
			if (j < 0 || j >= hitBox.length) {
				continue; // Should we return true when out of bounds?
			}
			for (var k = x; k < x + w; k++) {
				if (k < 0 || k >= hitBox[j].length) {
					continue; // Should we return true when out of bounds?
				}
				if (hitBox[j][k]) {
					return true
				}
			}
		}
		return false
	}

	function getTileAt(cellX, cellY) {
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			if (tileWithin(tile, cellX, cellY, cellX, cellY)) {
				return tile
			}
		}
		return null
	}

	function getTilesInArea(area) {
		var tileList = []

		// Move tiles below group label
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			if (tileWithin(tile, area.x1, area.y1, area.x2, area.y2)) {
				tileList.push(tile)
			}
		}

		// Sort results by y, then by x
		// tileList.sort(function(a, b) {
		// 	if (a.y == b.y) {
		// 		return b.x - a.x
		// 	} else {
		// 		return b.y - a.y
		// 	}
		// })

		return tileList
	}

	function getTileLabel(tile) {
		if (tile.url) {
			var app = appsModel.tileGridModel.getApp(tile.url)
			var labelText = tile.label || app.display || app.url || ""
			return labelText
		} else {
			return ""
		}
	}
	function sortGroupTiles(groupTile) {
		var area = getGroupAreaRect(groupTile)
		var tileList = getTilesInArea(area)

		var cursorX = groupTile.x
		var cursorY = groupTile.y + groupTile.h
		var rowH = 0
		tileList.sort(function(a, b) {
			var aLabel = getTileLabel(a)
			var bLabel = getTileLabel(b)
			return aLabel.localeCompare(bLabel)
		})

		for (var i = 0; i < tileList.length; i++) {
			var tile = tileList[i]
			var tileX2 = cursorX + tile.w - 1

			// If there's not enough room on this row
			if (tileX2 > area.x2) {
				// Move to the next row
				cursorX = groupTile.x
				cursorY += rowH
			}

			tile.x = cursorX
			tile.y = cursorY
			rowH = Math.max(rowH, tile.h)
			cursorX += tile.w
		}

		// We call this in moveTile so no need to duplicate work.
		tileGrid.tileModelChanged()
	}

	QQC2.ScrollView {
		id: scrollView
		anchors.fill: parent
		QQC2.ScrollBar.vertical: FennekScrollBar {}

		// Fennek OS: Qt 6's ScrollView has no flickableItem/viewport (Qt 5 names); its contentItem is the Flickable.
		// Without these, the drop position of a dragged tile was never computed and the tile jumped back.
		readonly property Flickable flickableItem: contentItem
		readonly property Item viewport: contentItem
		readonly property int scrollTop: flickableItem ? flickableItem.contentY : 0
		readonly property int scrollHeight: flickableItem ? flickableItem.contentHeight : 0
		readonly property int scrollTopAtBottom: viewport ? scrollHeight - viewport.height : 0
		readonly property bool scrollAtTop: scrollTop == 0
		readonly property bool scrollAtBottom: scrollTop >= scrollTopAtBottom

		function scrollBy(deltaY) {
			if (flickableItem) {
				// console.log('scrollHeight', scrollTopAtBottom, scrollHeight, viewport.height)
				flickableItem.contentY = Math.max(0, Math.min(scrollTop + deltaY, scrollTopAtBottom))
			}
		}

		// __wheelAreaScrollSpeed: cellBoxSize
		// style: ScrollViewStyle {
		// 	transientScrollBars: true
		// }
		
		Item {
			id: scrollItem

			width: columns * cellBoxSize
			height: rows * cellBoxSize

			// Rectangle {
			// 	anchors.fill: parent
			// 	color: "#88336699"
			// }

			Repeater {
				id: cellRepeater
				readonly property int cellCount: columns * rows
				onCellCountChanged: {
					if (!isDragging) {
						model = cellCount
					}
				}
				model: 0

				Item {
					id: cellItem
					property int modelX: modelData % columns
					property int modelY: Math.floor(modelData / columns)
					x: modelX * cellBoxSize
					y: modelY * cellBoxSize
					width: cellBoxSize
					height: cellBoxSize

					readonly property bool tileHovered: (hasDrag
						&& dropHoverX <= modelX && modelX < dropHoverX + dropWidth
						&& dropHoverY <= modelY && modelY < dropHoverY + dropHeight
					)
					readonly property bool groupAreaHovered: {
						if (isDraggingGroup) {
							var groupX1 = dropHoverX
							var groupY1 = dropHoverY + dropHeight
							var groupX2 = groupX1 + draggedGroupRect.w - 1
							var groupY2 = groupY1 + draggedGroupRect.h - 1
							return groupX1 <= modelX && modelX <= groupX2
								&& groupY1 <= modelY && modelY <= groupY2
						} else {
							return false
						}
					}

					Rectangle {
						anchors.fill: parent
						anchors.margins: cellMargin
						color: {
							if (cellItem.tileHovered) {
								if (canDrop) {
									return "#558a63d2"
								} else {
									return "#55c0392b"
								}
							} else if (cellItem.groupAreaHovered) {
								return "#8848395d" // purple
							} else {
								return "transparent"
							}
						}
						radius: 10   // Fennek OS: drop spots shaped like the tiles
						border.width: 1
						border.color: tileGrid.editing ? "#22ffffff" : "transparent"
					}

					MouseArea {
						anchors.fill: parent
						acceptedButtons: Qt.RightButton
						onClicked: function(mouse) {
							if (mouse.button == Qt.RightButton) {
								cellContextMenu.cellX = cellItem.modelX
								cellContextMenu.cellY = cellItem.modelY
								var pos = mapToItem(scrollItem, mouse.x, mouse.y) // cellContextMenu is a child of scrollItem
								cellContextMenu.open(pos.x, pos.y)
							}
						}

					}
				}
			}
			PlasmaExtras.Menu {
				id: cellContextMenu
				property int cellX: -1
				property int cellY: -1

				PlasmaExtras.MenuItem {
					icon: "group-new"
					text: i18n("New Group")
					visible: !plasmoid.configuration.tilesLocked
					onClicked: {
						var tile = tileGrid.addGroup(cellContextMenu.cellX, cellContextMenu.cellY)
						tileGrid.editTile(tile)
					}
				}

				TileGridPresets {
					id: tileGridPresets
					visible: !plasmoid.configuration.tilesLocked
				}

				PlasmaExtras.MenuItem {
					icon: plasmoid.configuration.tilesLocked ? "object-unlocked" : "object-locked"
					text: plasmoid.configuration.tilesLocked ? i18n("Unlock Tiles") : i18n("Lock Tiles")
					onClicked: {
						plasmoid.configuration.tilesLocked = !plasmoid.configuration.tilesLocked
					}
				}
			}

			Repeater {
				id: tileModelRepeater
				model: tileModel
				// onCountChanged: console.log('onCountChanged', count)
				
				TileItem {
					id: tileItem
				}
				
			}
		}
	}

	Loader {
		id: tileGridSplashLoader
		anchors.centerIn: parent
		active: tileModel.length == 0 && !tileGrid.editing
		visible: active && width <= parent.width
		source: "TileGridSplash.qml"
		property alias tileGridPresets: tileGridPresets
		property int maxWidth: parent.width
	}

	/* Scroll on hover with drag */
	property int scrollAreaTickDelta: cellBoxSize
	property int scrollAreaTickInterval: 200
	property int scrollAreaSize: Math.min(cellBoxSize * 1.5, scrollView.height / 5) // 20vh or 90pt

	Item {
		id: scrollUpArea
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.top: parent.top
		height: scrollAreaSize
		property bool active: !scrollView.scrollAtTop
		property bool containsDrag: false
		property bool ticking: active && containsDrag

		function checkContains(event) {
			containsDrag = scrollUpArea.contains(Qt.point(event.x, event.y))
		}

		Timer {
			id: scrollUpTicker
			interval: scrollAreaTickInterval
			repeat: true
			running: parent.ticking
			onTriggered: {
				scrollView.scrollBy(-scrollAreaTickDelta)
			}
		}

		Rectangle {
			anchors.fill: parent
			opacity: parent.ticking ? 1 : 0
			gradient: Gradient {
				GradientStop { position: 0.0; color: Kirigami.Theme.highlightColor }
				GradientStop { position: 0.3; color: "transparent" }
			}
		}
	}

	Item {
		id: scrollDownArea
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		height: scrollAreaSize
		property bool active: !scrollView.scrollAtBottom
		property bool containsDrag: false
		property bool ticking: active && containsDrag

		function checkContains(event) {
			var mouseY = event.y - (parent.height - height)
			containsDrag = scrollDownArea.contains(Qt.point(event.x, mouseY))
		}

		Timer {
			id: scrollDownTicker
			interval: scrollAreaTickInterval
			repeat: true
			running: parent.ticking
			onTriggered: {
				scrollView.scrollBy(scrollAreaTickDelta)
			}
		}

		Rectangle {
			anchors.fill: parent
			opacity: parent.ticking ? 1 : 0
			gradient: Gradient {
				GradientStop { position: 0.7; color: "transparent" }
				GradientStop { position: 1.0; color: Kirigami.Theme.highlightColor }
			}
		}
	}

	function newTile(url) {
		return {
			"x": 0,
			"y": 0,
			"w": 2,
			"h": 2,
			"url": url,
		}
	}

	function removeIndex(i) {
		tileModel.splice(i, 1) // remove 1 item at index
		tileModelChanged()
	}

	function removeApp(url) {
		var removedCount = 0
		for (var i = tileModel.length - 1; i >= 0; i--) {
			var tile = tileModel[i]
			if (tile.url == url) {
				removedCount += 1
				tileModel.splice(i, 1) // remove 1 item at index
			}
		}
		if (removedCount > 0) {
			tileModelChanged()
		}
	}

	function findOpenPos(w, h) {
		for (var y = 0; y < rows; y++) {
			for (var x = 0; x < columns - (w-1); x++) {
				if (hits(x, y, w, h))
					continue

				// Room open for
				return {
					x: x,
					y: y,
				}
			}
		}

		// Current grid has no room.
		// Add to new row.
		return {
			x: 0,
			y: rows
		}
	}

	function parseTileXY(tile, x, y) {
		if (typeof x !== "undefined" && typeof y !== "undefined") {
			tile.x = x
			tile.y = y
		} else {
			var openPos = findOpenPos(tile.w, tile.h)
			tile.x = openPos.x
			tile.y = openPos.y
		}
	}
	function addApp(url, x, y) {
		url = Utils.parseDropUrl(url)
		var tile = newTile(url)
		parseTileXY(tile, x, y)
		tileModel.push(tile)
		tileModelChanged()
		return tile
	}

	function hasAppTile(url) {
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			if (tile.url == url) {
				return true
			}
		}
		return false
	}

	function limit(minValue, value, maxValue) {
		return Math.max(minValue, Math.min(value, maxValue))
	}

	// Fennek OS: resize by the corner grip. Only into free cells, never over another tile or past the edge.
	// fitTile: the size a tile may have (clamped), or null when it would cover another tile.
	function fitTile(index, w, h) {
		var tile = tileModel[index]
		w = limit(1, w, columns - tile.x)
		h = limit(1, h, 8)
		for (var i = 0; i < tileModel.length; i++) {
			var t = tileModel[i]
			if (i == index) continue
			var t2 = { x: t.x, y: t.y, w: t.w, h: t.h + (t.previewRow || 0) }   // a folded group's small tiles count
			if (tileWithin(t2, tile.x, tile.y, tile.x + w - 1, tile.y + h - 1)) return null
		}
		return { w: w, h: h }
	}
	function resizeTile(index, w, h) {
		var tile = tileModel[index], f = fitTile(index, w, h)
		if (!f || (f.w == tile.w && f.h == tile.h)) return
		tile.w = f.w
		tile.h = f.h
		tileModelChanged()
	}

	function addTile(x, y, props) {
		var tile = newTile("")
		parseTileXY(tile, x, y)
		if (typeof props !== "undefined") {
			var keys = Object.keys(props)
			for (var i = 0; i < keys.length; i++) {
				var key = keys[i]
				var value = props[key]
				tile[key] = value
			}
		}
		tileModel.push(tile)
		tileModelChanged()
		return tile
	}

	function addGroup(x, y, props) {
		var groupProps = {
			tileType: "group",
			label: i18nc("default group label", "Group"),
			w: limit(2, columns-x, 6), // 6 unless we have less columns.
			h: 1,
		}
		if (typeof props !== "undefined") {
			var keys = Object.keys(props)
			for (var i = 0; i < keys.length; i++) {
				var key = keys[i]
				var value = props[key]
				groupProps[key] = value
			}
		}
		return addTile(x, y, groupProps)
	}

	// Use for quickly testing on widget load
	function addDefaultTiles() {
		tileGridPresets.addDefault()
	}

	signal editTile(var tile)
}
