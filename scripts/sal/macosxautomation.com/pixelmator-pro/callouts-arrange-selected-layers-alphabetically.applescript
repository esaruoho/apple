use AppleScript version "2.4" -- Yosemite (10.10) or later
use framework "Foundation"
use scripting additions

tell application "Pixelmator Pro 3"
	activate
	try
		if not (exists document 1) then error number -128
		tell front document
			set selectedLayers to the selected layers of it
			if selectedLayers is {} then error "Please select the layers to rearrange by name."
			set layerNames to {}
			repeat with i from 1 to the count of selectedLayers
				set the end of layerNames to the name of item i of selectedLayers
			end repeat
			set sortedLayerNames to my sortListOfStrings(layerNames)
			set sortedLayerNames to the reverse of sortedLayerNames
			repeat with i from 1 to the count of sortedLayerNames
				set thisLayerName to item i of sortedLayerNames
				set thisLayer to layer thisLayerName
				move thisLayer to before layer 1
			end repeat
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert (errorNumber as string) message errorMessage
		end if
	end try
end tell

on sortListOfStrings(sourceList)
	-- sorts a passed AppleScript list of strings
	-- DOCUMENTATION: https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSArray_Class/NSArray.html#//apple_ref/doc/uid/TP40003620
	-- create a Cocoa array from the passed AppleScript list
	set the CocoaArray to current application's NSArray's arrayWithArray:sourceList
	-- sort the Cocoa array
	set the sortedItems to CocoaArray's sortedArrayUsingSelector:"localizedStandardCompare:"
	-- return the Cocoa array coerced to an AppleScript list
	return (sortedItems as list)
end sortListOfStrings
