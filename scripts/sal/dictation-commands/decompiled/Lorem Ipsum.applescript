use framework "Foundation"
use scripting additions

property loremWords : {"lorem", "ipsum", "dolor", "sit", "amet", "consectetuer", "adipiscing", "elit", "integer", "in", "mi", "a", "mauris", "ornare", "sagittis", "suspendisse", "potenti", "suspendisse", "dapibus", "dignissim", "dolor", "nam", "sapien", "tellus", "tempus", "et", "tempus", "ac", "tincidunt", "in", "arcu", "duis", "dictum", "proin", "magna", "nulla", "pellentesque", "non", "commodo", "et", "iaculis", "sit", "amet", "mi", "mauris", "condimentum", "massa", "ut", "metus", "donec", "viverra", "sapien", "mattis", "rutrum", "tristique", "lacus", "eros", "semper", "tellus", "et", "molestie", "nisi", "sapien", "eu", "massa", "vestibulum", "ante", "ipsum", "primis", "in", "faucibus", "orci", "luctus", "et", "ultrices", "posuere", "cubilia", "curae;", "fusce", "erat", "tortor", "mollis", "ut", "accumsan", "ut", "lacinia", "gravida", "libero", "curabitur", "massa", "felis", "accumsan", "feugiat", "convallis", "sit", "amet", "porta", "vel", "neque", "duis", "et", "ligula", "non", "elit", "ultricies", "rutrum", "suspendisse", "tempor", "quisque", "posuere", "malesuada", "velit", "sed", "pellentesque", "mi", "a", "purus", "integer", "imperdiet", "orci", "a", "eleifend", "mollis", "velit", "nulla", "iaculis", "arcu", "eu", "rutrum", "magna", "quam", "sed", "elit", "nullam", "egestas", "integer", "interdum", "purus", "nec", "mauris", "vestibulum", "ac", "mi", "in", "nunc", "suscipit", "dapibus", "duis", "consectetuer", "ipsum", "et", "pharetra", "sollicitudin", "metus", "turpis", "facilisis", "magna", "vitae", "dictum", "ligula", "nulla", "nec", "mi", "nunc", "ante", "urna", "gravida", "sit", "amet", "congue", "et", "accumsan", "vitae", "magna", "praesent", "luctus", "nullam", "in", "velit", "praesent", "est", "curabitur", "turpis", "class", "aptent", "taciti", "sociosqu", "ad", "litora", "torquent", "per", "conubia", "nostra", "per", "inceptos", "hymenaeos", "cras", "consectetuer", "nibh", "in", "lacinia", "ornare", "turpis", "sem", "tempor", "massa", "sagittis", "feugiat", "mauris", "nibh", "non", "tellus", "phasellus", "mi", "fusce", "enim", "mauris", "ultrices", "turpis", "eu", "adipiscing", "viverra", "justo", "libero", "ullamcorper", "massa", "id", "ultrices", "velit", "est", "quis", "tortor", "quisque", "condimentum", "lacus", "volutpat", "nonummy", "accumsan", "est", "nunc", "imperdiet", "magna", "vulputate", "aliquet", "nisi", "risus", "at", "est", "aliquam", "imperdiet", "gravida", "tortor", "praesent", "interdum", "accumsan", "ante", "vivamus", "est", "ligula", "consequat", "sed", "pulvinar", "eu", "consequat", "vitae", "eros", "nulla", "elit", "nunc", "congue", "eget", "scelerisque", "a", "tempor", "ac", "nisi", "morbi", "facilisis", "pellentesque", "habitant", "morbi", "tristique", "senectus", "et", "netus", "et", "malesuada", "fames", "ac", "turpis", "egestas", "in", "hac", "habitasse", "platea", "dictumst", "suspendisse", "vel", "lorem", "ut", "ligula", "tempor", "consequat", "quisque", "consectetuer", "nisl", "eget", "elit", "proin", "quis", "mauris", "ac", "orci", "accumsan", "suscipit", "sed", "ipsum", "sed", "vel", "libero", "nec", "elit", "feugiat", "blandit", "vestibulum", "purus", "nulla", "accumsan", "et", "volutpat", "at", "pellentesque", "vel", "urna", "suspendisse", "nonummy", "aliquam", "pulvinar", "libero", "donec", "vulputate", "orci", "ornare", "bibendum", "condimentum", "lorem", "elit", "dignissim", "sapien", "ut", "aliquam", "nibh", "augue", "in", "turpis", "phasellus", "ac", "eros", "praesent", "luctus", "lorem", "a", "mollis", "lacinia", "leo", "turpis", "commodo", "sem", "in", "lacinia", "mi", "quam", "et", "quam", "curabitur", "a", "libero", "vel", "tellus", "mattis", "imperdiet", "in", "congue", "neque", "ut", "scelerisque", "bibendum", "libero", "lacus", "ullamcorper", "sapien", "quis", "aliquet", "massa", "velit", "vel", "orci", "fusce", "in", "nulla", "quis", "est", "cursus", "gravida", "in", "nibh", "lorem", "ipsum", "dolor", "sit", "amet", "consectetuer", "adipiscing", "elit", "integer", "fermentum", "pretium", "massa", "morbi", "feugiat", "iaculis", "nunc", "aenean", "aliquam", "pretium", "orci", "cum", "sociis", "natoque", "penatibus", "et", "magnis", "dis", "parturient", "montes", "nascetur", "ridiculus", "mus", "vivamus", "quis", "tellus", "vel", "quam", "varius", "bibendum", "fusce", "est", "metus", "feugiat", "at", "porttitor", "et", "cursus", "quis", "pede", "nam", "ut", "augue", "nulla", "posuere", "phasellus", "at", "dolor", "a", "enim", "cursus", "vestibulum", "duis", "id", "nisi", "duis", "semper", "tellus", "ac", "nulla", "vestibulum", "scelerisque", "lobortis", "dolor", "aenean", "a", "felis", "aliquam", "erat", "volutpat", "donec", "a", "magna", "vitae", "pede", "sagittis", "lacinia", "cras", "vestibulum", "diam", "ut", "arcu", "mauris", "a", "nunc", "duis", "sollicitudin", "erat", "sit", "amet", "turpis", "proin", "at", "libero", "eu", "diam", "lobortis", "fermentum", "nunc", "lorem", "turpis", "imperdiet", "id", "gravida", "eget", "aliquet", "sed", "purus", "ut", "vehicula", "laoreet", "ante", "mauris", "eu", "nunc", "sed", "sit", "amet", "elit", "nec", "ipsum", "aliquam", "egestas", "donec", "non", "nibh", "cras", "sodales", "pretium", "massa", "praesent", "hendrerit", "est", "et", "risus", "vivamus", "eget", "pede", "curabitur", "tristique", "scelerisque", "dui", "nullam", "ullamcorper", "vivamus", "venenatis", "velit", "eget", "enim", "nunc", "eu", "nunc", "eget", "felis", "malesuada", "fermentum", "quisque", "magna", "mauris", "ligula", "felis", "luctus", "a", "aliquet", "nec", "vulputate", "eget", "magna", "quisque", "placerat", "diam", "sed", "arcu", "praesent", "sollicitudin", "aliquam", "non", "sapien", "quisque", "id", "augue", "class", "aptent", "taciti", "sociosqu", "ad", "litora", "torquent", "per", "conubia", "nostra", "per", "inceptos", "hymenaeos", "etiam", "lacus", "lectus", "mollis", "quis", "mattis", "nec", "commodo", "facilisis", "nibh", "sed", "sodales", "sapien", "ac", "ante", "duis", "eget", "lectus", "in", "nibh", "lacinia", "auctor", "fusce", "interdum", "lectus", "non", "dui", "integer", "accumsan", "quisque", "quam", "curabitur", "scelerisque", "imperdiet", "nisl", "suspendisse", "potenti", "nam", "massa", "leo", "iaculis", "sed", "accumsan", "id", "ultrices", "nec", "velit", "suspendisse", "potenti", "mauris", "bibendum", "turpis", "ac", "viverra", "sollicitudin", "metus", "massa", "interdum", "orci", "non", "imperdiet", "orci", "ante", "at", "ipsum", "etiam", "eget", "magna", "mauris", "at", "tortor", "eu", "lectus", "tempor", "tincidunt", "phasellus", "justo", "purus", "pharetra", "ut", "ultricies", "nec", "consequat", "vel", "nisi", "fusce", "vitae", "velit", "at", "libero", "sollicitudin", "sodales", "aenean", "mi", "libero", "ultrices", "id", "suscipit", "vitae", "dapibus", "eu", "metus", "aenean", "vestibulum", "nibh", "ac", "massa", "vivamus", "vestibulum", "libero", "vitae", "purus", "in", "hac", "habitasse", "platea", "dictumst", "curabitur", "blandit", "nunc", "non", "arcu", "ut", "nec", "nibh", "morbi", "quis", "leo", "vel", "magna", "commodo", "rhoncus", "donec", "congue", "leo", "eu", "lacus", "pellentesque", "at", "erat", "id", "mi", "consequat", "congue", "praesent", "a", "nisl", "ut", "diam", "interdum", "molestie", "fusce", "suscipit", "rhoncus", "sem", "donec", "pretium", "aliquam", "molestie", "vivamus", "et", "justo", "at", "augue", "aliquet", "dapibus", "pellentesque", "felis", "morbi", "semper", "in", "venenatis", "imperdiet", "neque", "donec", "auctor", "molestie", "augue", "nulla", "id", "arcu", "sit", "amet", "dui", "lacinia", "convallis", "proin", "tincidunt", "proin", "a", "ante", "nunc", "imperdiet", "augue", "nullam", "sit", "amet", "arcu", "quisque", "laoreet", "viverra", "felis", "lorem", "ipsum", "dolor", "sit", "amet", "consectetuer", "adipiscing", "elit", "in", "hac", "habitasse", "platea", "dictumst", "pellentesque", "habitant", "morbi", "tristique", "senectus", "et", "netus", "et", "malesuada", "fames", "ac", "turpis", "egestas", "class", "aptent", "taciti", "sociosqu", "ad", "litora", "torquent", "per", "conubia", "nostra", "per", "inceptos", "hymenaeos", "nullam", "nibh", "sapien", "volutpat", "ut", "placerat", "quis", "ornare", "at", "lorem", "class", "aptent", "taciti", "sociosqu", "ad", "litora", "torquent", "per", "conubia", "nostra", "per", "inceptos", "hymenaeos", "morbi", "dictum", "massa", "id", "libero", "ut", "neque", "phasellus", "tincidunt", "nibh", "ut", "tincidunt", "lacinia", "lacus", "nulla", "aliquam", "mi", "a", "interdum", "dui", "augue", "non", "pede", "duis", "nunc", "magna", "vulputate", "a", "porta", "at", "tincidunt", "a", "nulla", "praesent", "facilisis", "suspendisse", "sodales", "feugiat", "purus", "cras", "et", "justo", "a", "mauris", "mollis", "imperdiet", "morbi", "erat", "mi", "ultrices", "eget", "aliquam", "elementum", "iaculis", "id", "velit", "in", "scelerisque", "enim", "sit", "amet", "turpis", "sed", "aliquam", "odio", "nonummy", "ullamcorper", "mollis", "lacus", "nibh", "tempor", "dolor", "sit", "amet", "varius", "sem", "neque", "ac", "dui", "nunc", "et", "est", "eu", "massa", "eleifend", "mollis", "mauris", "aliquet", "orci", "quis", "tellus", "ut", "mattis", "praesent", "mollis", "consectetuer", "quam", "nulla", "nulla", "nunc", "accumsan", "nunc", "sit", "amet", "scelerisque", "porttitor", "nibh", "pede", "lacinia", "justo", "tristique", "mattis", "purus", "eros", "non", "velit", "aenean", "sagittis", "commodo", "erat", "aliquam", "id", "lacus", "morbi", "vulputate", "vestibulum", "elit"}

