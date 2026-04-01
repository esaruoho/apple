on changeCaseOfText(sourceText, caseIndicator)
	-- DOCUMENTATION: http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/uid/20000154-uppercaseString
	-- DOCUMENTATION: http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/uid/20000154-lowercaseString
	-- DOCUMENTATION: http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/uid/20000154-capitalizedString
	
	-- create a Cocoa string from the passed text, by calling the NSString class method stringWithString:
	set the sourceString to current application's NSString's stringWithString_(sourceText)
	-- apply the indicated transformation to the Cocoa string
	if the caseIndicator is 0 then
		set the adjustedString to sourceString's uppercaseString()
	else if the caseIndicator is 1 then
		set the adjustedString to sourceString's lowercaseString()
	else
		set the adjustedString to sourceString's capitalizedString()
	end if
	-- convert from Cocoa string to AppleScript string
	return (adjustedString as string)
end changeCaseOfText
