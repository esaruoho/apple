tell application "System Events"
	-- create an empty property list dictionary item
	set the parent_dictionary to make new property list item with properties {kind:record}
	-- create new property list file using the empty dictionary list item as contents
	set the plistfile_path to "~/Desktop/example.plist"
	set this_plistfile to make new property list file with properties {contents:parent_dictionary, name:plistfile_path}
	-- add new property list items of each of the supported types
	make new property list item at end of property list items of contents of this_plistfile with properties {kind:boolean, name:"booleanKey", value:true}
	make new property list item at end of property list items of contents of this_plistfile with properties {kind:date, name:"dateKey", value:current date}
	make new property list item at end of property list items of contents of this_plistfile with properties {kind:list, name:"listKey"}
	make new property list item at end of property list items of contents of this_plistfile with properties {kind:number, name:"numberKey", value:5}
	make new property list item at end of property list items of contents of this_plistfile with properties {kind:record, name:"recordKey"}
	make new property list item at end of property list items of contents of this_plistfile with properties {kind:string, name:"stringKey", value:"string value"}
end tell
