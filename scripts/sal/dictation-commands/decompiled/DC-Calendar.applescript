use AppleScript version "2.5"
use framework "Foundation"
use framework "AppKit"
use framework "EventKit"
-- use framework "AddressBook"
use scripting additions


on showDayViewForToday()
	set currentDate to (get current date)
	showCurrentCalendarDayFor(currentDate)
end showDayViewForToday

on showDayViewForTomorrow()
	set currentDate to (get current date) + (1 * days)
	showCurrentCalendarDayFor(currentDate)
end showDayViewForTomorrow

on showDayViewForNextMonday()
	set currentDate to (get current date)
	set currentWeekday to (weekday of currentDate) as string
	if currentWeekday is "Monday" then
		set targetDate to currentDate + (7 * days)
	else if currentWeekday is "Tuesday" then
		set targetDate to currentDate + (6 * days)
	else if currentWeekday is "Wednesday" then
		set targetDate to currentDate + (5 * days)
	else if currentWeekday is "Thursday" then
		set targetDate to currentDate + (4 * days)
	else if currentWeekday is "Friday" then
		set targetDate to currentDate + (3 * days)
	else if currentWeekday is "Saturday" then
		set targetDate to currentDate + (2 * days)
	else if currentWeekday is "Sunday" then
		set targetDate to currentDate + (1 * days)
	end if
	showCurrentCalendarDayFor(targetDate)
end showDayViewForNextMonday

on showDayViewForNextTuesday()
	set currentDate to (get current date)
	set currentWeekday to (weekday of currentDate) as string
	if currentWeekday is "Monday" then
		set targetDate to currentDate + (1 * days)
	else if currentWeekday is "Tuesday" then
		set targetDate to currentDate + (7 * days)
	else if currentWeekday is "Wednesday" then
		set targetDate to currentDate + (6 * days)
	else if currentWeekday is "Thursday" then
		set targetDate to currentDate + (5 * days)
	else if currentWeekday is "Friday" then
		set targetDate to currentDate + (4 * days)
	else if currentWeekday is "Saturday" then
		set targetDate to currentDate + (3 * days)
	else if currentWeekday is "Sunday" then
		set targetDate to currentDate + (2 * days)
	end if
	showCurrentCalendarDayFor(targetDate)
end showDayViewForNextTuesday

on showDayViewForNextWednesday()
	set currentDate to (get current date)
	set currentWeekday to (weekday of currentDate) as string
	if currentWeekday is "Monday" then
		set targetDate to currentDate + (2 * days)
	else if currentWeekday is "Tuesday" then
		set targetDate to currentDate + (1 * days)
	else if currentWeekday is "Wednesday" then
		set targetDate to currentDate + (7 * days)
	else if currentWeekday is "Thursday" then
		set targetDate to currentDate + (6 * days)
	else if currentWeekday is "Friday" then
		set targetDate to currentDate + (5 * days)
	else if currentWeekday is "Saturday" then
		set targetDate to currentDate + (4 * days)
	else if currentWeekday is "Sunday" then
		set targetDate to currentDate + (3 * days)
	end if
	showCurrentCalendarDayFor(targetDate)
end showDayViewForNextWednesday

on showDayViewForNextThursday()
	set currentDate to (get current date)
	set currentWeekday to (weekday of currentDate) as string
	if currentWeekday is "Monday" then
		set targetDate to currentDate + (3 * days)
	else if currentWeekday is "Tuesday" then
		set targetDate to currentDate + (2 * days)
	else if currentWeekday is "Wednesday" then
		set targetDate to currentDate + (1 * days)
	else if currentWeekday is "Thursday" then
		set targetDate to currentDate + (7 * days)
	else if currentWeekday is "Friday" then
		set targetDate to currentDate + (6 * days)
	else if currentWeekday is "Saturday" then
		set targetDate to currentDate + (5 * days)
	else if currentWeekday is "Sunday" then
		set targetDate to currentDate + (4 * days)
	end if
	showCurrentCalendarDayFor(targetDate)
