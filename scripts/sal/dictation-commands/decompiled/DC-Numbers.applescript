use framework "Foundation"
use framework "AppKit"
use scripting additions

(* targetChartTypeIndicator:
	1 ‌Area 2D
	2 ‌Area 3D
	3 ‌Horizontal Bar 2D
	4 ‌Horizontal Bar 3D
	5 ‌Line 2D
	6 ‌Line 3D
	7 Pie 2D
	8 ‌Pie 3D
	9 ‌Scatterplot 2D
	10 ‌Stacked Area 2D
	11 ‌Stacked Area 3D
	12 ‌Stacked Horizontal Bar 2D
	13 ‌Stacked Horizontal Bar 3D
	14 ‌Stacked Vertical Bar 2D
	15 ‌Stacked Vertical Bar 3D
	16 ‌Vertical Bar 2D
	17 ‌Vertical Bar 3D
*)
(* dataSourceIndicator 0 = table, 1 = table selection *)
(* groupingMethodIndicator 1 = row, 2 = column *)

on exportNumbersTableToKeynoteAsChart()
	(* 2D CHART *)
	set dataSourceIndicator to 0 -- 0 = table, 1 = table selection
	set targetChartTypeIndicator to 16
	set groupingMethodIndicator to 2 -- 1 = row, 2 = column
	set shouldUseTableNameForSlideTitle to true
	
	my newKeynoteChartUsingDataFromNumbersTable(shouldUseTableNameForSlideTitle, dataSourceIndicator, targetChartTypeIndicator, groupingMethodIndicator)
end exportNumbersTableToKeynoteAsChart

on exportNumbersTableSelectionToKeynoteAsPieChart()
	(* PIE CHART *)
	set dataSourceIndicator to 1 -- 0 = table, 1 = table selection
	set targetChartTypeIndicator to 7
	set groupingMethodIndicator to 1
	set shouldUseTableNameForSlideTitle to true
	
	my newKeynoteChartUsingDataFromNumbersTable(shouldUseTableNameForSlideTitle, dataSourceIndicator, targetChartTypeIndicator, groupingMethodIndicator)
end exportNumbersTableSelectionToKeynoteAsPieChart