property defaultLowEndWordCharacterCount : 1
property defaultHighEndWordCharacterCount : 10
property defaultLowEndSentenceWordCount : 3
property defaultHighEndSentenceWordCount : 12
property defaultLowEndParagraphSentenceCount : 1
property defaultHighEndParagraphSentenceCount : 6



(*
	randomWord()
	randomWords(8, true)
	randomString(9)
	randomSentence()
	randomSentenceWithWordRange(3, 12)
	randomParagraph()
	randomParagraphWithSentenceRange(3, 6)
	randomParagraphWithSentenceRangeWordRange(4, 7, 4, 10)

*)

on randomWord()
	return some item of loremWords
end randomWord

on randomWords(numberOfWords, shouldCapitalize)
	set wordArray to {}
	repeat with i from 1 to the numberOfWords
		set the end of wordArray to randomWord()
	end repeat
	if shouldCapitalize is true then
		return convertToLocalizedCapitalizedStrings(wordArray)
	else
		return wordArray
	end if
end randomWords

on randomString(numberOfWords)
	if numberOfWords is less than 1 then set numberOfWords to 1
	repeat with i from 1 to numberOfWords
		if i is 1 then
			set aString to some item of loremWords
		else
			set aString to aString & space & some item of loremWords
		end if
	end repeat
	return aString
