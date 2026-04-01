use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's availableInputSourceIDs()
ASify from theResult
-->	{"com.apple.keylayout.US", "com.apple.keylayout.Australian", "com.apple.keylayout.USInternational-PC", "com.apple.CharacterPaletteIM", "com.apple.KeyboardViewer", "com.apple.keylayout.UnicodeHexInput", "com.apple.inputmethod.ironwood", "com.apple.PressAndHold"}
theResult as list
-->	{"com.apple.keylayout.US", "com.apple.keylayout.Australian", "com.apple.keylayout.USInternational-PC", "com.apple.CharacterPaletteIM", "com.apple.KeyboardViewer", "com.apple.keylayout.UnicodeHexInput", "com.apple.inputmethod.ironwood", "com.apple.PressAndHold"}