on newKeynoteChartUsingDataFromNumbersTable(shouldUseTableNameForSlideTitle, dataSourceIndicator, targetChartTypeIndicator, groupingMethodIndicator)
	try
		tell application id "com.apple.iWork.Keynote"
			if not (exists document 1) then
				error "NO_KEYNOTE_DOCUMENT"
			end if
		end tell
		
		tell application id "com.apple.iWork.Numbers"
			if not (exists document 1) then
				error "NO_NUMBERS_DOCUMENT"
			end if
			tell document 1
				## IDENTIFYING NUMBERS TABLE
				try -- check for selected table
					tell active sheet
						set the targetTable to (the first table whose class of selection range is range)
					end tell
				on error
					error "NO_TABLE_SELECTED"
				end try
				
				## GETTING DATA FROM NUMBERS TABLE
				tell targetTable
					set thisTableName to its name
					my logThis("targetTableName: " & thisTableName)
					-- get the count fo the various headers and footers
					set the headerColumnCount to header column count
					my logThis("headerColumnCount: " & headerColumnCount)
					set the headerRowCount to header row count
					my logThis("headerRowCount: " & headerRowCount)
					set the footerRowCount to footer row count
					my logThis("footerRowCount: " & footerRowCount)
					
					
					if dataSourceIndicator is 1 then -- selection of active table
						-- store references to the intersecting columns and rows
						set theseRows to the rows of the selection range
						set theseColumns to the columns of the selection range
						
						-- get the row and column counts
						set rowCount to (count of theseRows)
						set columnCount to (count of theseColumns)
						
						if targetChartTypeIndicator is in {7, 8} then -- pie chart
							-- check for errors
							if (rowCount is not 1) and (columnCount is not 1) then
								error "21002"
							else if (rowCount is 1) and (columnCount is 1) then
								error "21002"
							end if
							if headerRowCount is greater than 1 then
								error "21003"
							end if
							if headerColumnCount is greater than 1 then
								error "21004"
							end if
						end if
						
						if targetChartTypeIndicator is in {7, 8} then -- pie chart
							-- get the column names
							set columnNames to {}
							if headerColumnCount is not 0 then
								repeat with i from 1 to the count of theseColumns
									set thisValue to (the value of the first cell of (item i of theseColumns))
									if thisValue is not missing value then
										set the end of columnNames to thisValue
									end if
								end repeat
							end if
							my logThis("columnNames: " & my listToStringedList(columnNames))
							
							-- get the row names
							set rowNames to {}
							if headerRowCount is not 0 then
								repeat with i from 1 to the count of theseRows
									set thisValue to (the value of the first cell of (item i of theseRows))
									if thisValue is not missing value then
										set the end of rowNames to thisValue
									end if
								end repeat
							end if
							my logThis("rowNames: " & my listToStringedList(rowNames))
						else -- not a pie chart
							-- get the column names
							set columnNames to {}
							if headerColumnCount is 1 then
								repeat with i from 1 to the count of theseColumns
									set thisValue to (the value of the first cell of (item i of theseColumns))
									if thisValue is not missing value then
										set the end of columnNames to thisValue
									end if
								end repeat
							else -- use the Column IDs
								repeat with i from 1 to the count of theseColumns
									set thisValue to the name of (item i of theseColumns)
									if thisValue is not missing value then
										set the end of columnNames to thisValue
									end if
								end repeat
							end if
							my logThis("columnNames: " & my listToStringedList(columnNames))
							
							-- get the row names
							set rowNames to {}
							if headerRowCount is 1 then
								repeat with i from 1 to the count of theseRows
									set thisValue to (the value of the first cell of (item i of theseRows))
									if thisValue is not missing value then
										set the end of rowNames to thisValue
									end if
								end repeat
							else -- use row IDs
								repeat with i from 1 to the count of theseRows
									set thisValue to the name of (item i of theseRows)
									if thisValue is not missing value then
										set the end of rowNames to thisValue
									end if
								end repeat
							end if
							my logThis("rowNames: " & my listToStringedList(rowNames))
						end if
						
						-- GET TABLE DATA
						if targetChartTypeIndicator is in {7, 8} then -- pie chart
							if rowCount is greater than columnCount then
								-- a column is selected
								set thisColumn to item 1 of theseColumns
								set footerOffset to ((1 + footerRowCount) * -1)
								set tableData to ¬
									{(the value of cells (headerColumnCount + 1) thru footerOffset of thisColumn)}
							else
								-- a row is selected
								set thisRow to item 1 of theseRows
								set footerOffset to ((1 + footerRowCount) * -1)
								set tableData to ¬
									{(the value of cells (headerRowCount + 1) thru footerOffset of thisRow)}
							end if
							tell current application to log tableData
						else -- not a pie chart
							-- get the table data
							set tableData to {}
							repeat with i from 1 to rowCount
								set thisRow to item i of theseRows
								set thisDataSet to ¬
									(the value of cells (headerRowCount + 1) thru -1 of thisRow)
								set the end of the tableData to thisDataSet
							end repeat
						end if
					else -- get data of whole table
						-- get column names
						set columnNames to {}
						set columnCount to the count of columns
						if headerColumnCount is 1 then
							repeat with i from 1 to the columnCount
								set thisValue to (the value of the first cell of column i)
								if thisValue is not missing value then
									set the end of columnNames to thisValue
								end if
							end repeat
						else -- use the Column IDs
							repeat with i from 1 to the columnCount
								set thisValue to the name of column i
								if thisValue is not missing value then
									set the end of columnNames to thisValue
								end if
							end repeat
						end if
						my logThis("columnNames: " & my listToStringedList(columnNames))
						
						-- get the row names
						set rowNames to {}
						set rowCount to the count of rows
						if headerRowCount is 1 then
							repeat with i from 1 to the rowCount
								set thisValue to (the value of the first cell of row i)
								if thisValue is not missing value then
									set the end of rowNames to thisValue
								end if
							end repeat
						else -- use row IDs
							repeat with i from 1 to the rowCount
								set thisValue to the name of row i
								if thisValue is not missing value then
									set the end of rowNames to thisValue
								end if
							end repeat
						end if
						my logThis("rowNames: " & my listToStringedList(rowNames))
						
						-- get the table data
						set tableData to {}
						repeat with i from (headerRowCount + 1) to rowCount
							set thisRow to row i
							set thisDataSet to (the value of cells (headerColumnCount + 1) thru -1 of thisRow)
							set the end of the tableData to thisDataSet
						end repeat
					end if
				end tell
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Numbers")
		end if
		error number -128
	end try
	
	try
		tell application id "com.apple.iWork.Keynote"
			activate
			
			set thisChartTypeEnumerator to item targetChartTypeIndicator of {«constant KCctare2», «constant KCctare3», «constant KCcthbr2», «constant KCcthbr3», «constant KCctlin2», «constant KCctlin3», «constant KCctpie2», «constant KCctpie3», «constant KCctscp2», «constant KCctsar2», «constant KCctsar3», «constant KCctshb2», «constant KCctshb3», «constant KCctsvb2», «constant KCctsvb3», «constant KCctvbr2», «constant KCctvbr3»}
			if targetChartTypeIndicator is in {7, 8} then -- pie chart
				set thisGroupingMethodEnumerator to «constant KCgbKCgc»
			else
				set thisGroupingMethodEnumerator to item groupingMethodIndicator of {«constant KCgbKCgr», «constant KCgbKCgc»}
			end if
			
			set masterSlideTitleForBlank to my getLocalizedStringForKey("KEYNOTE_BLANK_MASTER_TITLE")
			set masterSlideTitles to the name of every «class KnMs» of document 1
			if masterSlideTitleForBlank is in masterSlideTitles then
				tell front document
					set thisSLide to make new «class KnSd» with properties {«class smas»:«class KnMs» masterSlideTitleForBlank}
				end tell
			else
				error "KEYNOTE_BLANK_MASTER_DOES_NOT_EXIST"
			end if
			tell thisSLide
				if targetChartTypeIndicator is in {7, 8} then -- pie chart
					if rowCount is greater than columnCount then
						-- a column is selected, so reverse the names
						«event KntcAddc» given «class KCrn»:columnNames, «class KCcn»:rowNames, «class KCdt»:tableData, «class KCct»:thisChartTypeEnumerator, «class KCgb»:«constant KCgbKCgc»
						set titleExtra to the first item of columnNames
					else -- row is selected
						«event KntcAddc» given «class KCrn»:rowNames, «class KCcn»:columnNames, «class KCdt»:tableData, «class KCct»:thisChartTypeEnumerator, «class KCgb»:thisGroupingMethodEnumerator
						set titleExtra to the first item of rowNames
					end if
				else
					«event KntcAddc» given «class KCrn»:rowNames, «class KCcn»:columnNames, «class KCdt»:tableData, «class KCct»:thisChartTypeEnumerator, «class KCgb»:thisGroupingMethodEnumerator
				end if
				-- set the title
				if shouldUseTableNameForSlideTitle is true then
					set «class Ktsh» to true
					if targetChartTypeIndicator is in {7, 8} then
						set the «class pDTx» of the «class sdti» to (thisTableName & ": " & titleExtra)
					else
						set the «class pDTx» of the «class sdti» to thisTableName
					end if
				end if
			end tell
		end tell
	on error errorMessage number errorNumber
		if errorNumber is not -128 then
			my displaySpokenErrorAlert(errorMessage, "com.apple.iWork.Keynote")
		end if
		error number -128
	end try
