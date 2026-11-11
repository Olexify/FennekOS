// Support Fennek OS: one button that cycles through the ways to donate, and a list of them all. Nothing here goes online until
// you click a link. Addresses are copied, never paid from here.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

Item {
    id: root

    readonly property string evm: "0x97369cf0f17593505df60249cc48bd1a60cefb32"
    readonly property var methods: [
        { name: "Monobank", chip: "M", net: "Pay by card", url: "https://send.monobank.ua/jar/4jizk5cDBp" },
        { name: "USDT", chip: "₮", net: "Ethereum (ERC-20)", addr: evm },
        { name: "USDC", chip: "$", net: "Ethereum (ERC-20)", addr: evm },
        { name: "BTC", chip: "₿", net: "Bitcoin", addr: "bc1q9ajz2q3evfrw4jkpyck6jtgvlz8pgkk4duw2wp" },
        { name: "ETH", chip: "Ξ", net: "Ethereum", addr: evm },
        { name: "XMR", chip: "ɱ", net: "Monero", addr: "83VuZZ56m5UALCf8kuuSY9dbNxj9AH3uxcLZv7CEx3fYfimjKprtAaHGTGzBeyDzRRVZEqJPDBUYQirQiyCSjANSBtwDxFj" },
        { name: "SOL", chip: "◎", net: "Solana", addr: "CELaFhXdDAWD5AZc6WARgMe2guHbuN3pHroQWRwKMe2U" },
        { name: "LTC", chip: "Ł", net: "Litecoin", addr: "ltc1qxrgvajveu2w05ktyyhpwu6g45llexe5vjqxcjt" },
        { name: "Ko-fi", chip: "K", net: "not available yet", off: true }
    ]
    property int current: 0
    property bool open: false
    property var chosen: null
    property bool copied: false

    function choose(m) {
        if (m.off) return
        if (m.url) { Qt.openUrlExternally(m.url); return }
        chosen = m
        copied = false
        open = true
    }

    P5Support.DataSource { id: run; engine: "executable"; onNewData: source => disconnectSource(source) }
    Timer { id: copiedAgo; interval: 2500; onTriggered: root.copied = false }
    // Only while it's on screen and nobody is about to click it.
    Timer {
        interval: 3500
        repeat: true
        running: root.visible && !root.open && !cycling.hovered
        onTriggered: {
            do { root.current = (root.current + 1) % root.methods.length } while (root.methods[root.current].off)
        }
    }

    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.gridUnit
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                wrapMode: Text.Wrap
                text: "Fennek OS is free and made by one person, with no ads and nothing sold. If it made leaving your old system a little less scary, you can share some love."
            }

            RowLayout {
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                spacing: Kirigami.Units.smallSpacing
                QQC2.Button {
                    highlighted: true
                    text: "♥ Patreon"
                    onClicked: Qt.openUrlExternally("https://www.patreon.com/c/Olexifyyy")
                }
                QQC2.Button {
                    id: cycling
                    text: root.methods[root.current].name
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 7   // stays put as the name changes
                    onClicked: root.choose(root.methods[root.current])
                }
                QQC2.Button {
                    icon.name: root.open ? "go-up" : "go-down"
                    display: QQC2.AbstractButton.IconOnly
                    text: "More ways to donate"
                    QQC2.ToolTip.text: text
                    QQC2.ToolTip.visible: hovered
                    onClicked: root.open = !root.open
                }
            }

            GridLayout {
                visible: root.open
                columns: 3
                columnSpacing: Kirigami.Units.smallSpacing
                rowSpacing: Kirigami.Units.smallSpacing
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                Repeater {
                    model: root.methods
                    delegate: QQC2.AbstractButton {
                        id: card
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1   // three even columns
                        enabled: !modelData.off
                        opacity: enabled ? 1 : 0.5
                        onClicked: root.choose(modelData)
                        background: Rectangle {
                            radius: 8
                            color: card.hovered ? Qt.lighter(Kirigami.Theme.alternateBackgroundColor, 1.2) : Kirigami.Theme.alternateBackgroundColor
                            border.width: root.chosen === card.modelData ? 1 : 0
                            border.color: Kirigami.Theme.highlightColor
                        }
                        contentItem: RowLayout {
                            spacing: Kirigami.Units.smallSpacing
                            Rectangle {
                                Layout.margins: Kirigami.Units.smallSpacing
                                width: 28; height: 28; radius: 14
                                color: Kirigami.Theme.backgroundColor
                                QQC2.Label { anchors.centerIn: parent; text: card.modelData.chip; font.weight: Font.DemiBold }
                            }
                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true
                                Layout.topMargin: Kirigami.Units.smallSpacing
                                Layout.bottomMargin: Kirigami.Units.smallSpacing
                                QQC2.Label { text: card.modelData.name; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                QQC2.Label { text: card.modelData.net; opacity: 0.7; font: Kirigami.Theme.smallFont; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                        }
                    }
                }
            }

            // The address of the one you picked: the network matters, money sent on the wrong one is gone.
            ColumnLayout {
                visible: root.open && root.chosen !== null
                spacing: Kirigami.Units.smallSpacing
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                QQC2.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WrapAnywhere
                    font.family: "monospace"
                    text: root.chosen ? root.chosen.addr : ""
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    opacity: 0.75
                    text: root.chosen ? "Send only " + root.chosen.name + " on " + root.chosen.net + " to this address. Anything else can be lost." : ""
                }
                QQC2.Button {
                    icon.name: "edit-copy"
                    text: root.copied ? "Copied" : "Copy address"
                    onClicked: {
                        run.connectSource("wl-copy " + root.chosen.addr)
                        root.copied = true
                        copiedAgo.restart()
                    }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                wrapMode: Text.Wrap
                opacity: 0.75
                text: "Monthly support, even a small one, helps plan ahead, and every one-time coffee means a lot too. Thank you!"
            }
        }
    }
}
