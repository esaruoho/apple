set the name_list to {"Sal", "Sue", "Bob", "Carl"}
set the phone_list to {"5-5874", "5-2435", "5-9008", "5-1037"}
set the chosen_person to choose from list the name_list with prompt "Choose a person:"
if the chosen_person is false then return "user cancelled"
set the phone_number to item (list_position((chosen_person as string), name_list)) of the phone_list
display dialog "The phone extension for " & chosen_person & " is " & phone_number & "." buttons {"OK"} default button 1

on list_position(this_item, this_list)
	repeat with i from 1 to the count of this_list
		if item i of this_list is this_item then return i
	end repeat
	return 0
end list_position
