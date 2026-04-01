set the columnCount to 4
set the rowCount to 6
set the tableName to "Project Costs"

tell application "Numbers"
	activate
	
	if not (exists document 1) then error number -128
	
	tell the front document
		tell active sheet
			set tableName to my incrementTableNameIfNeeded(tableName, "-")
			set thisTable to make new table with properties ¬
				{column count:columnCount, row count:rowCount, name:tableName}
		end tell
	end tell
end tell

on incrementTableNameIfNeeded(thisTableName, thisDivider)
	-- a routine for deriving a unique table name based on a provided table name
	tell application "Numbers"
		tell the front document
			tell active sheet
				-- get a list of the names of the tables on the active sheet
				set the theseTableNames to the name of every table
				set the testTableName to the thisTableName
				set incrementor to 0
				-- increment the passed name, if needed
				repeat until testTableName is not in the theseTableNames
					set incrementor to incrementor + 1
					set the testTableName to ¬
						the thisTableName & thisDivider & (incrementor as string)
				end repeat
				-- return the non-conflicting table name
				return the testTableName
			end tell
		end tell
	end tell
end incrementTableNameIfNeeded
