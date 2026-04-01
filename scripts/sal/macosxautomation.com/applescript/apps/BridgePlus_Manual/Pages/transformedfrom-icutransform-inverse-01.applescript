use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "Takaaki Naganoya"
set theResult to current application's SMSForder's transformedFrom:aString ICUTransform:"Latin-Katakana" inverse:false
ASify from theResult
-->	"タカアキ ナガノヤ"
theResult as text
-->	"タカアキ ナガノヤ"

set theResult to current application's SMSForder's transformedFrom:(words of aString) ICUTransform:"Latin-Katakana" inverse:false
ASify from theResult
-->	{"タカアキ", "ナガノヤ"}
theResult as list
-->	{"タカアキ", "ナガノヤ"}
