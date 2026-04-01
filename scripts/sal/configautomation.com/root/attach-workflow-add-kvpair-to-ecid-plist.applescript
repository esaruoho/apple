use framework "Foundation"
use scripting additions

set aKey to "favorite color"
set aValue to "blue"

set thisECID to (do shell script "echo $ECID") as string
set aPath to (the POSIX path of (path to "cach" from user domain)) & "com.apple.configurator.AttachedDevices/" & thisECID & ".plist"
set aDictionary to current application's class "NSMutableDictionary"'s dictionaryWithContentsOfFile:aPath
aDictionary's setObject:aValue forKey:aKey
aDictionary's writeToFile:aPath atomically:true
