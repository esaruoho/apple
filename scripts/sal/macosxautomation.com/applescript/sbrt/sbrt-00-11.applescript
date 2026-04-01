on convertNumberToWords(thisNumber)
	--> returns a numeric value in words, e.g: (23 = “twenty-three”) (23.75 = “twenty-three point seven five”)
	-- DOCUMENTATION: http://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSNumberFormatter_Class/Reference/Reference.html
	tell current application's NSNumberFormatter to set resultingText to localizedStringFromNumber_numberStyle_(thisNumber, current application's NSNumberFormatterSpellOutStyle)
	return (resultingText as string)
end convertNumberToWords
