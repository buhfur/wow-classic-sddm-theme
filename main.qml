import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import Qt.labs.folderlistmodel 2.1
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "black"

    // ---- config ----
    function cfg(section, key, def) {
        return (typeof sddm !== "undefined" && sddm.readConfig)
               ? sddm.readConfig(section, key, def) : def;
    }
    property string bgPath: cfg("General", "background", "assets/background.png")

    // ---- scale (reference 1920x1080) ----
    readonly property real uiScale: Math.min(width/1920, height/1080)

    // sizes
    readonly property real fieldW: 270 * uiScale
    readonly property real fieldH: 38  * uiScale   // taller fields
    readonly property real btnW  : fieldW
    readonly property real btnH  : fieldH          // button matches field height
    readonly property real gapY  : 10  * uiScale

    // Palette
    readonly property color goldRim    : "#C6A664"
    readonly property color labelGold  : "#FFD13A"
    readonly property color darkStroke : "#2A2014"
    readonly property color cavTop     : "#6B563C"
    readonly property color cavBot     : "#3A2B1E"
    readonly property color redTop     : "#C61A1A"
    readonly property color redBot     : "#8B0F0F"
    readonly property color glossTop   : "#FFF3A0"

    // Font
    FontLoader { id: frizFont; source: "file:///usr/share/fonts/truetype/friz/FrizQuadrata.ttf" }
    function friz() { return frizFont.name && frizFont.name.length ? frizFont.name : "DejaVu Serif"; }

    // ---------- FALLBACK SESSION SCAN ----------
    // If sddm.sessionsModel is empty in test-mode, scan /usr/share/xsessions and wayland-sessions.
    property var  fallbackSessions: []              // array of {name:string, file:string}
    property bool fallbackReady: false

    // helper: parse Name or Name[locale] from .desktop content
    function parseDesktopName(text) {
        if (!text) return "";
        var loc = Qt.locale().name; // e.g. en_US
        var reLoc = new RegExp("^Name\\[" + loc.replace("-", "_") + "\\]\\s*=\\s*(.+)$", "m");
        var m = text.match(reLoc);
        if (m && m[1]) return m[1].trim();
        var m2 = text.match(/^Name\s*=\s*(.+)$/m);
        return (m2 && m2[1]) ? m2[1].trim() : "";
    }

    // Reads one file synchronously
    function readFileSync(fileUrl) {
        try {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", fileUrl, false); // sync
            xhr.send();
            if (xhr.status === 0 || (xhr.status >= 200 && xhr.status < 300)) {
                return xhr.responseText;
            }
        } catch (e) {}
        return "";
    }

    // Build fallback list once folder models are ready
    function buildFallback() {
        var arr = [];
        function pushFromFolder(model) {
            for (var i = 0; i < model.count; ++i) {
                var path = model.get(i, "filePath");     // absolute path
                var url  = "file://" + path;
                var content = readFileSync(url);
                var nm = parseDesktopName(content);
                if (nm && path.endsWith(".desktop")) {
                    arr.push({ name: nm, file: path });
                }
            }
        }
        pushFromFolder(xSessions);
        pushFromFolder(wSessions);
        arr.sort(function(a,b){ return a.name.localeCompare(b.name); });
        fallbackSessions = arr;
        fallbackReady = true;
    }

    FolderListModel {
        id: xSessions
        folder: "file:///usr/share/xsessions"
        nameFilters: [ "*.desktop" ]
        showDirs: false
        // Use countChanged (statusChanged may not exist in your Qt build)
        onCountChanged: fallbackTimer.restart()
    }
    FolderListModel {
        id: wSessions
        folder: "file:///usr/share/wayland-sessions"
        nameFilters: [ "*.desktop" ]
        showDirs: false
        onCountChanged: fallbackTimer.restart()
    }
    Timer {
        id: fallbackTimer
        interval: 50; repeat: false
        onTriggered: buildFallback()
    }

    /* ===================== PRIMITIVES ===================== */

    // Field: capsule dark stroke -> gold rim -> warm-brown cavity
    Component {
        id: wowField
        Item {
            id: fld
            width: fieldW; height: fieldH
            property string placeholder: ""
            property bool password: false
            property alias text: ti.text
            signal accepted()
            clip: true

            Rectangle { anchors.fill: parent; radius: height/2; color: darkStroke }
            Rectangle { anchors.fill: parent; anchors.margins: 1*uiScale; radius: (height - 2*uiScale)/2; color: goldRim }

            Rectangle { // cavity
                id: cavity
                anchors.fill: parent; anchors.margins: 3*uiScale
                radius: (height - 6*uiScale)/2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: cavTop }
                    GradientStop { position: 1.0; color: cavBot }
                }
                border.color: "#000"; border.width: 1
                clip: true
            }

            TextInput {
                id: ti
                anchors.fill: cavity
                anchors.leftMargin: 12*uiScale; anchors.rightMargin: 12*uiScale
                anchors.topMargin: 6*uiScale;  anchors.bottomMargin: 6*uiScale
                color: "#F2F2F2"
                echoMode: fld.password ? TextInput.Password : TextInput.Normal
                font.pixelSize: Math.max(14, 15*uiScale)     // keep current input font size
                font.family: friz()
                clip: true
                Keys.onReturnPressed: fld.accepted()
            }
            Text { // placeholder
                text: fld.placeholder
                color: "#E6D7A8"
                anchors.fill: cavity; leftPadding: 12*uiScale
                verticalAlignment: Text.AlignVCenter
                visible: ti.text.length === 0 && !ti.activeFocus
                font.pixelSize: Math.max(12, 13*uiScale)
                font.family: friz()
            }
        }
    }

    // Button: capsule dark stroke -> gold rim -> red body + soft top gloss
    Component {
        id: wowButton
        Item {
            id: btn
            width: btnW; height: btnH
            property alias text: label.text
            signal clicked()
            clip: true

            Rectangle { anchors.fill: parent; radius: height/2; color: darkStroke }
            Rectangle { anchors.fill: parent; anchors.margins: 1*uiScale; radius: (height - 2*uiScale)/2; color: goldRim }

            Rectangle {
                id: body
                anchors.fill: parent; anchors.margins: 3*uiScale
                radius: (height - 6*uiScale)/2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: redTop }
                    GradientStop { position: 1.0; color: redBot }
                }
                border.color: "#2C0A0A"; border.width: 1
                clip: true
            }

            Rectangle { // top gloss/lip
                anchors.left: body.left; anchors.right: body.right; anchors.top: body.top
                height: Math.max(4, Math.round(body.height * 0.38))
                radius: body.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: glossTop }
                    GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0) }
                }
                opacity: 0.88
                clip: true
            }

            Text {
                id: label
                anchors.centerIn: body
                color: "#FFF2C5"
                text: "Login"
                font.bold: true
                font.pixelSize: Math.max(13, 14*uiScale)   // keep current label size
                font.family: friz()
            }

            MouseArea { anchors.fill: parent; onClicked: btn.clicked() }
        }
    }

    /* ===================== SESSION DROPDOWN (TOP-RIGHT) ===================== */
    Component {
        id: wowSessionDropdown
        Item {
            id: box
            width: 240*uiScale; height: 30*uiScale
            clip: false

            // current label & selection
            property string faceText: "Session"
            property int index: (typeof sddm !== "undefined" && sddm.session !== undefined) ? sddm.session : 0
            readonly property real rowH: Math.max(28*uiScale, 28)
            readonly property bool hasSddmModel: (typeof sddm !== "undefined" && sddm.sessionsModel && sddm.sessionsModel.count > 0)
            readonly property bool useFallback: !hasSddmModel && fallbackReady && fallbackSessions.length > 0

            Component.onCompleted: {
                if (hasSddmModel) {
                    index = Math.max(0, Math.min(sddm.sessionsModel.count-1, index));
                    var it = sddm.sessionsModel.get(index);
                    if (it && it.name) faceText = it.name;
                } else if (useFallback) {
                    index = Math.min(index, fallbackSessions.length - 1);
                    faceText = fallbackSessions.length ? fallbackSessions[index].name : "Session";
                }
            }

            // closed face
            Rectangle { anchors.fill: parent; radius: height/2; color: darkStroke }
            Rectangle { anchors.fill: parent; anchors.margins: 1*uiScale; radius: (height - 2*uiScale)/2; color: goldRim }
            Rectangle {
                id: face
                anchors.fill: parent; anchors.margins: 3*uiScale
                radius: (height - 6*uiScale)/2
                color: "#E7E7E7"
                border.color: "#000"
                border.width: 1
            }

            Text {
                id: faceLabel
                text: faceText
                color: "#111"
                font.pixelSize: Math.max(11, 12*uiScale)
                elide: Text.ElideRight
                anchors.left: face.left
                anchors.leftMargin: 8*uiScale
                anchors.verticalCenter: face.verticalCenter
                anchors.right: arrow.left
                anchors.rightMargin: 8*uiScale
            }
            Text {
                id: arrow
                text: menu.visible ? "▲" : "▼"
                color: "#333"
                font.pixelSize: Math.max(10, 12*uiScale)
                anchors.right: face.right
                anchors.rightMargin: 8*uiScale
                anchors.verticalCenter: face.verticalCenter
            }

            MouseArea { anchors.fill: parent; onClicked: menu.visible = !menu.visible }

            // popup menu (works with sddm model OR fallback list)
            Rectangle {
                id: menu
                visible: false
                z: 2000
                width: box.width
                radius: 6*uiScale
                color: "#E7E7E7"
                border.color: "#000"
                border.width: 1
                anchors.top: box.bottom
                anchors.right: box.right
                anchors.topMargin: 6*uiScale
                clip: true
                layer.enabled: true

                // dynamic height from content
                height: Math.min(300*uiScale, Math.max(rowH, contentCol.implicitHeight) + 8*uiScale)

                Rectangle { anchors.left: parent.left; anchors.right: parent.right; height: 2; color: goldRim }

                Flickable {
                    id: scroll
                    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; topMargin: 2 }
                    contentWidth: parent.width
                    contentHeight: contentCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: contentCol
                        width: parent.width
                        spacing: 0

                        // Placeholder if nothing at all
                        Item {
                            width: parent.width
                            height: (!hasSddmModel && !useFallback) ? rowH : 0
                            visible: height > 0
                            Text {
                                text: "No desktop sessions found"
                                color: "#444"
                                font.italic: true
                                font.pixelSize: Math.max(11, 12*uiScale)
                                anchors.centerIn: parent
                            }
                        }

                        // SDDM model entries (preferred)
                        Repeater {
                            model: hasSddmModel ? sddm.sessionsModel : 0
                            delegate: Rectangle {
                                width: contentCol.width
                                height: rowH
                                color: (index === box.index) ? "#dcdcdc" : "transparent"
                                border.color: "#00000011"; border.width: 1

                                Text {
                                    text: (typeof name !== "undefined") ? name
                                          : (typeof model !== "undefined" && model.name !== undefined) ? model.name
                                          : (modelData !== undefined ? modelData : "Session")
                                    color: "#111"
                                    font.pixelSize: Math.max(11, 12*uiScale)
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8*uiScale
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8*uiScale
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        box.index = index;
                                        box.faceText = (typeof name !== "undefined") ? name
                                                     : (typeof model !== "undefined" && model.name !== undefined) ? model.name
                                                     : (modelData !== undefined ? modelData : box.faceText);
                                        if (typeof sddm !== "undefined") sddm.session = box.index;
                                        menu.visible = false;
                                    }
                                }
                            }
                        }

                        // Fallback entries from filesystem scan
                        Repeater {
                            model: useFallback ? fallbackSessions.length : 0
                            delegate: Rectangle {
                                width: contentCol.width
                                height: rowH
                                color: (index === box.index) ? "#dcdcdc" : "transparent"
                                border.color: "#00000011"; border.width: 1

                                property string itemName: fallbackSessions[index].name

                                Text {
                                    text: itemName
                                    color: "#111"
                                    font.pixelSize: Math.max(11, 12*uiScale)
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8*uiScale
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8*uiScale
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        box.index = index;
                                        box.faceText = itemName;
                                        // In fallback (test-mode), we don't set sddm.session,
                                        // but the real greeter will use sddm model anyway.
                                        menu.visible = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- background ----
    Image {
        id: bg
        anchors.fill: parent
        source: Qt.resolvedUrl(bgPath)
        fillMode: Image.PreserveAspectCrop
        smooth: true
        cache: true
    }

    /* ===================== CENTER STACK ===================== */
    Column {
        id: stack
        spacing: gapY
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 188 * uiScale

        // Labels — WoW yellow with outline and tracking
        Text {
            width: fieldW; horizontalAlignment: Text.AlignHCenter
            text: "Account Name"
            color: labelGold
            style: Text.Outline; styleColor: "#000000"
            font.pixelSize: Math.max(16, 17*uiScale)
            font.bold: true
            font.family: friz()
            font.letterSpacing: 1.6 * uiScale
        }
        Loader { id: userField; sourceComponent: wowField; onLoaded: { item.placeholder = "name" } }

        Text {
            width: fieldW; horizontalAlignment: Text.AlignHCenter
            text: "Account Password"
            color: labelGold
            style: Text.Outline; styleColor: "#000000"
            font.pixelSize: Math.max(16, 17*uiScale)
            font.bold: true
            font.family: friz()
            font.letterSpacing: 1.6 * uiScale
        }
        Loader {
            id: passField
            sourceComponent: wowField
            onLoaded: { item.placeholder = "Password"; item.password = true; item.accepted.connect(function(){ loginNow(); }) }
        }

        Loader {
            id: loginButton
            anchors.horizontalCenter: parent.horizontalCenter
            sourceComponent: wowButton
            onLoaded: { item.text = "Login"; item.clicked.connect(function(){ loginNow(); }) }
        }
    }

    /* ===================== SESSION DROPDOWN ABOVE ALL ===================== */
    Loader {
        id: sessionBox
        z: 1000                        // render above center stack
        sourceComponent: wowSessionDropdown
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 24*uiScale
        anchors.rightMargin: 28*uiScale
    }

    // ---- login helpers ----
    function loginNow() {
        var u  = userField.item ? userField.item.text : ""
        var p  = passField.item ? passField.item.text : ""
        var si = (typeof sddm !== "undefined" && sessionBox.item) ? sessionBox.item.index : 0
        if (typeof sddm !== "undefined") sddm.login(u, p, si)
    }
    Connections {
        target: (typeof sddm !== "undefined") ? sddm : null
        function onLoginFailed() { /* optional error text */ }
    }
}

