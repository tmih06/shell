import qs.components
import qs.components.misc
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

GridLayout {
    id: root

    // Card sizing constants
    readonly property int unitWidth: 160  // Bigger base unit for grid
    readonly property int cardHeight: 190  // Taller cards
    readonly property int memorySize: 180  // Square, bigger

    // CPU and GPU are 2 units wide, Memory is ~1.3 units, Storage is ~2.7 units
    columns: 4
    rowSpacing: Appearance.spacing.normal
    columnSpacing: Appearance.spacing.normal

    function displayTemp(temp: real): string {
        return `${Math.ceil(Config.services.useFahrenheit ? temp * 1.8 + 32 : temp)}°${Config.services.useFahrenheit ? "F" : "C"}`;
    }

    Ref {
        service: SystemUsage
    }

    // CPU Card (Row 0, Col 0-1) - spans 2 columns
    ResourceCard {
        Layout.row: 0
        Layout.column: 0
        Layout.columnSpan: 2
        Layout.preferredWidth: root.unitWidth * 2 + root.columnSpacing
        Layout.preferredHeight: root.cardHeight

        visible: Config.dashboard.performance.showCpu

        icon: "memory"
        title: SystemUsage.cpuName || qsTr("CPU")

        model: [
            {
                value: SystemUsage.cpuPerc,
                maxValue: 1,
                displayValue: `${Math.round(SystemUsage.cpuPerc * 100)}%`,
                label: qsTr("Usage"),
                color: Colours.palette.m3primary
            },
            {
                value: SystemUsage.cpuTemp,
                maxValue: 90,
                displayValue: root.displayTemp(SystemUsage.cpuTemp),
                label: qsTr("Temperature"),
                color: Colours.palette.m3secondary
            }
        ]
    }

    // GPU Card (Row 0, Col 2-3) - spans 2 columns
    ResourceCard {
        Layout.row: 0
        Layout.column: 2
        Layout.columnSpan: 2
        Layout.preferredWidth: root.unitWidth * 2 + root.columnSpacing
        Layout.preferredHeight: root.cardHeight

        visible: Config.dashboard.performance.showGpu

        icon: "display_settings"
        title: SystemUsage.gpuName || qsTr("GPU")

        model: [
            {
                value: SystemUsage.gpuPerc,
                maxValue: 1,
                displayValue: `${Math.round(SystemUsage.gpuPerc * 100)}%`,
                label: qsTr("Usage"),
                color: Colours.palette.m3primary
            },
            {
                value: SystemUsage.gpuTemp,
                maxValue: 90,
                displayValue: root.displayTemp(SystemUsage.gpuTemp),
                label: qsTr("Temperature"),
                color: Colours.palette.m3secondary
            }
        ]
    }

    // Memory Card (Row 1, Col 0) - spans 1 column, square
    MemoryCard {
        Layout.row: 1
        Layout.column: 0
        Layout.columnSpan: 1
        Layout.preferredWidth: root.memorySize
        Layout.preferredHeight: root.memorySize

        visible: Config.dashboard.performance.showMemory
    }

    // Storage Card (Row 1, Col 1-3) - spans 3 columns
    StorageCard {
        Layout.row: 1
        Layout.column: 1
        Layout.columnSpan: 3
        Layout.fillWidth: true
        Layout.preferredHeight: root.memorySize

        visible: Config.dashboard.performance.showStorage
    }

    // ============================================
    // Components
    // ============================================

    component ResourceCard: StyledRect {
        id: card

        property string icon
        property string title
        property var model: []

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.large

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            anchors.bottomMargin: Appearance.padding.large + Appearance.padding.normal  // Extra bottom padding
            spacing: Appearance.spacing.small

            // Header: Icon + Title
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                MaterialIcon {
                    text: card.icon
                    fill: 1
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: card.title
                    font.pointSize: Appearance.font.size.normal
                    elide: Text.ElideRight
                }
            }

            // Spacer
            Item {
                Layout.fillHeight: true
            }

            // Indicators
            Repeater {
                model: card.model

                delegate: HorizontalIndicator {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true

                    value: modelData.value
                    maxValue: modelData.maxValue
                    displayValue: modelData.displayValue
                    label: modelData.label
                    barColor: modelData.color
                }
            }
        }
    }

    component MemoryCard: StyledRect {
        id: memCard

        property real displayedPercentage: 0

        // Arc configuration: 3/4 circle (270 degrees)
        // Gap at the bottom, starts from bottom-left, ends at bottom-right
        readonly property real arcStartAngle: 0.75 * Math.PI   // 135 degrees (bottom-left)
        readonly property real arcSweep: 1.5 * Math.PI         // 270 degrees sweep

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.large

        Component.onCompleted: displayedPercentage = SystemUsage.memPerc

        Connections {
            target: SystemUsage
            function onMemPercChanged() {
                memCard.displayedPercentage = SystemUsage.memPerc;
            }
        }

        Behavior on displayedPercentage {
            Anim {
                duration: Appearance.anim.durations.large
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: 0

            // Header: Icon + Title
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                MaterialIcon {
                    text: "memory_alt"
                    fill: 1
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Memory")
                    font.pointSize: Appearance.font.size.normal
                }
            }

            // Circular progress indicator (3/4 arc) with percentage only in center
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Circular progress - 3/4 arc
                Canvas {
                    id: memCanvas

                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();

                        const cx = width / 2;
                        const cy = height / 2;
                        const radius = (Math.min(width, height) - 14) / 2;
                        const lineWidth = 8;

                        // Background arc (3/4 circle)
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, memCard.arcStartAngle, memCard.arcStartAngle + memCard.arcSweep);
                        ctx.lineWidth = lineWidth;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = Colours.layer(Colours.palette.m3surfaceContainerHigh, 2);
                        ctx.stroke();

                        // Progress arc
                        if (memCard.displayedPercentage > 0) {
                            ctx.beginPath();
                            ctx.arc(cx, cy, radius, memCard.arcStartAngle, memCard.arcStartAngle + memCard.arcSweep * memCard.displayedPercentage);
                            ctx.lineWidth = lineWidth;
                            ctx.lineCap = "round";
                            ctx.strokeStyle = Colours.palette.m3primary;
                            ctx.stroke();
                        }
                    }

                    Connections {
                        target: memCard
                        function onDisplayedPercentageChanged() {
                            memCanvas.requestPaint();
                        }
                    }

                    Component.onCompleted: requestPaint()
                }

                // Center text - percentage only
                StyledText {
                    anchors.centerIn: parent
                    text: `${Math.round(SystemUsage.memPerc * 100)}%`
                    font.pointSize: Appearance.font.size.large
                    font.weight: Font.Medium
                }
            }

            // Used/Total at the bottom
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    const usedFmt = SystemUsage.formatKib(SystemUsage.memUsed);
                    const totalFmt = SystemUsage.formatKib(SystemUsage.memTotal);
                    return `${usedFmt.value.toFixed(1)} / ${Math.floor(totalFmt.value)} ${totalFmt.unit}`;
                }
                font.pointSize: Appearance.font.size.smaller
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    component StorageCard: StyledRect {
        id: storageCard

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.large

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.small

            // Header: Icon + Title
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                MaterialIcon {
                    text: "hard_disk"
                    fill: 1
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Storage")
                    font.pointSize: Appearance.font.size.normal
                }
            }

            // Disk indicators - row by row
            Repeater {
                model: SystemUsage.disks.slice(0, 4)

                delegate: DiskIndicator {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true

                    mount: modelData.mount
                    used: modelData.used
                    total: modelData.total
                    percentage: modelData.perc
                }
            }

            // Fill remaining space at bottom
            Item {
                Layout.fillHeight: true
            }
        }
    }

    component HorizontalIndicator: ColumnLayout {
        id: indicator

        property real value
        property real maxValue
        property string displayValue
        property string label
        property color barColor: Colours.palette.m3primary

        // Internal animated value to prevent flicker on recreation
        property real animatedValue: 0

        spacing: Appearance.spacing.smaller

        // Animate value changes smoothly without resetting
        Behavior on animatedValue {
            Anim {
                duration: Appearance.anim.durations.large
            }
        }

        // Update animated value when actual value changes
        onValueChanged: animatedValue = value
        Component.onCompleted: animatedValue = value

        // Label on top with value on right
        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: indicator.label
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.smaller
            }

            Item { Layout.fillWidth: true }

            StyledText {
                text: indicator.displayValue
                font.pointSize: Appearance.font.size.smaller
            }
        }

        // Progress bar
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: Config.dashboard.sizes.resourceProgessThickness

            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
            radius: Appearance.rounding.full

            StyledRect {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Math.min(1, indicator.maxValue > 0 ? indicator.animatedValue / indicator.maxValue : 0)

                color: indicator.barColor
                radius: Appearance.rounding.full
            }
        }
    }

    component DiskIndicator: RowLayout {
        id: diskInd

        property string mount
        property real used
        property real total
        property real percentage
        property int barWidth: 180  // Longer default bar width

        // Internal animated value to prevent flicker
        property real animatedPercentage: 0

        onPercentageChanged: animatedPercentage = percentage
        Component.onCompleted: animatedPercentage = percentage

        Behavior on animatedPercentage {
            Anim {
                duration: Appearance.anim.durations.large
            }
        }

        spacing: Appearance.spacing.normal

        // Disk name label - wider to fit nvme0n1
        StyledText {
            text: diskInd.mount
            font.pointSize: Appearance.font.size.smaller
            Layout.preferredWidth: 85
            elide: Text.ElideMiddle
        }

        // Progress bar - fills available space
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: Config.dashboard.sizes.resourceProgessThickness

            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
            radius: Appearance.rounding.full

            StyledRect {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Math.min(1, diskInd.animatedPercentage)

                color: Colours.palette.m3primary
                radius: Appearance.rounding.full
            }
        }

        // Size info - compact
        StyledText {
            text: {
                const usedFmt = SystemUsage.formatKib(diskInd.used);
                const totalFmt = SystemUsage.formatKib(diskInd.total);
                return `${usedFmt.value.toFixed(0)}/${totalFmt.value.toFixed(0)}${totalFmt.unit}`;
            }
            font.pointSize: Appearance.font.size.smaller
            color: Colours.palette.m3onSurfaceVariant
            Layout.preferredWidth: 90
        }

        // Percentage
        StyledText {
            text: `${Math.round(diskInd.percentage * 100)}%`
            font.pointSize: Appearance.font.size.smaller
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 35
        }
    }
}
