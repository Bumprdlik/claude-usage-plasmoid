// Claude Usage — shows Claude plan usage written by ~/.local/bin/claude-statusline
// into ~/.cache/claude-usage.json (refreshed on every Claude Code reply).
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property var usage: null
    property real now: Date.now() / 1000
    readonly property string readCmd: "cat \"$HOME/.cache/claude-usage.json\""

    // A window that has passed its reset time counts as 0 %.
    function pctOf(name) {
        var w = usage ? usage[name] : null
        if (!w || (w.resets_at && w.resets_at < now)) return 0
        return Math.max(0, Math.min(100, w.used_percentage || 0))
    }
    function resetOf(name) {
        var w = usage ? usage[name] : null
        if (!w || !w.resets_at || w.resets_at < now) return 0
        return w.resets_at
    }

    readonly property real sessionPct: pctOf("five_hour")
    readonly property real weekPct: pctOf("seven_day")
    readonly property real sessionReset: resetOf("five_hour")
    readonly property real weekReset: resetOf("seven_day")
    readonly property real age: usage && usage.updated ? now - usage.updated : -1
    readonly property bool stale: age < 0 || age > 3600

    function barColor(p) {
        if (p >= 95) return Kirigami.Theme.negativeTextColor
        if (p >= 80) return Kirigami.Theme.neutralTextColor
        return Kirigami.Theme.highlightColor
    }
    function fmtPct(p) { return Math.round(p) + "%" }
    function fmtReset(ts, withDay) {
        if (!ts) return "—"
        var d = new Date(ts * 1000)
        return "Resets " + Qt.locale("en_GB").toString(d, withDay ? "dddd HH:mm" : "HH:mm")
    }
    function fmtAge(s) {
        if (s < 0) return "No data yet"
        if (s < 90) return "Updated just now"
        if (s < 5400) return "Updated " + Math.round(s / 60) + " min ago"
        if (s < 172800) return "Updated " + Math.round(s / 3600) + " h ago"
        return "Updated " + Math.round(s / 86400) + " days ago"
    }

    toolTipMainText: "Claude"
    toolTipSubText: usage
        ? "Session: " + fmtPct(sessionPct) + " · week: " + fmtPct(weekPct) + "\n" + fmtAge(age)
        : "No data yet — use Claude Code"

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: function (source, data) {
            disconnectSource(source)
            if (data["exit code"] === 0) {
                try { root.usage = JSON.parse(data["stdout"]) } catch (e) { }
            } else {
                root.usage = null
            }
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.now = Date.now() / 1000
            exec.connectSource(root.readCmd)
        }
    }

    component Bar: Rectangle {
        property real pct: 0
        implicitHeight: Math.max(3, Math.round(Kirigami.Units.smallSpacing * 1.2))
        radius: height / 2
        color: Qt.alpha(Kirigami.Theme.textColor, 0.15)
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: parent.width * parent.pct / 100
            radius: parent.radius
            color: root.barColor(parent.pct)
        }
    }

    component MiniRow: ColumnLayout {
        property string label
        property real pct
        spacing: 1
        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label {
                text: label
                font: Kirigami.Theme.smallFont
                opacity: 0.7
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents.Label {
                text: root.usage ? root.fmtPct(pct) : "–"
                font: Kirigami.Theme.smallFont
            }
        }
        Bar { Layout.fillWidth: true; pct: parent.pct }
    }

    component BigRow: RowLayout {
        property string title
        property string sub
        property real pct
        spacing: Kirigami.Units.largeSpacing
        ColumnLayout {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
            spacing: 0
            PlasmaComponents.Label { text: title }
            PlasmaComponents.Label { text: sub; font: Kirigami.Theme.smallFont; opacity: 0.6 }
        }
        Bar { Layout.fillWidth: true; pct: parent.pct }
        PlasmaComponents.Label {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            horizontalAlignment: Text.AlignRight
            text: root.fmtPct(pct) + " used"
            opacity: 0.7
        }
    }

    compactRepresentation: MouseArea {
        readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        Layout.minimumHeight: vertical ? col.implicitHeight + 2 * Kirigami.Units.smallSpacing : -1
        Layout.preferredHeight: Layout.minimumHeight
        Layout.minimumWidth: vertical ? -1 : Kirigami.Units.gridUnit * 5
        Layout.preferredWidth: Layout.minimumWidth
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
        opacity: root.stale ? 0.55 : 1

        ColumnLayout {
            id: col
            anchors {
                left: parent.left; right: parent.right
                verticalCenter: parent.verticalCenter
                margins: Kirigami.Units.smallSpacing
            }
            spacing: Kirigami.Units.smallSpacing
            MiniRow { Layout.fillWidth: true; label: "5h"; pct: root.sessionPct }
            MiniRow { Layout.fillWidth: true; label: "week"; pct: root.weekPct }
        }
    }

    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 26
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Heading { text: "Claude usage"; level: 4 }
        BigRow {
            Layout.fillWidth: true
            title: "Current session"
            sub: root.fmtReset(root.sessionReset, false)
            pct: root.sessionPct
        }
        BigRow {
            Layout.fillWidth: true
            title: "This week"
            sub: root.fmtReset(root.weekReset, true)
            pct: root.weekPct
        }
        PlasmaComponents.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
            opacity: 0.6
            text: root.fmtAge(root.age) + ". Refreshed on every Claude Code reply."
        }
    }
}
