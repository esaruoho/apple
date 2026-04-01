tell application "Keynote"
	
	-- STOP ANY PLAYING PRESENTATION
	if playing is true then stop the front document
	
	activate
	
	-- MAKE NEW DOCUMENT
	set thisDocument to make new document with properties ¬
		{height:764, width:1024, document theme:theme "Black"}
	
	tell thisDocument
		
		-- THE SOURCE DATA
		set rowNames to {"ROW A", "ROW B", "ROW C"}
		set columnNames to {"COL 1", "COL 2", "COL 3", "COL 4"}
		set rowCount to count of rowNames
		set columnCount to count of columnNames
		set thisData to my generateRandomData(rowCount, columnCount)
		
		-- THE EXISTING SLIDE
		tell slide 1
			set the base slide to master slide "Title - Top" of thisDocument
			set the object text of the default title item to "Table"
			
			-- MAKE A TABLE FROM DATA
			-- include headers in counts
			set the rowCount to (the count of thisData) + 1
			set the columnCount to (the count of (item 1 of thisData)) + 1
			
			-- make the table
			set thisTable to ¬
				make new table with properties ¬
					{row count:rowCount, column count:columnCount}
			
			-- populate the table
			tell thisTable
				-- column headers
				repeat with i from 1 to the the count of the columnNames
					set the value of cell (i + 1) of row 1 to item i of columnNames
				end repeat
				
				-- row headers
				repeat with i from 1 to the the count of the rowNames
					set the value of cell (i + 1) of column 1 to item i of rowNames
				end repeat
				
				-- insert data, which is assumed to be grouped by rows
				repeat with q from 1 to the count of thisData
					set thisDataItem to item q of thisData
					repeat with i from 1 to the the count of thisDataItem
						set the value of cell (i + 1) of row (q + 1) to item i of thisDataItem
					end repeat
				end repeat
			end tell
		end tell
		
		-- MAKE NEW SLIDE
		set thisSlide to make new slide with properties {base slide:master slide "Title - Top"}
		tell thisSlide
			set the object text of the default title item to "Grouped by Column"
			
			-- MAKE A CHART FROM DATA (GROUPED BY COLUMN)
			add chart row names rowNames column names columnNames ¬
				data thisData type line_2d group by chart column
		end tell
		
		-- MAKE NEW SLIDE
		set thisSlide to make new slide with properties {base slide:master slide "Title - Top"}
		tell thisSlide
			set the object text of the default title item to "Grouped by Row"
			
			-- MAKE A CHART FROM DATA (GROUPED BY ROW)
			add chart row names rowNames column names columnNames ¬
				data thisData type line_2d group by chart row
		end tell
	end tell
	
	-- PLAY THE PRESENTATION
	start thisDocument from first slide of thisDocument
	
end tell

-- SUB-ROUTINE FOR GENERATING RANDOM ROW/COLUMN DATA
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