end showDayViewForNextThursday

on showDayViewForNextFriday()
	set currentDate to (get current date)
	set currentWeekday to (weekday of currentDate) as string
	if currentWeekday is "Monday" then
		set targetDate to currentDate + (4 * days)
	else if currentWeekday is "Tuesday" then
		set targetDate to currentDate + (3 * days)
	else if currentWeekday is "Wednesday" then
		set targetDate to currentDate + (2 * days)
	else if currentWeekday is "Thursday" then
		set targetDate to currentDate + (1 * days)
	else if currentWeekday is "Friday" then
		set targetDate to currentDate + (7 * days)
	else if currentWeekday is "Saturday" then
		set targetDate to currentDate + (6 * days)
	else if currentWeekday is "Sunday" then
		set targetDate to currentDate + (5 * days)
	end if
	showCurrentCalendarDayFor(targetDate)
end showDayViewForNextFriday

on showDayViewForNextSaturday()
	set currentDate to (get current date)
	set currentWeekday to (weekday of currentDate) as string
	if currentWeekday is "Monday" then
		set targetDate to currentDate + (5 * days)
	else if currentWeekday is "Tuesday" then
		set targetDate to currentDate + (4 * days)
	else if currentWeekday is "Wednesday" then
		set targetDate to currentDate + (3 * days)
	else if currentWeekday is "Thursday" then
		set targetDate to currentDate + (2 * days)
	else if currentWeekday is "Friday" then
		set targetDate to currentDate + (1 * days)
	else if currentWeekday is "Saturday" then
		set targetDate to currentDate + (7 * days)
	else if currentWeekday is "Sunday" then
		set targetDate to currentDate + (6 * days)
	end if
	showCurrentCalendarDayFor(targetDate)
end showDayViewForNextSaturday

on showDayViewForNextSunday()
	set currentDate to (get current date)
	set currentWeekday to (weekday of currentDate) as string
	if currentWeekday is "Monday" then
		set targetDate to currentDate + (6 * days)
	else if currentWeekday is "Tuesday" then
		set targetDate to currentDate + (5 * days)
	else if currentWeekday is "Wednesday" then
		set targetDate to currentDate + (4 * days)
	else if currentWeekday is "Thursday" then
		set targetDate to currentDate + (3 * days)
	else if currentWeekday is "Friday" then
		set targetDate to currentDate + (2 * days)
	else if currentWeekday is "Saturday" then
		set targetDate to currentDate + (1 * days)
	else if currentWeekday is "Sunday" then
		set targetDate to currentDate + (7 * days)
	end if
	showCurrentCalendarDayFor(targetDate)
end showDayViewForNextSunday

on showWeekViewForCurrentWeek()
	showDayViewForToday()
	tell application id "com.apple.iCal"
		switch view to week view
	end tell
end showWeekViewForCurrentWeek

on showWeekViewForNextWeek()
	set targetDate to (get current date) + (7 * days)
	showCurrentCalendarDayFor(targetDate)
	tell application id "com.apple.iCal"
		switch view to week view
	end tell
end showWeekViewForNextWeek

on showMonthViewForCurrentMonth()
	showDayViewForToday()
	tell application id "com.apple.iCal"
		switch view to month view
	end tell
end showMonthViewForCurrentMonth

on showMonthViewForNextMonth()
	set targetDate to (get current date)
	set day of targetDate to 1
	set currentMonth to the month of targetDate as integer
	if currentMonth is 12 then
		set month of targetDate to 1
	else
		set month of targetDate to currentMonth + 1
	end if
	showCurrentCalendarDayFor(targetDate)
	tell application id "com.apple.iCal"
		switch view to month view
	end tell
end showMonthViewForNextMonth

