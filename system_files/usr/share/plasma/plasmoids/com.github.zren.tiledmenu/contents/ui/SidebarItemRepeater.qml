import QtQuick

Repeater {
	id: repeater
	property int buttonHeight: config.flatButtonSize
	property int iconSize: config.flatButtonIconSize

	delegate: SidebarItem {
		buttonHeight: repeater.buttonHeight
		iconSize: repeater.iconSize
		// Fennek OS: quiet monochrome folder icons in the left strip (the coloured ones shout on the dark menu).
		icon.name: (model.iconName && /^(folder|user-home)/.test(model.iconName)) ? model.iconName + "-symbolic" : (model.iconName || model.decoration)
		text: model.name || model.display
		sidebarMenu: repeater.parent.parent // SidebarContextMenu { Column { Repeater{} } }
		onClicked: {
			repeater.parent.parent.open = false // SidebarContextMenu { Column { Repeater{} } }
			repeater.model.triggerIndex(index)
		}
	}
}
