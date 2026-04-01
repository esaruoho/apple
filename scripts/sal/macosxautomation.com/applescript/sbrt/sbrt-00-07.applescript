on decodePercentEncoding(sourceText)
	-- DOCUMENTATION: http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/uid/20000154-BCIECHFE
	-- DOCUMENTATION: http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/Reference/NSString.html#//apple_ref/doc/uid/20000154-SW59
	
	-- create a Cocoa string from the passed AppleScript string, by calling the NSString class method stringWithString:
	set the sourceString to current application's NSString's stringWithString_(sourceText)
	-- apply the indicated transformation to the Cooca string
	set the adjustedString to the sourceString's stringByReplacingPercentEscapesUsingEncoding_(current application's NSUTF8StringEncoding)
	-- coerce from Cocoa string to AppleScript string
	return (adjustedString as string)
end decodePercentEncoding
