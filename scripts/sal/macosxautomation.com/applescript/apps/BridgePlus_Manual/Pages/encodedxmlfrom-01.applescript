use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set aString to "> < & \" '"
set theResult to current application's SMSForder's encodedXMLFrom:aString
ASify from theResult
-->	"&gt; &lt; &amp; &quot; &apos;"
theResult as text
-->	"&gt; &lt; &amp; &quot; &apos;"