end randomString

on randomSentence()
	set numberOfWords to random number from defaultLowEndSentenceWordCount to defaultHighEndSentenceWordCount
	set aString to randomString(numberOfWords)
	set aCharacter to character 1 of aString
	set aCharacter to item 1 of convertToLocalizedCapitals({aCharacter})
	set aString to aCharacter & text 2 thru -1 of aString & "."
end randomSentence

on randomSentenceWithWordRange(lowValue, highValue)
	set numberOfWords to random number from lowValue to highValue
	set aString to randomString(numberOfWords)
	set aCharacter to character 1 of aString
	set aCharacter to item 1 of convertToLocalizedCapitals({aCharacter})
	set aString to aCharacter & text 2 thru -1 of aString & "."
end randomSentenceWithWordRange

on randomParagraph()
	set numberOfSentences to random number from defaultLowEndParagraphSentenceCount to defaultHighEndParagraphSentenceCount
	repeat with i from 1 to numberOfSentences
		if i is 1 then
			set aString to randomSentence()
		else
			set aString to aString & space & randomSentence()
		end if
	end repeat
end randomParagraph

on randomParagraphWithSentenceRange(lowValue, highValue)
	set numberOfSentences to random number from lowValue to highValue
	repeat with i from 1 to numberOfSentences
		if i is 1 then
			set aString to randomSentence()
		else
			set aString to aString & space & randomSentence()
		end if
	end repeat
