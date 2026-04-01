tell application "Keynote"
	activate
	try
		set the chosenDocumentFile to ¬
			(choose file of type ¬
				{"com.apple.iwork.keynote.key", ¬
					"com.apple.iwork.keynote.kth", ¬
					"com.apple.iwork.keynote.sffkey", ¬
					"com.apple.iwork.keynote.key-tef", ¬
					"com.microsoft.powerpoint.ppt", ¬
					"org.openxmlformats.presentationml.presentation", ¬
					"org.openxmlformats.presentationml.presentation.macroenabled", ¬
					"com.microsoft.powerpoint.pps", ¬
					"org.openxmlformats.presentationml.slideshow", ¬
					"org.openxmlformats.presentationml.slideshow.macroenabled", ¬
					"com.microsoft.powerpoint.pot", ¬
					"org.openxmlformats.presentationml.template", ¬
					"org.openxmlformats.presentationml.template.macroenabled"} ¬
					default location (path to documents folder) ¬
				with prompt "Choose the Keynote, PowerPoint, or Open XML document to open:")
		open the chosenDocumentFile
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			display alert errorNumber message errorMessage
		end if
	end try
end tell
