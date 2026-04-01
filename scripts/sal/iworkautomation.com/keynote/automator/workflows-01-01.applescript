tell application id "com.apple.iwork.keynote"
	activate
	set textToReturn to ""
	repeat with i from 1 to 10
		display dialog "Enter the text of the bullet point " & ¬
			(i as string) default answer ("Bullet text " & (i as string)) ¬
			with title "Slide Bullet Points" buttons ¬
			{"Cancel", "Add & Done", "Add"} default button 3
		copy result to ¬
			{button returned:buttonPressed, text returned:textEntered}
		if buttonPressed is "Add & Done" then
			if textToReturn is "" then
				set textToReturn to textEntered
			else
				set textToReturn to textToReturn & return & textEntered
			end if
			return textToReturn
		end if
		if i is 1 then
			set textToReturn to textEntered
		else
			set textToReturn to textToReturn & return & textEntered
		end if
	end repeat
end tell
