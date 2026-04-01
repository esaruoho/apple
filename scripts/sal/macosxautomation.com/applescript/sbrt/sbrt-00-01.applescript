on findAndReplaceStringInText(sourceText, searchString, replacementString)
	-- DOCUMENTATION: http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/uid/20000154-SW6
	
	-- create a Cocoa string from the passed AppleScript string, by calling the NSString class method stringWithString:
	set the sourceString to current application's NSString's stringWithString_(sourceText)
	-- Replace the search string with the replacement string, by calling a method on the newly created instance
	set the adjustedString to the sourceString's stringByReplacingOccurrencesOfString_withString_(searchString, replacementString)
	-- convert from Cocoa string to AppleScript string
	return (adjustedString as string)
end findAndReplaceStringInText
