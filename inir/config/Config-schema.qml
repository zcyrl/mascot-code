// Add this inside the `mascot` JsonObject in modules/common/Config.qml.
// The defaults are duplicated in defaults/config.json so fresh installs and
// existing configs agree.
property JsonObject codingCompanion: JsonObject {
    property bool enable: false
    // "empo" (default) or "claude"
    property string character: "empo"
}
