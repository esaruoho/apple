use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "&gt; &lt; &amp; &quot; &apos;"
set theResult to current application's SMSForder's unencodedForXMLFrom:aString
ASify from theResult
-->	"> < & \" '"
theResult as text
-->	"> < & \" '"
