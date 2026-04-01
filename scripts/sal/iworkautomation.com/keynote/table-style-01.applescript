tell application "Keynote"
	activate
	tell document 1
		set documentWidth to its width
		set documentHeight to its height
		
		tell current slide
			-- make a new table
			set thisTable to ¬
				make new table with properties ¬
					{header column count:1 ¬
						, header row count:1 ¬
						, row count:4 ¬
						, column count:4 ¬
						, name:"ACME Widget Prices"}
			
			tell thisTable
				-- set the vertical alignment of all table cells
				set vertical alignment of cell range to center
				
				-- set the properties of the headers
				tell first row
					-- cell properties
					set the background color to {26214, 26214, 39321}
					set height to 48
					-- text properties
					set the font name to "Impact"
					set the font size to 32
					set text color to {65535, 65535, 65535}
					set the alignment to center
				end tell
				
				tell first column
					-- cell properties
					set the background color to {26214, 26214, 39321}
					set width to 150
					-- text properties
					set the font name to "Impact"
					set the font size to 32
					set text color to {65535, 65535, 65535}
					set the alignment to right
				end tell
				
				-- set header content
				set headerColumnTitles to {"", "JAPAN", "USA", "EUROPE"}
				set headerRowTitles to {"", "WIDGET A", "WIDGET B", "WIDGET C"}
				tell the first row
					repeat with i from 1 to the count of cells
						set the value of cell i to item i of headerColumnTitles
					end repeat
				end tell
				tell the first column
					repeat with i from 1 to the count of cells
						set the value of cell i to item i of headerRowTitles
					end repeat
				end tell
				
				-- set content range properties
				set nameOfLastCell to the name of the last cell
				set contentRange to ("B2:" & nameOfLastCell)
				tell range contentRange
					set rangeCellIDs to the name of every cell
					-- cell properties
					set the background color to {65535, 65535, 65535}
					-- text properties
					set the font name to "Helvetica"
					set the font size to 32
					set text color to {0, 0, 0}
					set the alignment to center
					set format to text
				end tell
				
				-- set content range content
				set the pricingData to ¬
					{"¥121280", "$1495", "€1170", "¥190238", "$2345", "€1835", "¥263656", "$3250", "€2542"}
				repeat with i from 1 to the count of rangeCellIDs
					tell cell (item i of rangeCellIDs)
						set the value to (item i of pricingData)
						set format to currency
					end tell
				end repeat
				
				-- set table properties
				set tableWidth to its width
				set tableHeight to its height
				set position to ¬
					{(documentWidth - tableWidth) div 2 ¬
						, (documentHeight - tableHeight) div 2}
			end tell
		end tell
	end tell
end tell
