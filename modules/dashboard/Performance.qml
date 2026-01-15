import qs.components
import qs.components.misc
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Appearance.spacing.normal

    function displayTemp(temp: real): string {
        return `${Math.ceil(Config.services.useFahrenheit ? temp * 1.8 + 32 : temp)}°${Config.services.useFahrenheit ? "F" : "C"}`;
    }

    Ref {
        service: SystemUsage
    }

    // Top section: CPU and GPU side by side as hero cards
    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        // CPU Hero Card
        HeroCard {
            Layout.fillWidth: true
            Layout.minimumWidth: 400
            Layout.preferredHeight: 150

            visible: Config.dashboard.performance.showCpu

            icon: "memory"
            title: SystemUsage.cpuName ? `CPU - ${SystemUsage.cpuName}` : qsTr("CPU")
            mainValue: `${Math.round(SystemUsage.cpuPerc * 100)}%`
            mainLabel: qsTr("Usage")
            secondaryValue: root.displayTemp(SystemUsage.cpuTemp)
            secondaryLabel: qsTr("Temp")
            usage: SystemUsage.cpuPerc
            temperature: SystemUsage.cpuTemp
            accentColor: Colours.palette.m3primary
        }

        // GPU Hero Card
        HeroCard {
            Layout.fillWidth: true
            Layout.minimumWidth: 400
            Layout.preferredHeight: 150

            visible: Config.dashboard.performance.showGpu

            icon: "display_settings"
            title: SystemUsage.gpuName ? `GPU - ${SystemUsage.gpuName}` : qsTr("GPU")
            mainValue: `${Math.round(SystemUsage.gpuPerc * 100)}%`
            mainLabel: qsTr("Usage")
            secondaryValue: root.displayTemp(SystemUsage.gpuTemp)
            secondaryLabel: qsTr("Temp")
            usage: SystemUsage.gpuPerc
            temperature: SystemUsage.gpuTemp
            accentColor: Colours.palette.m3secondary
        }
    }

    // Bottom section: Memory and Storage
    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        // Memory Card with gauge
        GaugeCard {
            Layout.minimumWidth: 250
            Layout.preferredHeight: 220

            visible: Config.dashboard.performance.showMemory

            icon: "memory_alt"
            title: qsTr("Memory")
            percentage: SystemUsage.memPerc
            subtitle: {
                const usedFmt = SystemUsage.formatKib(SystemUsage.memUsed);
                const totalFmt = SystemUsage.formatKib(SystemUsage.memTotal);
                return `${usedFmt.value.toFixed(1)} / ${Math.floor(totalFmt.value)} ${totalFmt.unit}`;
            }
            accentColor: Colours.palette.m3tertiary
        }

        // Storage Card
        StorageCard {
            Layout.fillWidth: true
            Layout.minimumWidth: 550
            Layout.preferredHeight: 220

            visible: Config.dashboard.performance.showStorage
        }
    }

    // ============================================
    // Components
    // ============================================

    component HeroCard: StyledRect {
        id: heroCard

        property string icon
        property string title
        property string mainValue
        property string mainLabel
        property string secondaryValue
        property string secondaryLabel
        property real usage: 0        // Usage percentage (0-1) for background overlay
        property real temperature: 0  // Temperature in Celsius for progress bar
        property color accentColor: Colours.palette.m3primary

        // Temperature range for the bar (0-100°C mapped to 0-1)
        readonly property real maxTemp: 100
        readonly property real tempProgress: Math.min(1, Math.max(0, temperature / maxTemp))

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.large
        clip: true

        // Animated usage for progress bar
        property real animatedUsage: 0
        onUsageChanged: animatedUsage = usage
        Behavior on animatedUsage {
            Anim { duration: Appearance.anim.durations.large }
        }

        // Animated temp for background overlay
        property real animatedTemp: 0
        onTempProgressChanged: animatedTemp = tempProgress
        Behavior on animatedTemp {
            Anim { duration: Appearance.anim.durations.large }
        }

        Component.onCompleted: {
            animatedUsage = usage
            animatedTemp = tempProgress
        }

        // Background progress overlay (temperature)
        StyledRect {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.max(0.02, heroCard.animatedTemp)

            color: Qt.alpha(heroCard.accentColor, 0.08)
            radius: parent.radius

            visible: heroCard.animatedTemp > 0.001
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.small

            // Header row with icon and full title
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                MaterialIcon {
                    text: heroCard.icon
                    fill: 1
                    color: heroCard.accentColor
                    font.pointSize: Appearance.font.size.large
                }

                StyledText {
                    text: heroCard.title
                    font.pointSize: Appearance.font.size.normal
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Item { Layout.fillHeight: true }

            // Bottom row: Temp on left, Usage on right
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                // Temperature (left side)
                Row {
                    spacing: Appearance.spacing.small

                    StyledText {
                        text: heroCard.secondaryValue
                        font.pointSize: Appearance.font.size.normal
                        font.weight: Font.Medium
                    }

                    StyledText {
                        text: heroCard.secondaryLabel
                        font.pointSize: Appearance.font.size.smaller
                        color: Colours.palette.m3onSurfaceVariant
                        anchors.baseline: parent.children[0].baseline
                    }
                }

                Item { Layout.fillWidth: true }

                // Usage percentage (right side)
                Column {
                    spacing: -4

                    StyledText {
                        anchors.right: parent.right
                        text: heroCard.mainValue
                    font.pointSize: Appearance.font.size.large
                        font.weight: Font.Medium
                        color: heroCard.accentColor
                    }

                    StyledText {
                        anchors.right: parent.right
                        text: heroCard.mainLabel
                        font.pointSize: Appearance.font.size.smaller
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }

            // Progress bar at bottom (usage)
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 6

                color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                radius: Appearance.rounding.full

                StyledRect {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * heroCard.animatedUsage

                    color: heroCard.accentColor
                    radius: Appearance.rounding.full
                }
            }
        }
    }

    component GaugeCard: StyledRect {
        id: gaugeCard

        property string icon
        property string title
        property real percentage: 0
        property string subtitle
        property color accentColor: Colours.palette.m3primary

        // Arc configuration: 3/4 circle (270 degrees)
        readonly property real arcStartAngle: 0.75 * Math.PI
        readonly property real arcSweep: 1.5 * Math.PI

        property real animatedPercentage: 0
        Component.onCompleted: animatedPercentage = percentage
        onPercentageChanged: animatedPercentage = percentage
        Behavior on animatedPercentage {
            Anim { duration: Appearance.anim.durations.large }
        }

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.large
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.smaller

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                MaterialIcon {
                    text: gaugeCard.icon
                    fill: 1
                    color: gaugeCard.accentColor
                    font.pointSize: Appearance.font.size.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: gaugeCard.title
                    font.pointSize: Appearance.font.size.normal
                }
            }

            // Gauge
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Canvas {
                    id: gaugeCanvas

                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();

                        const cx = width / 2;
                        const cy = height / 2;
                        const radius = (Math.min(width, height) - 12) / 2;
                        const lineWidth = 10;

                        // Background arc
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, gaugeCard.arcStartAngle, gaugeCard.arcStartAngle + gaugeCard.arcSweep);
                        ctx.lineWidth = lineWidth;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = Colours.layer(Colours.palette.m3surfaceContainerHigh, 2);
                        ctx.stroke();

                        // Progress arc
                        if (gaugeCard.animatedPercentage > 0) {
                            ctx.beginPath();
                            ctx.arc(cx, cy, radius, gaugeCard.arcStartAngle, gaugeCard.arcStartAngle + gaugeCard.arcSweep * gaugeCard.animatedPercentage);
                            ctx.lineWidth = lineWidth;
                            ctx.lineCap = "round";
                            ctx.strokeStyle = gaugeCard.accentColor;
                            ctx.stroke();
                        }
                    }

                    Connections {
                        target: gaugeCard
                        function onAnimatedPercentageChanged() {
                            gaugeCanvas.requestPaint();
                        }
                    }

                    Connections {
                        target: Colours
                        function onPaletteChanged() {
                            gaugeCanvas.requestPaint();
                        }
                    }

                    Component.onCompleted: requestPaint()
                }

                // Center percentage
                StyledText {
                    anchors.centerIn: parent
                    text: `${Math.round(gaugeCard.percentage * 100)}%`
                    font.pointSize: Appearance.font.size.extraLarge
                    font.weight: Font.Medium
                    color: gaugeCard.accentColor
                }
            }

            // Subtitle at bottom
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: gaugeCard.subtitle
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    component StorageCard: StyledRect {
        id: storageCard

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.large
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.normal

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                MaterialIcon {
                    text: "hard_disk"
                    fill: 1
                    color: Colours.palette.m3secondary
                    font.pointSize: Appearance.font.size.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Storage")
                    font.pointSize: Appearance.font.size.normal
                }
            }

            // Disk list
            Repeater {
                model: SystemUsage.disks.slice(0, 5)

                delegate: DiskRow {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    diskName: modelData.mount
                    used: modelData.used
                    total: modelData.total
                    percentage: modelData.perc
                    diskColor: index === 0 ? Colours.palette.m3primary : 
                               index === 1 ? Colours.palette.m3secondary :
                               index === 2 ? Colours.palette.m3tertiary :
                               index === 3 ? Colours.palette.m3outline :
                               Colours.palette.m3error
                }
            }

            Item { Layout.fillHeight: SystemUsage.disks.length < 5 }
        }
    }

    component DiskRow: Item {
        id: diskRow

        property string diskName
        property real used
        property real total
        property real percentage
        property color diskColor: Colours.palette.m3primary

        property real animatedPercentage: 0
        property bool hovered: false

        implicitHeight: rowLayout.implicitHeight

        Component.onCompleted: animatedPercentage = percentage
        onPercentageChanged: animatedPercentage = percentage
        Behavior on animatedPercentage {
            Anim { duration: Appearance.anim.durations.large }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: diskRow.hovered = true
            onExited: diskRow.hovered = false
        }

        RowLayout {
            id: rowLayout
            anchors.fill: parent
            spacing: Appearance.spacing.normal

            // Disk color indicator
            Rectangle {
                width: 4
                Layout.fillHeight: true
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                radius: 2
                color: diskRow.diskColor
            }

            // Disk name
            StyledText {
                text: diskRow.diskName
                font.pointSize: Appearance.font.size.small
                Layout.preferredWidth: 80
            }

            // Progress bar - fills most of the space
            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 4
                Layout.bottomMargin: 4

                color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                radius: Appearance.rounding.full

                StyledRect {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * diskRow.animatedPercentage

                    color: diskRow.diskColor
                    radius: Appearance.rounding.full
                }
            }

            // Percentage / Usage info (morphs on hover)
            Item {
                Layout.preferredWidth: usageText.visible ? usageText.implicitWidth : percentText.implicitWidth
                Layout.minimumWidth: 35
                implicitHeight: Math.max(percentText.implicitHeight, usageText.implicitHeight)

                Behavior on Layout.preferredWidth {
                    Anim { duration: Appearance.anim.durations.normal }
                }

                // Percentage (shown when not hovered)
                StyledText {
                    id: percentText
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !diskRow.hovered
                    text: `${Math.round(diskRow.percentage * 100)}%`
                    font.pointSize: Appearance.font.size.small
                    font.weight: Font.Medium
                    color: diskRow.diskColor
                    horizontalAlignment: Text.AlignRight

                    opacity: diskRow.hovered ? 0 : 1
                    Behavior on opacity {
                        Anim { duration: Appearance.anim.durations.normal }
                    }
                }

                // Usage/Total (shown on hover)
                StyledText {
                    id: usageText
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: diskRow.hovered
                    text: {
                        const usedFmt = SystemUsage.formatKib(diskRow.used);
                        const totalFmt = SystemUsage.formatKib(diskRow.total);
                        return `${usedFmt.value.toFixed(0)}/${totalFmt.value.toFixed(0)}${totalFmt.unit}`;
                    }
                    font.pointSize: Appearance.font.size.smaller
                    color: Colours.palette.m3onSurfaceVariant
                    horizontalAlignment: Text.AlignRight

                    opacity: diskRow.hovered ? 1 : 0
                    Behavior on opacity {
                        Anim { duration: Appearance.anim.durations.normal }
                    }
                }
            }
        }
    }
}
