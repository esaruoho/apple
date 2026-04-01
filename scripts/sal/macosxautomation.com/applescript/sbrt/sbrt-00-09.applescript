on convertNumberToPercentageValueString(thisNumber)
	--> returns comma delimited, rounded, localized percentage value, e.g.: (0.2345 = 23%) (0.2375 = 24%)
	-- DOCUMENTATION: http://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSNumberFormatter_Class/Reference/Reference.html
	tell current application's NSNumberFormatter to set resultingText to localizedStringFromNumber_numberStyle_(thisNumber, current application's NSNumberFormatterPercentStyle)
	return (resultingText as string)
end convertNumberToPercentageValueString
