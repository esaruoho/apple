on trimWhiteSpaceAroundString(sourceText)
	-- trims spaces and tabs from both sides of the passed string
	-- create Cocoa string from passed AppleScript string
	set the sourceString to current application's NSString's stringWithString_(sourceText)
	-- trim white space around Cocoa string
	set the trimmedCocoaString to ¬
		sourceString's stringByTrimmingCharactersInSet_(current application's NSCharacterSet's whitespaceCharacterSet)
	-- return result coerced to an AppleScript string
	return (trimmedCocoaString as string)
end trimWhiteSpaceAroundString
