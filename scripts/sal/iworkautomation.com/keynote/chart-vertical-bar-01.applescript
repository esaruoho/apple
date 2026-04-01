tell application "Keynote"
	
	if playing is true then stop the front document
	
	activate
	
	set thisDocument to make new document with properties ¬
		{height:764, width:1024, document theme:theme "Black"}
	
	tell thisDocument
		
		set rowNames to {"ROW 1", "ROW 2", "ROW 3"}
		set columnNames to {"COL A", "COL B", "COL C", "COL D"}
		set rowCount to count of rowNames
		set columnCount to count of columnNames
		set chartData to my generateRandomData(rowCount, columnCount)
		
		tell slide 1
			set the base slide to master slide "Title - Top" of thisDocument
			set the object text of the default title item to "Grouped by Column"
			
			add chart row names rowNames column names columnNames ¬
				data chartData type vertical_bar_2d group by chart column
		end tell
		
		set thisSlide to ¬
			make new slide with properties {base slide:master slide "Title - Top"}
		tell thisSlide
			set the object text of the default title item to "Grouped by Row"
			
			add chart row names rowNames column names columnNames ¬
				data chartData type vertical_bar_2d group by chart row
		end tell
		
	end tell
	
	start thisDocument from first slide of thisDocument
	
end tell

on generateRandomData(rowCount, columnCount)
	set thisData to {}
	repeat rowCount times
		set thisDataItem to {}
		repeat columnCount times
			set thisValue to random number from 0 to 100
			set the end of thisDataItem to thisValue
		end repeat
		set the end of thisData to thisDataItem
	end repeat
	return thisData
end generateRandomData
