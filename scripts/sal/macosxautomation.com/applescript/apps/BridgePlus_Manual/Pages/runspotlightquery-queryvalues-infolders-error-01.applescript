use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's runSpotlightQuery:"kMDItemContentCreationDate > %@" queryValues:{(current date) - 10 * days} inFolders:{(path to desktop)} |error|:(missing value)
ASify from theResult
-->	<list of image files on desktop, searching recursively>
theResult as list
-->	<list of image files on desktop, searching recursively>

set {theResult, theError} to current application's SMSForder's runSpotlightQuery:"kMDItemContentCreationDate > %@" queryValues:{} inFolders:{(path to desktop)} |error|:(reference)
if theResult = missing value then error (theError's localizedDescription() as text)
-->	error number -10000  Insufficient arguments for conversion characters specified in format string.