on showMonthViewForMonth(monthNumber)
	set targetDate to (get current date)
	set currentMonth to (month of targetDate) as integer
	set currentYear to (year of targetDate)
	set day of targetDate to 1
	if monthNumber is less than or equal to currentMonth then
		set year of targetDate to (currentYear + 1)
	end if
	set month of targetDate to monthNumber
	showCurrentCalendarDayFor(targetDate)
	tell application id "com.apple.iCal"
		switch view to month view
	end tell
end showMonthViewForMonth

on showYearViewForCurrentYear()
	showDayViewForToday()
	tell application "System Events"
		keystroke "4" using command down
	end tell
end showYearViewForCurrentYear

on showYearViewForNextYear()
	set targetDate to (get current date)
	set day of targetDate to 1
	set month of targetDate to 1
	set year of targetDate to (year of targetDate) + 1
	showCurrentCalendarDayFor(targetDate)
	tell application "System Events"
		keystroke "4" using command down
	end tell
end showYearViewForNextYear

on showCurrentCalendarDayFor(thisDate)
	tell script "DC-Workspace"
		copy getScreenDimensions() to {screenWidth, screenHeight}
	end tell
	tell application id "com.apple.iCal"
		activate
		set bounds of window 1 to {0, 23, screenWidth, screenHeight}
		switch view to day view
		view calendar at thisDate
	end tell
end showCurrentCalendarDayFor

(* EVENT KIT HANDLERS *)

-- You need to fetch the event store first; it's required for many other handlers. This also triggers authentication if needed.
on fetchEKEventStore()
	-- create event store and get the OK to access Calendars
	set theEKEventStore to current application's EKEventStore's alloc()'s init()
	theEKEventStore's requestAccessToEntityType:0 completion:(missing value)
	-- check if app has access; this will still occur the first time you OK authorization
	set authorizationStatus to current application's EKEventStore's authorizationStatusForEntityType:0
	if authorizationStatus is not 3 then
		displayPrivacyPreferencePaneForCalendarAccess()
		return false
	else
		return theEKEventStore
	end if
end fetchEKEventStore

on getTodaysEvents()
	set currentDate to (current date)
	-- create day start 
	copy currentDate to dayStart
	set time of dayStart to 0
	-- create day end
	copy currentDate to dayEnd
	set time of dayEnd to 86400 - 1
	-- get current time
	set currentTime to time of currentDate
	
	-- GET A SNAPSHOT OF THE CURRENT CALENDAR STORE
	set theStore to fetchEKEventStore()
	-- GET A LIST OF CALENDARS THAT SUPPORT ADDING EVENTS
	set eventSupportingCalendars to theStore's calendarsForEntityType:0
	-- CREATE A PREDICATE FOR PERFORMING A SEARCH
	set thePredicate to theStore's predicateForEventsWithStartDate:dayStart endDate:dayEnd calendars:eventSupportingCalendars
	-- SEARCH THE CALENDAR STORE
	set theEvents to theStore's eventsMatchingPredicate:thePredicate
	set theEvents to theEvents's sortedArrayUsingSelector:"compareStartDateWithEvent:"
	if (count of theEvents) is 0 then
		my displaySpokenErrorAlert("NO_EVENTS_TODAY", "")
		error number -128
	else
		return theEvents
	end if
end getTodaysEvents

on getEventIDsForTodaysEvents()
	set theseEvents to getTodaysEvents()
	set eventData to {}
	repeat with i from 1 to the count of theseEvents
		set theEvent to item i of theseEvents
		set eventPropertiesRecord to (its propertiesOfEvent:theEvent)
		set the end of eventData to {event_external_ID of eventPropertiesRecord, calendar_name of eventPropertiesRecord}
	end repeat
	return eventData
end getEventIDsForTodaysEvents