end randomParagraphWithSentenceRange

on randomParagraphWithSentenceRangeWordRange(sentenceLowValue, sentenceHighValue, wordLowValue, wordHighValue)
	set numberOfSentences to random number from sentenceLowValue to sentenceHighValue
	repeat with i from 1 to numberOfSentences
		if i is 1 then
			set aString to randomSentence()
		else
			set aString to aString & space & randomSentenceWithWordRange(wordLowValue, wordHighValue)
		end if
	end repeat
end randomParagraphWithSentenceRangeWordRange

on generateNSentences(sentenceCount)
	repeat with i from 1 to sentenceCount
		if i is 1 then
			set textBlock to randomSentence()
		else
			set textBlock to textBlock & space & randomSentence()
		end if
	end repeat
	return textBlock
end generateNSentences

on generateNParagraphs(paragraphCount)
	repeat with i from 1 to paragraphCount
		if i is 1 then
			set textBlock to randomParagraph()
		else
			set textBlock to textBlock & return & randomParagraph()
		end if
	end repeat
	return textBlock
end generateNParagraphs

on placeNParagraphsOnClipboard(paragraphCount)
	set aString to generateNParagraphs(paragraphCount)
	set the clipboard to aString
	announceCompletion()
end placeNParagraphsOnClipboard

on pasteMatchingStyleNParagrapshFromClipboard(paragraphCount)
	set aString to generateNParagraphs(paragraphCount)
	set the clipboard to aString
	tell application "System Events" to keystroke "v" using {command down, option down, shift down}
	announceCompletion()
end pasteMatchingStyleNParagrapshFromClipboard

on pasteNParagrapshFromClipboard(paragraphCount)
	set aString to generateNParagraphs(paragraphCount)
	set the clipboard to aString
	tell application "System Events" to keystroke "v" using {command down}
	announceCompletion()
end pasteNParagrapshFromClipboard

on replacePagesTextPlaceholdersWithLoremIpsum(sentenceLowValue, sentenceHighValue, wordLowValue, wordHighValue)
	tell application id "com.apple.iWork.Pages"
		activate
		if not (exists document 1) then error number -128
		tell front document
			set theseTags to the tag of every placeholder text
			repeat with i from 1 to the count of theseTags
				set thisTag to item i of theseTags
				tell script "Lorem Ipsum"
					set aString to randomParagraphWithSentenceRangeWordRange(2, 3, 3, 6)
				end tell
				set (every placeholder text whose tag is thisTag) to aString
			end repeat
		end tell
	end tell
	announceCompletion()
end replacePagesTextPlaceholdersWithLoremIpsum


(* SUPPORT HANDLERS *)

on convertToLocalizedCapitals(listOfStrings)
	set thisLocale to current application's NSLocale's currentLocale()
	repeat with i from 1 to count of listOfStrings
		set aString to (current application's NSString's stringWithString:(item i of listOfStrings))
		set item i of listOfStrings to (aString's uppercaseStringWithLocale:thisLocale) as text
	end repeat
	return listOfStrings
end convertToLocalizedCapitals

on convertToLocalizedCapitalizedStrings(listOfStrings)
	set thisLocale to current application's NSLocale's currentLocale()
	repeat with i from 1 to count of listOfStrings
		set aString to (current application's NSString's stringWithString:(item i of listOfStrings))
		set item i of listOfStrings to (aString's capitalizedStringWithLocale:thisLocale) as text
	end repeat
	return listOfStrings
end convertToLocalizedCapitalizedStrings


on getLocalizedStringForKey(thisKey)
	set thisBundlePath to (path to me)
	set aLocalizedString to (localized string thisKey in bundle thisBundlePath)
	log aLocalizedString
	return aLocalizedString
end getLocalizedStringForKey

on announceCompletion()
	say (my getLocalizedStringForKey("SUCCESSFUL_COMPLETION_PHRASE")) with stopping current speech
end announceCompletion




