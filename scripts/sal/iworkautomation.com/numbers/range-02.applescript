tell application "Numbers"
	activate
	tell document 1
		tell active sheet
			set thisTable to ¬
				make new table with properties {row count:10, column count:12}
			tell thisTable
				set the width of every column to 36
				set the height of every row to 24
				set alignment of every cell to center
				set vertical alignment of every cell to center
				repeat with i from 1 to the count of cells
					set the value of cell i to (the name of cell i)
				end repeat
			end tell
		end tell
	end tell
end tell
