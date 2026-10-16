// Fennek OS update for existing desktops (once per user): the panel theme moves to Fennek Dark (Breeze Dark plus
// Fennek's taskbar buttons). Only if the panel style is still one Fennek set, never over the user's own choice.
var theme = ConfigFile("plasmarc", "Theme")
var name = theme.readEntry("name")
if (name === "" || name === "default" || name === "breeze-dark") {
    theme.writeEntry("name", "fennek-dark")
}
