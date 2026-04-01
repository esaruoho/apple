on convertNumberToCurrencyValueString(thisNumber)
	--> returns comma delimited, rounded, localized currency value, e.g.: (9128 = $9,128.00) (9978.2485 = $9,128.25)
	-- DOCUMENTATION: http://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSNumberFormatter_Class/Reference/Reference.html
	tell current application's NSNumberFormatter to set resultingText to localizedStringFromNumber_numberStyle_(thisNumber, current application's NSNumberFormatterCurrencyStyle)
	return (resultingText as string)
end convertNumberToCurrencyValueString
