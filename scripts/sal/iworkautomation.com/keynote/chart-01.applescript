tell application "Keynote"
	activate
	
	set thisDocument to make new document with properties ¬
		{height:764, width:1024, document theme:theme "Black"}
	
	tell thisDocument
		tell slide 1
			set the base slide to master slide "Title - Top" of thisDocument
			set the object text of the default title item to "2D Pie Chart"
			add chart row names {"ROW A"} column names {"COL A", "COL B", "COL C"} ¬
				data {{45, 25, 30}} type pie_2d group by chart column
		end tell
	end tell
end tell
