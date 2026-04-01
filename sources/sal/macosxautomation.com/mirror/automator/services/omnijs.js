var originalContent = null;

function showPopup(elementID){
	// get the current window vertical scroll
	curVScroll = document.documentElement.scrollTop || document.body.scrollTop
	// disable scrolling
	document.body.style.overflow = "hidden";
	// locate the hidden script element by passed ID
	popUp = document.getElementById(elementID);
	// set position and dimensions
	popUp.style.top = "18px";
	popUp.style.left = "18px";
	popUp.style.width = "96%";
	popUp.style.height = "200px";
	// store two copies of content, one local, one global
	originalContent = popUp.innerHTML;
	curDivContent = popUp.innerHTML;
	// create content for popup view
	popUp.innerHTML = "<div id=\"statusbar\"><button onclick=\"hidePopup('" + elementID + "'," + curVScroll + ");\">CLOSE</button>&nbsp;<button onclick=\"selectAll();\">SELECT ALL</button></div>" + "<textarea id=\"code-view\">" + curDivContent + "</textarea>";
	sbar = document.getElementById("statusbar");
	sbar.style.marginTop = "12px";
	// show the popup view with content selected
	popUp.style.visibility = "visible";
	var codeView = document.getElementById("code-view");
	codeView.selectionStart=0;
	codeView.selectionEnd = codeView.value.length;
	document.ontouchmove = function (e) {
		e.preventDefault();
	}
	codeView.focus();
	document.execCommand('copy');
}


function selectAll(){
	var codeView = document.getElementById("code-view").select();
	//codeView.selectionStart=0;
	//codeView.selectionEnd = codeView.value.length;
}

function hidePopup(scriptID,curVScroll){
	document.ontouchmove = function (e) {
		return true;
	}
	var popUp = document.getElementById(scriptID);
	// hide the script window
	popUp.style.visibility = "hidden";
	// reset content of div to original content
	popUp.innerHTML = originalContent;
	// re-enable scrolling
	document.body.style.overflow = "visible";
	// scroll to the previous vertical position
	window.scrollTo(0,parseInt(curVScroll));
}

function openScriptLink(scriptID){
	var scriptDiv = document.getElementById(scriptID);
	var linkText = scriptDiv.innerHTML;
	window.location = linkText;
}

function openInWebConsole(consoleURL, scriptID){
	var scriptDiv = document.getElementById(scriptID);
	var scriptText = scriptDiv.innerHTML;
	consoleWindow = window.open(consoleURL, "_blank");
	consoleWindow.addEventListener('load', function(){
		consoleWindow.displayScript(scriptText);
	});
}

function runFormScriptInOnmiGraffle (form) {
	var scriptCode = form.encodedScriptCode.value;
	var targetURL = "omnigraffle:///omnijs-run?script=" + scriptCode
	window.location = targetURL;
}

function installOOPlugIn(pluginFilenameName){
	os = navigator.platform
	if(os.startsWith('iPad')){
		message = "To install on iOS, choose the “More…” option in forthcoming dialog, and then select the “Copy to OmniOutliner” option. The installed action will appear in the Plug-Ins view on your device, and will be available from the OmniOutliner automation menu.";
	} else if (os.startsWith('iPhone')){
		message = "To install on iOS, choose the “More…” option in forthcoming dialog, and then select the “Copy to OmniOutliner” option. The installed action will appear in the Plug-Ins view on your device, and will be available from the OmniOutliner automation menu.";
	} else if (os.startsWith('Mac')){
		message = "To install on macOS, download and unpack the ZIP archive, then choose “Plug-Ins…” from the OmniOutliner automation menu, and place the file in the PlugIns folder opened on the desktop. The script will be available from the OmniOutliner Automation menu.";
	} else {
		message = "To install on macOS, download and unpack the ZIP archive, then choose “Plug-Ins…” from the OmniOutliner automation menu, and place the file in the PlugIns folder opened on the desktop. The script will be available from the OmniOutliner Automation menu.\n\nTo install on iOS, choose the “More…” option in forthcoming dialog, and then select the “Copy to OmniOutliner” option. The installed action will appear in the Plug-Ins view on your device, and will be available from the OmniOutliner automation menu.";
	};
	alert(message);
	location.href = "actions/" + pluginFilenameName;
}

function installOGPlugIn(pluginFilenameName){
	os = navigator.platform
	if(os.startsWith('iPad')){
		message = "To install on iOS, choose the “More…” option in forthcoming dialog, and then select the “Copy to OmniGraffle” option. The installed action will appear in the Plug-Ins view on your device, and will be available from the OmniGraffle automation menu.";
	} else if (os.startsWith('iPhone')){
		message = "To install on iOS, choose the “More…” option in forthcoming dialog, and then select the “Copy to OmniGraffle” option. The installed action will appear in the Plug-Ins view on your device, and will be available from the OmniGraffle automation menu.";
	} else if (os.startsWith('Mac')){
		message = "To install on macOS, download and unpack the ZIP archive, then choose “Plug-Ins…” from the OmniGraffle automation menu, and place the file in the PlugIns folder opened on the desktop. The script will be available from the OmniGraffle Automation menu.";
	} else {
		message = "To install on macOS, download and unpack the ZIP archive, then choose “Plug-Ins…” from the OmniGraffle automation menu, and place the file in the PlugIns folder opened on the desktop. The script will be available from the OmniGraffle Automation menu.\n\nTo install on iOS, choose the “More…” option in forthcoming dialog, and then select the “Copy to OmniGraffle” option. The installed action will appear in the Plug-Ins view on your device, and will be available from the OmniGraffle automation menu.";
	};
	alert(message);
	location.href = "actions/" + pluginFilenameName;
}


