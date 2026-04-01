set rowCount to 10
set columnCount to 12
tell application "Numbers"
	activate
	if not (exists document 1) then make new document
	tell the front document
		tell active sheet
			set thisTable to ¬
				make new table with properties ¬
					{row count:rowCount, column count:columnCount}
			tell thisTable
				-- style the cells of the table
				set the width of every column to 60
				set the height of every row to 40
				set alignment of every cell to center
				set vertical alignment of every cell to center
				set font size of every cell to 16
				repeat with i from 1 to the count of cells
					-- show the address of the cell
					set value of cell i to (name of cell i)
					-- generate a random background color
					set RcolorValue to random number from 0 to 65535
					set GcolorValue to random number from 0 to 65535
					set BcolorValue to random number from 0 to 65535
					-- set the background color of the cell
					set the background color of cell i to ¬
						{RcolorValue, GcolorValue, BcolorValue}
					-- ensure that text color will constrast with background color
					if RcolorValue is greater than 32767 then
						set RcolorValue to 0
					else
						set RcolorValue to 65535
					end if
					if GcolorValue is greater than 32767 then
						set GcolorValue to 0
					else
						set GcolorValue to 65535
					end if
					if BcolorValue is greater than 32767 then
						set BcolorValue to 0
					else
						set BcolorValue to 65535
					end if
					-- set the color of the text
					set the text color of cell i to ¬
						{RcolorValue, GcolorValue, BcolorValue}
				end repeat
			end tell
		end tell
	end tell
end tell
