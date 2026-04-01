on listToStringUsingTextItemDelimiter(sourceList, textItemDelimiter)
	-- creates a string from a passed AppleScript list of strings using a passed delimiter string
	-- DOCUMENTATION: https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSArray_Class/NSArray.html#//apple_ref/doc/uid/TP40003620
	
	-- convert AppleScript list into Cocoa array
	set the CocoaArray to current application's NSArray's arrayWithArray_(sourceList)
	-- create a Cocoa string from the Cocoa array using the passed delimiter string
	set the CocoaString to CocoaArray's componentsJoinedByString_(textItemDelimiter)
	-- return the Cocoa string coerced into an AppleScript string
	return (CocoaString as string)
end listToStringUsingTextItemDelimiter
