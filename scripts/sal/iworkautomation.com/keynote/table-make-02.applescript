set the columnCount to 4
set the rowCount to 6
set the headerRowCount to 1
set the headerColumnCount to 0
set the footerRowCount to 1

tell application "Keynote"
	activate
	
	if not (exists document 1) then error number -128
	
	tell document 1
		tell current slide
			set thisTable to ¬
				make new table with properties ¬
					{column count:columnCount ¬
						, row count:rowCount ¬
						, footer row count:footerRowCount ¬
						, header column count:headerColumnCount ¬
						, header row count:headerRowCount}
		end tell
	end tell
end tell
