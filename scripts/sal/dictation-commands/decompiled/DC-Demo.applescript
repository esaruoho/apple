
(* SETUP FOR “IMPORT FROM PHOTOS” DEMO *)
on setupForImportFromPhotosToKeynoteDemo()
	tell application id "com.apple.iWork.Keynote"
		activate
		if «class Plng» is true then
			tell front document to «event KnststoP»
		end if
		set newDocument to make new document with properties {«class Kndt»:«class Knth» "Photo Essay"}
		set newDocID to the id of newDocument
		tell script "DC-Workspace" to resizeDocumentWindow("com.apple.iWork.Keynote", newDocID)
		tell newDocument
			set «class smas» of «class KnSd» 1 to «class KnMs» "Photo - Horizontal Alt"
			tell «class KnSd» 1
				set «class pDTx» of «class sdti» to "My Photos"
				set «class pDTx» of «class sdbi» to "Photos from My Collection"
			end tell
			set newSlide to make new «class KnSd» with properties {«class smas»:«class KnMs» "Photo - 3 Up"}
			set newSlide to make new «class KnSd» with properties {«class smas»:«class KnMs» "Blank"}
			tell «class KnSd» 1
				set aShape to make new «class sshp»
				delete aShape
			end tell
		end tell
	end tell
	say "Ready!"
end setupForImportFromPhotosToKeynoteDemo