on getTomorrowsEvents()
	set currentDate to (current date) + (1 * days)
	-- create day start 
	copy currentDate to dayStart
	set time of dayStart to 0
	-- create day end
	copy currentDate to dayEnd
	set time of dayEnd to 86400 - 1
	-- get current time
	set currentTime to time of currentDate
	
	-- GET A SNAPSHOT OF THE CURRENT CALENDAR STORE
	set theStore to fetchEKEventStore()
	-- GET A LIST OF CALENDARS THAT SUPPORT ADDING EVENTS
	set eventSupportingCalendars to theStore's calendarsForEntityType:0
	-- CREATE A PREDICATE FOR PERFORMING A SEARCH
	set thePredicate to theStore's predicateForEventsWithStartDate:dayStart endDate:dayEnd calendars:eventSupportingCalendars
	-- SEARCH THE CALENDAR STORE
	set theEvents to theStore's eventsMatchingPredicate:thePredicate
	set theEvents to theEvents's sortedArrayUsingSelector:"compareStartDateWithEvent:"
	if (count of theEvents) is 0 then
		my displaySpokenErrorAlert("NO_EVENTS_TOMORROW", "")
		error number -128
	else
		return theEvents
	end if
end getTomorrowsEvents

on getEventIDsForTomorrowsEvents()
	set theseEvents to getTomorrowsEvents()
	set eventData to {}
	repeat with i from 1 to the count of theseEvents
		set theEvent to item i of theseEvents
		set eventPropertiesRecord to (its propertiesOfEvent:theEvent)
		set the end of eventData to {event_external_ID of eventPropertiesRecord, calendar_name of eventPropertiesRecord}
	end repeat
	return eventData
end getEventIDsForTomorrowsEvents

on getCurrentEvent()
	set theEvents to getTodaysEvents()
	set currentTime to time of (current date)
	set currentEvents to {}
	repeat with anEvent in theEvents
		set thisEventInfo to (its propertiesOfEvent:anEvent)
		set calendarTitle to (calendar_name of thisEventInfo)
		set thisEventID to event_external_ID of thisEventInfo
		set thisEventStartTime to time of (event_start_date of thisEventInfo)
		set thisEventEndTime to time of (event_end_date of thisEventInfo)
		if currentTime is greater than thisEventStartTime and currentTime is less than thisEventEndTime then
			set the end of currentEvents to anEvent
		end if
	end repeat
	if currentEvents is {} then
		my displaySpokenErrorAlert("NO_EVENT_NOW", "")
		error number -128
	else if (count of currentEvents) is greater than 1 then
		my displaySpokenErrorAlert("MULTIPLE_EVENTS", "")
		error number -128
	else
		set currentEvent to item 1 of currentEvents
		return currentEvent
	end if
end getCurrentEvent

on getAttendeeEmailAddressesForEvent(thisEvent)
	set thisEventInfo to (its propertiesOfEvent:thisEvent)
	set thisEventID to event_external_ID of thisEventInfo
	set calendarTitle to (calendar_name of thisEventInfo)
	set attendeeEmailAddresses to {}
	tell application "Calendar"
		set thisEvent to event id thisEventID of calendar calendarTitle
		set theseAttendees to attendees of thisEvent
		repeat with i from 1 to the count of theseAttendees
			set anAttendee to item i of theseAttendees
			try
				set thisEmailAddress to (get email of anAttendee)
				if thisEmailAddress does not start with "urn:" then
					if thisEmailAddress is not in attendeeEmailAddresses then
						set the end of attendeeEmailAddresses to thisEmailAddress
					end if
				end if
			end try
		end repeat
	end tell
	return attendeeEmailAddresses
end getAttendeeEmailAddressesForEvent

on getAttendeeAddressesForCurrentMeeting()
	say (getLocalizedStringForKey("GETTING_CURRENT_EVENT"))
	set currentEvent to getCurrentEvent()
	say (getLocalizedStringForKey("GETTING_ATTENDEE_ADDRESSES"))
	set theseAddresses to getAttendeeEmailAddressesForEvent(currentEvent)
	return theseAddresses
end getAttendeeAddressesForCurrentMeeting

