on convertNumberToDecimalValueString(thisNumber, maxDecimalPlaces)
	if maxDecimalPlaces is greater than 0 then
		set decimalIndicators to "."
		repeat maxDecimalPlaces times
			set decimalIndicators to decimalIndicators & "#"
		end repeat
	else
		set decimalIndicators to ""
	end if
	set thisFormatter to current application's NSNumberFormatter's alloc()'s init()
	tell thisFormatter to setFormat_("0" & decimalIndicators)
	set resultingText to thisFormatter's stringFromNumber_(thisNumber)
	return (resultingText as string)
end convertNumberToDecimalValueString
