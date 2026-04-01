on sortListOfStrings(sourceList)
	-- sorts a passed AppleScript list of strings
	-- DOCUMENTATION: https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSArray_Class/NSArray.html#//apple_ref/doc/uid/TP40003620
	
	-- create a Cocoa array from the passed AppleScript list
	set the CocoaArray to current application's NSArray's arrayWithArray_(sourceList)
	-- sort the Cocoa array
	set the sortedItems to CocoaArray's sortedArrayUsingSelector_("localizedStandardCompare:")
	-- return the Cocoa array coerced to an AppleScript list
	return (sortedItems as list)
end sortListOfStrings
