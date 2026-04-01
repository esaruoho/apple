set the columnCount to 8
set the rowCount to 10
set the headerRowCount to 0
set the headerColumnCount to 0
set the footerRowCount to 0

tell application "Keynote"
	activate
	
	set thisDocument to ¬
		make new document with properties ¬
			{document theme:theme "Black", width:1024, height:768}
	
	tell thisDocument
		tell current slide
			set base slide to master slide "Blank" of thisDocument
			set thisTable to ¬
				make new table with properties ¬
					{column count:columnCount ¬
						, row count:rowCount ¬
						, footer row count:footerRowCount ¬
						, header column count:headerColumnCount ¬
						, header row count:headerRowCount}
			tell thisTable
				set format of cell range to percent
				repeat with i from 1 to the count of cells
					set the value of cell i to ((random number from 0 to 100) * 0.01)
				end repeat
			end tell
		end tell
	end tell
end tell
