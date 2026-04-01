use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's currentKeyboardLayoutInputSourceID()
ASify from theResult
-->	"com.apple.keylayout.Australian"
theResult as text
-->	"com.apple.keylayout.Australian"
