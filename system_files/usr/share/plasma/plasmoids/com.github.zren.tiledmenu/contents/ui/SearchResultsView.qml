import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

GridLayout {
	id: searchResultsView
	rowSpacing: 0
	property alias listView: searchResultsList
	property bool filterViewOpen: false
	
	RowLayout {
		id: searchFiltersRow
		Layout.row: searchView.searchOnTop ? 2 : 0
		Layout.preferredHeight: config.searchFilterRowHeight - 1 // -1px is for the underline seperator
		Layout.fillWidth: true

		// Fennek OS: plain text tabs with an accent underline (the old icon buttons drew dark, ghost-like icons).
		// Files = Fennek's own instant file search (KDE's file indexer is off).
		Repeater {
			model: [
				{ name: i18n("All"), filters: [] },
				{ name: i18n("Apps"), filters: ["services"] },
				{ name: i18n("Files"), filters: ["fennek-search"] },
			]
			PlasmaComponents3.ToolButton {
				required property var modelData
				readonly property bool current: modelData.filters.length ? search.isFilter(modelData.filters[0]) : search.isDefaultFilter
				Layout.preferredHeight: searchFiltersRow.Layout.preferredHeight
				flat: true
				text: modelData.name
				font.weight: current ? Font.DemiBold : Font.Normal
				opacity: current ? 1 : 0.65
				onClicked: modelData.filters.length ? search.filters = modelData.filters : search.applyDefaultFilters()
				Rectangle {
					anchors.horizontalCenter: parent.horizontalCenter
					anchors.bottom: parent.bottom
					anchors.bottomMargin: 4
					width: parent.width * 0.5; height: 2; radius: 1
					color: Kirigami.Theme.highlightColor
					visible: parent.current
				}
			}
		}

		Item { Layout.fillWidth: true }

		FlatButton {
			id: moreFiltersButton
			Layout.preferredHeight: parent.Layout.preferredHeight
			Layout.preferredWidth: moreFiltersButtonRow.implicitWidth + padding*2
			// property int padding: (config.searchFilterRowHeight - config.flatButtonIconSize) / 2
			padding: (config.searchFilterRowHeight - config.flatButtonIconSize) / 2
			// enabled: false

			RowLayout {
				id: moreFiltersButtonRow
				anchors.centerIn: parent
				anchors.margins: parent.padding
				
				PlasmaComponents3.Label {
					id: moreFiltersButtonLabel
					text: i18n("Filters")
				}
				Kirigami.Icon {
					source: "arrow-down-symbolic"
					isMask: true
					color: "#f0eef5"   // light on the dark menu (see FlatButton)
					rotation: searchResultsView.filterViewOpen ? 180 : 0
					Layout.preferredHeight: config.flatButtonIconSize
					Layout.preferredWidth: config.flatButtonIconSize

					Behavior on rotation {
						NumberAnimation { duration: Kirigami.Units.longDuration }
					}
				}
			}

			onClicked: searchResultsView.filterViewOpen = !searchResultsView.filterViewOpen
		}
	}

	Rectangle {
		color: "#1affffff"   // Fennek OS: a faint line, not a black bar
		height: 1
		width: parent.width
		// anchors.bottom: searchFiltersRow.bottom - 1
	}

	QQC2.StackView {
		id: searchResultsViewStackView
		Layout.row: searchView.searchOnTop ? 0 : 2
		Layout.fillWidth: true
		Layout.fillHeight: true
		clip: true
		initialItem: searchResultsListScrollView

		Connections {
			target: searchResultsView
			function onFilterViewOpenChanged() {
				if (searchResultsView.filterViewOpen) {
					searchResultsViewStackView.push(searchFiltersViewScrollView)
				} else {
					searchResultsViewStackView.pop()
				}
			}
		}

		QQC2.ScrollView {
			id: searchResultsListScrollView
			visible: false

			SearchResultsList {
				id: searchResultsList
			}
		}

		QQC2.ScrollView {
			id: searchFiltersViewScrollView
			visible: false

			SearchFiltersView {
				id: searchFiltersView
			}
		}
		
	}
}