end newKeynoteChartUsingDataFromNumbersTable

on selectFirstTableOnActiveSheet()
	tell application id "com.apple.iWork.Numbers"
		activate
		if not (exists document 1) then
			error "NO_NUMBERS_DOCUMENT"
		end if
		tell front document
			tell active sheet
				if (count of tables) is 0 then
					error "NO_TABLE_ON_CURRENT_SHEET"
				end if
				tell table 1
					set selection range to cell range
				end tell
			end tell
		end tell
	end tell
end selectFirstTableOnActiveSheet


(* SUPPORT HANDLERS *)

on logThis(thisText)
	log thisText
end logThis

on listToStringedList(thisList)
	set AppleScript's text item delimiters to "\", \""
	set combinedList to "\"" & (thisList as string) & "\""
	set AppleScript's text item delimiters to ""
	return combinedList
end listToStringedList

on getLocalizedStringForKey(thisKey)
	set thisBundlePath to (path to me)
	return (localized string thisKey in bundle thisBundlePath)
end getLocalizedStringForKey

on displaySpokenErrorAlert(errorKey, appID)
	if appID is "" or appID is missing value then
		set aWorkspace to current application's NSWorkspace's sharedWorkspace
		set frontmostApp to aWorkspace's frontmostApplication
		set appID to (frontmostApp's bundleIdentifier) as text
	end if
	try
		set errorTitle to getLocalizedStringForKey("ERROR_TITLE")
		set errorMessage to getLocalizedStringForKey(errorKey)
		set cancelButtonTitle to getLocalizedStringForKey("CANCEL_BUTTON_TITLE")
		tell current application
			say errorMessage without waiting until completion
		end tell
		tell application id appID
			activate
			display alert errorTitle message errorMessage buttons {cancelButtonTitle}
		end tell
		-- stop speaking
		say " " with stopping current speech
		return true
	on error errorMessage
		log errorMessage
		error number -128
	end try
end displaySpokenErrorAlert

on getPOSIXPathForItem(thisItemReference)
	(* This routine attempts to return a clean full POSIX path reference *)
	-- check class of input
	if the class of thisItemReference is alias then
		set thisItemReference to the POSIX path of thisItemReference
	else if the class of thisItemReference is «class furl» then
		set thisItemReference to the POSIX path of thisItemReference
	else if class of thisItemReference is string or class of thisItemReference is text then
		if thisItemReference begins with "'" and thisItemReference ends with "'" then
			-- remove single quotes
			set thisItemReference to text 2 thru -2 of thisItemReference
		end if
		if thisItemReference begins with "~" then
			set thisCocoaString to current application's NSString's stringWithString:thisItemReference
			set thisItemReference to (thisCocoaString's stringByExpandingTildeInPath()) as string
		end if
	end if
	return thisItemReference
end getPOSIXPathForItem

on checkForItemExistence(POSIXPathToItem)
	-- check validity of stored path
	set POSIXPathToItem to getPOSIXPathForItem(POSIXPathToItem)
	-- create an instance of the File Manager
	set thisFileManager to current application's NSFileManager's defaultManager()
	-- check for existence
	set fileExistenceStatus to (thisFileManager's fileExistsAtPath:POSIXPathToItem) as boolean
	-- return result
	return fileExistenceStatus
end checkForItemExistence




