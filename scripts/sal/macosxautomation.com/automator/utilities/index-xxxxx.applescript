use framework "Foundation"
use framework "AppKit"
use scripting additions

property ignoredVolumes : {"home", "net", "Recovery HD"}

global pathToWorkflow

on run
	-- SET VALUE OF PROPERTY TO STORED WORKFLOW PATH
	my initializeDefaults()
	
	-- CHECK STATUS OF STORED WORKFLOW PATH
	if (pathToWorkflow as text) is "" then
		my promptForWorkflow()
	else
		-- DISPLAY OPENING DIALOG
		display dialog "Workflow file: " & return & return & (pathToWorkflow as text) buttons {"Quit", "Change", "Start"} default button 3 with title (name of me)
		set buttonPressed to the button returned of the result
		if the buttonPressed is "Change" then
			-- prompt for a new workflow
			my promptForWorkflow()
		else if buttonPressed is "Quit" then
			tell me to quit
		else -- check to see if workflow file exists
			if my workflowCheck() is false then
				display alert "MISSING RESOURCE" message "There is no workflow file at the indicated path:" & ¬
					return & return & pathToWorkflow buttons {"Select", "Quit"} default button 2
				if button returned of the result is "Quit" then
					tell me to quit
				end if
				-- prompt for a new workflow
				my promptForWorkflow()
			end if
		end if
	end if
	
	-- REGISTER FOR NOTIFICATION
	my registerToReceiveNotification()
	
end run

on initializeDefaults()
	-- Initialize default if needed, retrieve current value
	tell current application's NSUserDefaults to set defaults to standardUserDefaults()
	tell defaults to registerDefaults:{pathToWorkflow:""}
	-- set the value of the applet property to the stored value
	tell defaults to set pathToWorkflow to (objectForKey_("pathToWorkflow")) as text
end initializeDefaults

on workflowCheck()
	-- check validity of stored path
	-- create an instance of the Shared Workspace
	set workspace to current application's NSWorkspace's sharedWorkspace()
	-- check for existence
	set fileExistenceStatus to (workspace's isFilePackageAtPath:pathToWorkflow)
	-- return result
	return fileExistenceStatus
end workflowCheck

on promptForWorkflow()
	-- prompt user to choose a workflow file
	try
		activate
		set workflowsFolderPath to checkForWorkflowsFolder()
		if workflowsFolderPath is false then
			set defaultLocation to (path to desktop folder)
		else
			set defaultLocation to workflowsFolderPath as POSIX file as alias
		end if
		set thisPOSIXPath to POSIX path of ¬
			(choose file of type "com.apple.automator-workflow" with prompt ¬
				"Select the workflow to be run when a volume is mounted:" default location defaultLocation)
		tell current application's NSUserDefaults to set defaults to standardUserDefaults()
		tell defaults to setObject:thisPOSIXPath forKey:"pathToWorkflow"
		return thisPOSIXPath
	on error
		tell me to quit
	end try
end promptForWorkflow

on checkForWorkflowsFolder()
	set aFileManager to current application's class "NSFileManager"'s defaultManager()
	set aURL to aFileManager's URLsForDirectory:(current application's NSLibraryDirectory) inDomains:(current application's NSUserDomainMask)
	set workflowsFolderPath to (((item 1 of aURL)'s |path|()) as string) & "/Workflows"
	if (aFileManager's fileExistsAtPath:workflowsFolderPath isDirectory:true) then
		return workflowsFolderPath
	else
		return false
	end if
end checkForWorkflowsFolder

on registerToReceiveNotification()
	-- create an instance of the Shared Workspace
	set workspace to current application's NSWorkspace's sharedWorkspace()
	-- identify the Shared Workspace's notification center
	set noteCenter to workspace's notificationCenter()
	-- register notification handlers for dealing with volume mounting
	noteCenter's addObserver:me selector:"volumeWasMounted:" |name|:"NSWorkspaceDidMountNotification" object:(missing value)
end registerToReceiveNotification

on volumeWasMounted:notif
	-- CHECK FOR WORKFLOW FILE
	if my workflowCheck() is false then
		my promptForWorkflow()
	end if
	
	-- get the path to the mounted volume
	set mountedVolumePath to (notif's userInfo()'s NSWorkspaceVolumeURLKey's |path|())
	-- get last path item
	set thisVolumeName to (mountedVolumePath's lastPathComponent()) as text
	
	if thisVolumeName is not in ignoredVolumes then
		-- display alert
		tell application (POSIX path of (path to frontmost application))
			display dialog "The volume “" & thisVolumeName & "” has been mounted on this system." & ¬
				return & return & "Do you want to run the associated workflow?" buttons {"No", "Yes"} default button 2
			if the button returned of the result is "No" then error number -128
		end tell
		
		-- RUN WORKFLOW
		try
			-- execute the chosen workflow, passing path to volume as workflow input
			do shell script "automator -i " & (quoted form of (mountedVolumePath as text)) & ¬
				space & (quoted form of (pathToWorkflow as text))
		on error errorMessage
			activate
			display alert "WORKFLOW EXECUTION ERROR" message errorMessage
			tell me to quit
		end try
	end if
end volumeWasMounted:
