import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

GridLayout {
	id: searchResultsView
	rowSpacing: 0
	property alias listView: searchResultsList
	
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
				{ name: i18n("Apps"), filters: ["krunner_services"] },
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

		QQC2.ScrollView {
			id: searchResultsListScrollView
			visible: false
			QQC2.ScrollBar.vertical: FennekScrollBar {}

			SearchResultsList {
				id: searchResultsList
			}
		}

		
	}
}