-- returns record.
on propertiesOfEvent:theEvent
	-- work around problem with null values in dictionaries in 10.9; set initial nulls for all values that might be missing value
	set theNull to current application's NSNull's |null|()
	set theDict to current application's NSMutableDictionary's dictionaryWithObjects:{theNull, theNull, theNull, theNull, theNull, theNull, theNull} forKeys:{"event_summary", "event_time_zone", "event_location", "event_url", "event_description", "event_organizer", "event_original_date"}
	log (theEvent's calendar()'s title()) as string
	theDict's setObject:(theEvent's calendar()'s title()) forKey:"calendar_name"
	log theDict
	set theResult to (theEvent's calendar()'s type()) as integer
	theDict's setObject:(item (theResult + 1) of {"local", "cloud", "Exchange", "subscription", "birthday"}) forKey:"calendar_type"
	set theResult to (theEvent's title())
	if theResult is not missing value then theDict's setObject:theResult forKey:"event_summary"
	theDict's setObject:(theEvent's |calendarItemExternalIdentifier|()) forKey:"event_external_ID"
	theDict's setObject:(theEvent's |startDate|()) forKey:"event_start_date"
	theDict's setObject:(theEvent's |endDate|()) forKey:"event_end_date"
	set tz to (theEvent's timeZone())
	if tz is not missing value then theDict's setObject:(tz's |name|()) forKey:"event_time_zone"
	set theResult to (theEvent's location())
	if theResult is not missing value then theDict's setObject:theResult forKey:"event_location"
	set theURL to (theEvent's |URL|())
	if theURL is not missing value then theDict's setObject:(theURL's absoluteString()) forKey:"event_url"
	set theResult to (theEvent's hasNotes()) as boolean
	if theResult then
		set theResult to (theEvent's notes())
		if theResult is not missing value then theDict's setObject:theResult forKey:"event_description"
	end if
	set theAttendees to theEvent's |hasAttendees|()
	if theAttendees as boolean then
		theDict's setObject:(theEvent's attendees()'s valueForKey:"name") forKey:"event_attendees"
	else
		theDict's setObject:{} forKey:"event_attendees"
	end if
	theDict's setObject:(theEvent's |hasRecurrenceRules|()) forKey:"event_is_recurring"
	theDict's setObject:(theEvent's |creationDate|()) forKey:"event_creation_date"
	set theResult to (theEvent's organizer())
	if theResult is not missing value then
		set theResult to (theResult's |name|())
		if theResult is not missing value then theDict's setObject:theResult forKey:"event_organizer"
	end if
	set theResult to (theEvent's |occurrenceDate|())
	if theResult is not missing value then theDict's setObject:theResult forKey:"event_original_date"
	set theResult to (theEvent's status())
	if theResult is missing value then
		theDict's setObject:"none" forKey:"event_status"
	else
		set theResult to theResult as integer
		theDict's setObject:(item (theResult + 1) of {"none", "confirmed", "tentative", "canceled"}) forKey:"event_status"
	end if
	log theDict
	return theDict as record
end propertiesOfEvent:



on displayPrivacyPreferencePaneForCalendarAccess()
	try
		set errorMessage to getLocalizedStringForKey("PRIVACY_ACCESS_MSG")
		tell application "System Settings"
			activate
			reveal anchor "Privacy_Calendars" of pane id "com.apple.preference.security"
		end tell
		say errorMessage
		return true
	on error errorMessage
		return false
	end try
end displayPrivacyPreferencePaneForCalendarAccess

(* DEMO *)

on createDemoEventsForToday()
	set aDate to (get current date)
	createDemoEventsForDate(aDate)
end createDemoEventsForToday

on createDemoEventsForTomorrow()
	set aDate to (get current date)
	set aDate to aDate + (1 * days)
	createDemoEventsForDate(aDate)
end createDemoEventsForTomorrow

on deleteDemoCalendar()
	(* DO NOT USE causes database error *)
	tell application id "com.apple.iCal"
		activate
		if exists calendar "DEMO" then
			try
				say "Delete the demo calendar?" without waiting until completion
				display dialog "Delete calendar DEMO?"
				say " " with stopping current speech
				delete calendar "DEMO"
				say "Done!"
			on error
				say " " with stopping current speech
			end try
		end if
	end tell
end deleteDemoCalendar

on createDemoEventsForDate(targetDate)
	tell application id "com.apple.iCal"
		activate
		
		if not (exists calendar "DEMO") then
			make new calendar with properties {name:"DEMO"}
			delay 1
		end if
		view calendar at targetDate
		switch view to day view
		
		copy targetDate to startDate
		copy targetDate to endDate
		set time of startDate to 9 * 3600
		set time of endDate to 10 * 3600
		tell calendar "DEMO"
			set aEvent to make new event with properties {start date:startDate, end date:endDate, summary:"Team Adjenda"}
			tell aEvent
				make new attendee with properties {display name:"Roberta Shumacher", email:"rshu@acme.com"}
				make new attendee with properties {display name:"Carl Fontana", email:"cfont@acme.com"}
				make new attendee with properties {display name:"Selena Drummond", email:"seldru@acme.com"}
				make new attendee with properties {display name:"Dan Write", email:"dwrte@acme.com"}
			end tell
		end tell
		
		copy targetDate to startDate
		copy targetDate to endDate
		set time of startDate to 11 * 3600
		set time of endDate to 12 * 3600
		tell calendar "DEMO"
			set aEvent to make new event with properties {start date:startDate, end date:endDate, summary:"Project Planning"}
			tell aEvent
				make new attendee with properties {display name:"Zesti Ferber", email:"zesti@acme.com"}
				make new attendee with properties {display name:"Wilma Rudolph", email:"wilma@acme.com"}
				make new attendee with properties {display name:"Herbert Finlay", email:"finlay@acme.com"}
			end tell
		end tell
		
		copy targetDate to startDate
		copy targetDate to endDate
		set time of startDate to 14 * 3600
		set time of endDate to 15 * 3600
		tell calendar "DEMO"
			set aEvent to make new event with properties {start date:startDate, end date:endDate, summary:"Finance Review"}
			tell aEvent
				make new attendee with properties {display name:"June Applebaum", email:"june@acme.com"}
			end tell
		end tell
		
		copy targetDate to startDate
		copy targetDate to endDate
		set time of startDate to 16 * 3600
		set time of endDate to 17 * 3600
		tell calendar "DEMO"
			set aEvent to make new event with properties {start date:startDate, end date:endDate, summary:"Team Review"}
			tell aEvent
				make new attendee with properties {display name:"Roberta Shumacher", email:"rshu@acme.com"}
				make new attendee with properties {display name:"Carl Fontana", email:"cfont@acme.com"}
				make new attendee with properties {display name:"Selena Drummond", email:"seldru@acme.com"}
				make new attendee with properties {display name:"Dan Write", email:"dwrte@acme.com"}
			end tell
		end tell
		
	end tell
end createDemoEventsForDate


(* USER INTERACTION *)

on announceCompletion()
	say my getLocalizedStringForKey("SUCCESSFUL_COMPLETION_PHRASE")
end announceCompletion

on askForConfirmation(messageKey, approveButtonKey, disapproveButtonKey, appID)
	if appID is "" or appID is missing value then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		set frontmostApp to aWorkspace's frontmostApplication
		set appID to (frontmostApp's bundleIdentifier) as text
	end if
	try
		set confirmationTitle to getLocalizedStringForKey("CONFIRMATION_TITLE")
		set confirmationMessage to getLocalizedStringForKey(messageKey)
		set approvalButtonTitle to getLocalizedStringForKey(approveButtonKey)
		set disapprovalButtonTitle to getLocalizedStringForKey(disapproveButtonKey)
		set cfgutil to "/usr/bin/say"
		set theTask to (current application's NSTask's launchedTaskWithLaunchPath:cfgutil arguments:{confirmationMessage})
		tell application id appID
			activate
			display alert confirmationTitle message confirmationMessage buttons {disapprovalButtonTitle, approvalButtonTitle}
			set userChoice to the button returned of the result
		end tell
		-- stop speaking
		theTask's terminate()
		if userChoice is approvalButtonTitle then
			return true
		else
			return false
		end if
	on error errorMessage
		log errorMessage
		-- stop speaking
		theTask's terminate()
		return false
	end try
end askForConfirmation

on displaySpokenErrorAlert(errorKey, appID)
	if appID is "" or appID is missing value then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		set frontmostApp to aWorkspace's frontmostApplication
		set appID to (frontmostApp's bundleIdentifier) as text
	end if
	try
		set errorTitle to getLocalizedStringForKey("ERROR_TITLE")
		set errorMessage to getLocalizedStringForKey(errorKey)
		set cancelButtonTitle to getLocalizedStringForKey("CANCEL_BUTTON_TITLE")
		tell current application
			say errorMessage without waiting until completion
		end tell
		tell application id appID
			activate
			display alert errorTitle message errorMessage buttons {cancelButtonTitle}
		end tell
		-- stop speaking
		say " " with stopping current speech
		return true
	on error errorMessage
		log errorMessage
		error number -128
	end try
end displaySpokenErrorAlert

on promptForInput(displayedPrompt, spokenPrompt, defaultAnswerString, answerIsRequired, continueButtonTitle, appID)
	if appID is "" or appID is missing value then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		set frontmostApp to aWorkspace's frontmostApplication
		set appID to (frontmostApp's bundleIdentifier) as text
	end if
	try
		set cancelButtonTitle to getLocalizedStringForKey("CANCEL_BUTTON_TITLE")
		say spokenPrompt without waiting until completion
		repeat
			tell application id appID
				activate
				display dialog displayedPrompt default answer defaultAnswerString buttons {cancelButtonTitle, continueButtonTitle} default button 2
				set textInput to the text returned of the result
				if answerIsRequired then
					if textInput is not "" then
						return textInput
					else
						say (my getLocalizedStringForKey("INPUT_REQUIRED")) without waiting until completion
					end if
				else
					return textInput
				end if
			end tell
		end repeat
		return true
	on error errorMessage
		log errorMessage
		-- return false
		error number -128
	end try
end promptForInput

on requestPositiveIntegerFromUserWithPrompt(aPrompt, defaultValue, targetAppID)
	if targetAppID is "" or targetAppID is missing value then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		set frontmostApp to aWorkspace's frontmostApplication
		set appID to (frontmostApp's bundleIdentifier) as text
	end if
	tell application id appID
		activate
		repeat
			try
				display dialog aPrompt default answer defaultValue
				set thisInteger to the text returned of the result as integer
				if thisInteger is greater than 0 then
					return thisInteger
				else
					beep
				end if
			on error number errorNumber
				if errorNumber is -128 then return false
				beep
			end try
		end repeat
	end tell
end requestPositiveIntegerFromUserWithPrompt

on getLocalizedStringForKey(thisKey)
	set thisBundlePath to (path to me)
	return (localized string thisKey in bundle thisBundlePath)
end getLocalizedStringForKey

on speakWithMutedInput(stringToSpeak)
	try
		set volumeLevel to missing value
		tell current application
			set volumeLevel to input volume of (get volume settings)
			if volumeLevel is missing value then -- the current device has no input controls 
				my logThis("audio device has no input controls")
				say stringToSpeak with stopping current speech -- and waiting until completion
			else
				set volume input volume 0
				say stringToSpeak with stopping current speech and waiting until completion
				set volume input volume volumeLevel
			end if
		end tell
	on error errorMessage
		if volumeLevel is not missing value then
			tell current application
				try
					set volume input volume volumeLevel
				end try
			end tell
		end if
		beep
		my logThis(errorMessage)
	end try
end speakWithMutedInput
