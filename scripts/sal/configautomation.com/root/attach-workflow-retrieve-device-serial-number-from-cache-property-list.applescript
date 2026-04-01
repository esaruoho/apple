use framework "Foundation"
use scripting additions

set thisECID to (do shell script "echo $ECID") as string
set aPath to (the POSIX path of (path to "cach" from user domain)) & "com.apple.configurator.AttachedDevices/" & thisECID & ".plist"
set aDictionary to current application's class "NSDictionary"'s dictionaryWithContentsOfFile:aPath
set serialNumber to (aDictionary's valueForKey:"serialNumber") as text
