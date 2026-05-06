/*

Copyright _ 2005, Apple Computer, Inc.  All rights reserved.
NOTE:  Use of this source code is subject to the terms of the Software
License Agreement for Mac OS X, which accompanies the code.  Your use
of this source code signifies your agreement to such license terms and
conditions.  Except as expressly granted in the Software License Agreement
for Mac OS X, no other copyright, patent, or other intellectual property
license or right is granted, either expressly or by implication, by Apple.

*/

var currentlyRunningScript = null;

// setup() is called when the body of the widget is loaded.  This function places the localized
// strings into the widget.

function setup()
{
	if(window.widget) {
		currentlyRunningScript = widget.system("/usr/bin/osascript -e 'beep 2'" , doneRunningScript);
	}
}

function menuChanged(elem)
{
	var chosenMenuItem = elem.options[elem.selectedIndex].value;
	elem.selectedIndex = 0;
	document.getElementById("popupMenuText").innerText = "Open folder...";
	
	if(window.widget) {
		closeWindows = document.getElementById('closeWindowsCheckbox').checked;
		
		if (closeWindows) {
		
			if( currentlyRunningScript != null) {
				doneRunningScript();
			}
			else if(chosenMenuItem == "Applications-Computer"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to applications folder)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Applications-User"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to applications folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Documents"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to documents folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Home"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open home\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Library-Computer"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to library folder from local domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Library-User"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to library folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Movies"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to movies folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Music"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to music folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Pictures"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to pictures folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Public"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to public folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Preferences-Computer"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to preferences folder from local domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Preferences-User"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to preferences folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Scripts-Computer"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to scripts folder from local domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Scripts-User"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to scripts folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Shared"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to shared documents folder)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Sites"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to sites folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Startup Disk"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open startup disk\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Utilities"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to utilities folder)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Workflows-Computer"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to workflows folder from local domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Workflows-User"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to close every window\rtell application \"Finder\" to open (path to workflows folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
		}
		else {
		
			if( currentlyRunningScript != null) {
				doneRunningScript();
			}
			else if(chosenMenuItem == "Applications-Computer"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to applications folder)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Applications-User"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to applications folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Documents"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to documents folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Home"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open home\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Library-Computer"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to library folder from local domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Library-User"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to library folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Movies"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to movies folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Music"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to music folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Pictures"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to pictures folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Public"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to public folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Preferences-Computer"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to preferences folder from local domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Preferences-User"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to preferences folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Scripts-Computer"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to scripts folder from local domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Scripts-User"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to scripts folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Shared"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to shared documents folder)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Sites"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to sites folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Startup Disk"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open startup disk\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Utilities"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to utilities folder)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Workflows-Computer"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to workflows folder from local domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
			else if(chosenMenuItem == "Workflows-User"){
				currentlyRunningScript = widget.system("/usr/bin/osascript -e 'tell application \"Finder\" to set visible of (every process whose visible is true and creator type is not \"MACS\") to false\rtell application \"Finder\" to open (path to workflows folder from user domain)\rtell application \"System Events\" to key code 111'" , doneRunningScript);	
			}
		
		}
	}
}

function doneRunningScript()
{
	currentlyRunningScript = null;
}

