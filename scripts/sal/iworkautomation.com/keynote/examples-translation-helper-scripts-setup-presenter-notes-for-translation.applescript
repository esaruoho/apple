property sourceLanguageID : "en" -- (en=English, fr=French, es=Spanish, de=German, it=Italian, sv=Swedish, nl=Dutch)
property sourceLanguageTitle : "English"
property destinationLanguageID : "es"
property destinationLanguageTitle : "Spanish"

property languageAbbreviations : {"en", "fr", "es", "de", "it", "sv", "nl"}
property languageTitles : {"English", "French", "Spanish", "German", "Italian", "Swedish", "Dutch"}

property bodyStyleCSS : "margin-left:36px;-webkit-user-select:none;width:50%;background-color:#555;color:white;"

property slideIdentiferOpeningTag : "<h4 style=\"margin-bottom:4px;margin:0;\">"
property slideIdentiferClosingTag : "</h4>"

property noteOpeningTag : "<textarea rows=\"5\" id=\"txtareaXXXX\" onClick=\"SelectAll('txtareaXXXX');\">"
property noteClosingTag : "</textarea>"

property blankLineHTML : "<hr>"

property introductionOpeningTag : "<h3 style=\"margin-bottom:0;font-style:italic;\">"
property introductionClosingTag : "</h3>"

property documentTitleHTMLOpeningTag : "<h2 style=\"margin-left:24px;margin-bottom:12px;margin-top:8px;\">"
property documentTitleHTMLClosingTag : "</h2>"

property instructionsOpeningTag : "<p style=\"font-size:small;font-style:italic;\">"
property instructionsClosingTag : "</p>"

tell application "Keynote"
	activate
	if not (exists document 1) then error number -128
	repeat
		display dialog "This script will open a new window in Safari containing a tab listing the presenters notes from the front presentation, and a second tab displaying the Google Translate website." & linefeed & linefeed & "Translate from: " & sourceLanguageTitle & linefeed & "Translate to: " & destinationLanguageTitle buttons {"Cancel", "Set Prefs", "Begin"} default button 3 with title "Translation Helper"
		if button returned of the result is "Set Prefs" then
			set thisLanguage to (choose from list languageTitles with prompt "Language to translate from:" default items {sourceLanguageTitle})
			if thisLanguage is not false then
				set sourceLanguageTitle to (thisLanguage as string)
				set sourceLanguageID to my matchItemByIndexToCorrespondingList(sourceLanguageTitle, languageTitles, languageAbbreviations)
			end if
			set thisLanguage to (choose from list languageTitles with prompt "Language to translate to:" default items {destinationLanguageTitle})
			if thisLanguage is not false then
				set destinationLanguageTitle to (thisLanguage as string)
				set destinationLanguageID to my matchItemByIndexToCorrespondingList(destinationLanguageTitle, languageTitles, languageAbbreviations)
			end if
		else
			exit repeat
		end if
	end repeat
	tell the front document
		set thisDocumentName to the name of it
		set the HTMLBody to ¬
			introductionOpeningTag & "Presenter notes for:" & ¬
			introductionClosingTag & linefeed & ¬
			documentTitleHTMLOpeningTag & "“" & thisDocumentName & ¬
			"”" & documentTitleHTMLClosingTag & linefeed & ¬
			instructionsOpeningTag & "(Click the text of a presenter note to select it)" & ¬
			instructionsClosingTag
		repeat with i from 1 to the count of slides
			tell slide i
				if skipped is false then
					set thisSlideNotes to its presenter notes
					set thisSlideNotesHTML to thisSlideNotes
					set thisNoteOpeningTag to my replaceText(noteOpeningTag, "XXXX", (i as string))
					set the HTMLBody to ¬
						HTMLBody & linefeed & ¬
						blankLineHTML & linefeed & ¬
						slideIdentiferOpeningTag & "Slide " & (i as string) & ¬
						slideIdentiferClosingTag & linefeed & ¬
						thisNoteOpeningTag & thisSlideNotesHTML & noteClosingTag
				end if
			end tell
		end repeat
	end tell
end tell

-- MEGE HTML CONTENT
set HTMLOutline to "<!DOCTYPE html>
<html lang=\"en\">
<head>
	<meta charset=\"utf-8\" />
	<meta name=\"description\" content=\"Page Generated for Translation\">
	<title>" & thisDocumentName & "</title>
	<script type=\"text/javascript\">
		function SelectAll(id)
			{
				document.getElementById(id).focus();
				document.getElementById(id).select();
			}
	</script>
	<style>
		textarea {width:96%;}
	</style>
</head>
<body style=\"" & bodyStyleCSS & "\">" & linefeed & HTMLBody & ¬
	linefeed & "</body>" & linefeed & "</html>"

-- CREATE THE HTML FILE
set fileName to (do shell script "uuidgen") & ".html"
set temporaryFolder to (path to temporary items folder from user domain)
set targetFileHFSPath to (temporaryFolder as string) & fileName
if my writeToFile(HTMLOutline, targetFileHFSPath, false) is true then
	tell application "System Events"
		set thisURL to the URL of disk item targetFileHFSPath
	end tell
else
	beep
	error number -128
end if

-- OPEN HTML FILE IN NEW 2-TAB WINDOW WITH GOOGLE TRANSLATE <https://translate.google.com/#en/es/>
set GoogleTranslateURL to ¬
	"https://translate.google.com/#" & sourceLanguageID & ¬
	"/" & destinationLanguageID & "/"
tell application "Safari"
	activate
	set thisWindow to make new document with properties {URL:thisURL}
	tell window 1
		make new tab with properties {URL:GoogleTranslateURL}
	end tell
end tell

on writeToFile(thisData, targetFile, appendData)
	try
		set the targetFile to the targetFile as string
		set the openTargetFile to ¬
			open for access file targetFile with write permission
		if appendData is false then set eof of the openTargetFile to 0
		write thisData to the openTargetFile starting at eof as «class utf8»
		close access the openTargetFile
		return true
	on error
		try
			close access file targetFile
		end try
		return false
	end try
end writeToFile

on replaceText(sourceText, searchString, replacementString)
	set AppleScript's text item delimiters to the searchString
	set the itemList to every text item of sourceText
	set AppleScript's text item delimiters to the replacementString
	set sourceText to the itemList as string
	set AppleScript's text item delimiters to ""
	return sourceText
end replaceText

on matchItemByIndexToCorrespondingList(itemToMatch, sourceList, matchingList)
	if length of sourceList is equal to length of matchingList then
		repeat with i from 1 to the count of sourceList
			if item i of sourceList is itemToMatch then
				return item i of matchingList
			end if
		end repeat
	end if
	return false
end matchItemByIndexToCorrespondingList
