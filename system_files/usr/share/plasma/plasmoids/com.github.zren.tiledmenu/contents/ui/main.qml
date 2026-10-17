import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker
import org.kde.coreaddons as KCoreAddons
// import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddons

import "lib"

PlasmoidItem {
	id: widget

	Logger {
		id: logger
		name: 'tiledmenu'
		// showDebug: true
	}

	SearchModel {
		id: search
		Component.onCompleted: {
			search.applyDefaultFilters()
		}
	}

	property alias rootModel: appsModel.rootModel
	AppsModel {
		id: appsModel
	}

	Item {
		// https://invent.kde.org/frameworks/kcoreaddons/-/blob/master/src/qml/kuserproxy.h
		// https://invent.kde.org/frameworks/kcoreaddons/-/blob/master/src/qml/kuserproxy.cpp
		KCoreAddons.KUser {
			id: kuser
			// faceIconUrl is an empty QUrl 'object' when ~/.face.icon doesn't exist.
			// Cast it to string first before checking if it's empty by casting to bool.
			readonly property bool hasFaceIcon: (''+faceIconUrl)
		}

		Kicker.DragHelper {
			id: dragHelper

			dragIconSize: Kirigami.Units.iconSizes.medium

			// Used when we only have a string and don't have a QIcon.
			// DragHelper.startDrag(...) requires a QIcon. See Issue #75.
			// property var defaultIconItem: KQuickControlsAddons.QIconItem {
			// 	id: defaultIconItem
			// }
			// property alias defaultIcon: defaultIconItem.icon
		}

		Kicker.ProcessRunner {
			id: processRunner
			// .runMenuEditor() to run kmenuedit
		}
	}

	AppletConfig {
		id: config
	}

	function logListModel(label, listModel) {
		console.log(label + '.count', listModel.count);
		// logObj(label, listModel);
		for (var i = 0; i < listModel.count; i++) {
			var item = listModel.modelForRow(i);
			var itemLabel = label + '[' + i + ']';
			console.log(itemLabel, item);
			logObj(itemLabel, item);
			if (('' + item).indexOf('Model') >= 0) {
				logListModel(itemLabel, item);
			}
		}
	}
	function logObj(label, obj) {
		// if (obj && typeof obj === 'object') {
		//  console.log(label, Object.keys(obj))
		// }
		
		for (var key in obj) {
			var val = obj[key];
			if (typeof val !== 'function') {
				var itemLabel = label + '.' + key;
				console.log(itemLabel, typeof val, val);
				if (('' + val).indexOf('Model') >= 0) {
					logListModel(itemLabel, val);
				}
			}
		}
	}

	toolTipMainText: ""
	toolTipSubText: ""

	compactRepresentation: LauncherIcon {
		id: panelItem
		iconSource: plasmoid.configuration.icon || "start-here-kde-symbolic"
	}

	hideOnWindowDeactivate: !widget.userConfiguring
	activationTogglesExpanded: true
	onExpandedChanged: {   // Fennek OS: no argument in Qt 6 (it was always undefined: search was never reset on open)
		if (expanded) {
			search.query = ""
			search.applyDefaultFilters()
			// config.showSearch = false
			// TODO popup is an invalid reference here for some reason
			fullRepresentationItem.searchView.searchField.forceActiveFocus()
			fullRepresentationItem.searchView.showDefaultView()

			// Debug TileEditorView
			// fullRepresentationItem.tileGrid.addDefaultTiles()
			// var testTile = fullRepresentationItem.tileGrid.getTileAt(0, 1)
			// fullRepresentationItem.tileGrid.editTile(testTile)

			// Show icon active effect without hovering
			justOpenedTimer.start()
		}
	}
	Timer {
		id: justOpenedTimer
		repeat: false
		interval: 600
	}

	// property alias searchResultsView: popup.searchView.searchResultsView
	// width: popup.width
	// height: popup.height

	fullRepresentation: Popup {
		id: popup

		Layout.minimumWidth: config.leftSectionWidth
		Layout.minimumHeight: config.minimumHeight
		Layout.preferredWidth: config.popupWidth
		Layout.preferredHeight: config.popupHeight

		// Layout.minimumHeight: 600 // For quickly testing as a desktop widget
		// Layout.minimumWidth: 800

		// Fennek OS: only sizes the user drags count. While the menu is being laid out (closed, or just opened) it
		// passes through small sizes; remembering those shrank it for good.
		property double openedAt: 0
		function userResizing() { return widget.expanded && Date.now() - openedAt > 1000 }
		Connections {
			target: widget
			function onExpandedChanged() { if (widget.expanded) popup.openedAt = Date.now() }
		}
		onWidthChanged: {
			if (userResizing()) resizeToFit.run()  // wider menu = more tile columns
		}
		onHeightChanged: {
			if (userResizing()) resizeHeight.restart()  // remember the height
		}

		// Make popup resizeable like default Kickoff widget.
		// The FullRepresentation must have an appletInterface property.
		// https://invent.kde.org/plasma/plasma-desktop/-/commit/23c4e82cdcb6c7f251c27c6eefa643415c8c5927
		// https://invent.kde.org/frameworks/plasma-framework/-/merge_requests/500/diffs
		readonly property var appletInterface: Plasmoid.self

		Timer {
			id: resizeHeight
			interval: 200
			onTriggered: {
				if (!plasmoid.configuration.fullscreen) {
					// Need to Math.ceil when writing to fix (Issue #71)
					var dPR = Screen.devicePixelRatio
					var pH2 = height / dPR
					var pH3 = Math.ceil(pH2)
					// console.log('pH.set', 'dPR='+dPR, 'pH1='+height, 'pH2='+pH2, 'pH3='+pH3)
					if (plasmoid.configuration.popupHeight != pH3) {
						plasmoid.configuration.popupHeight = pH3
					}
				}
			}
		}
		Timer {
			id: resizeToFit
			interval: attemptsLeft == attempts ? 200 : 100
			repeat: attemptsLeft > 0
			property int attempts: 10
			property int attemptsLeft: 10

			function run() {
				restart()
				attemptsLeft = attempts
			}

			onTriggered: {
				if (plasmoid.configuration.fullscreen) {
					attemptsLeft = 0
				} else {
					// Fennek OS: the open menu's width (was the taskbar button's, which left 0 tile columns).
					var favWidth = Math.max(0, popup.width - config.leftSectionWidth)
					// console.log(favWidth, widget.width, config.leftSectionWidth)
					// console.log(favWidth / config.cellBoxSize)
					// var cols = Math.floor(favWidth / config.favColWidth) * 2
					// Fennek OS: never fewer than 6 columns (3 medium tiles; a narrow resize used to hide the tiles for good).
					var cols = Math.max(6, Math.floor(favWidth / config.cellBoxSize))
					if (plasmoid.configuration.favGridCols != cols) {
						// console.log(plasmoid.configuration.favGridCols, cols)
						plasmoid.configuration.favGridCols = cols
					}
					// Force a reflow since Meta+RightClick+Drag resizing doesn't really play nice with PlasmaCore.Dialog.
					config.popupWidthChanged()
					widget.Layout.preferredWidthChanged()
					attemptsLeft -= 1
				}
			}
		}
		// Layout.onPreferredWidthChanged: console.log('popup.size', width, height)
		// Layout.onPreferredHeightChanged: console.log('popup.size', width, height)


		onFocusChanged: {
			if (focus) {
				popup.searchView.searchField.forceActiveFocus()
			}
		}
	}

	// Fennek: right-click on Start = quick links (test.sh checks every command below exists).
	P5Support.DataSource {
		id: quickRun
		engine: "executable"
		onNewData: (source) => disconnectSource(source)
	}
	function run(cmd) { quickRun.connectSource(cmd) }

	Plasmoid.contextualActions: [
		PlasmaCore.Action { text: i18n("Install or remove apps"); icon.name: "plasmadiscover"; onTriggered: widget.run("plasma-discover") },
		PlasmaCore.Action { text: i18n("Power options"); icon.name: "preferences-system-power-management"; onTriggered: widget.run("systemsettings kcm_powerdevilprofilesconfig") },
		PlasmaCore.Action { text: i18n("System"); icon.name: "hwinfo"; onTriggered: widget.run("kinfocenter") },
		PlasmaCore.Action { text: i18n("Network connections"); icon.name: "network-wired"; onTriggered: widget.run("systemsettings kcm_networkmanagement") },
		PlasmaCore.Action { text: i18n("Storage"); icon.name: "drive-harddisk"; onTriggered: widget.run("filelight") },
		PlasmaCore.Action { text: i18n("Disk management"); icon.name: "partitionmanager"; onTriggered: widget.run("partitionmanager") },
		PlasmaCore.Action { isSeparator: true },
		PlasmaCore.Action { text: i18n("Terminal"); icon.name: "utilities-terminal"; onTriggered: widget.run("konsole") },
		PlasmaCore.Action { text: i18n("Task Manager"); icon.name: "utilities-system-monitor"; onTriggered: widget.run("plasma-systemmonitor") },
		PlasmaCore.Action { text: i18n("Settings"); icon.name: "fennek-settings"; onTriggered: widget.run("fennek-app settings") },
		PlasmaCore.Action { text: i18n("File Explorer"); icon.name: "system-file-manager"; onTriggered: widget.run("dolphin") },
		PlasmaCore.Action { text: i18n("Run"); icon.name: "system-run"; onTriggered: widget.run("krunner") },
		PlasmaCore.Action { isSeparator: true },
		PlasmaCore.Action { text: i18n("Shut down or sign out"); icon.name: "system-shutdown"; onTriggered: widget.run("dbus-send --session --dest=org.kde.LogoutPrompt --type=method_call /LogoutPrompt org.kde.LogoutPrompt.promptAll") },
		PlasmaCore.Action { text: i18n("Desktop"); icon.name: "user-desktop"; onTriggered: widget.run("dbus-send --session --dest=org.kde.kglobalaccel --type=method_call /component/kwin org.kde.kglobalaccel.Component.invokeShortcut string:'Show Desktop'") }
	]

	Component.onCompleted: {
		// Plasmoid.internalAction("configure").trigger() // Uncomment to open the config window on load.
	}
}
