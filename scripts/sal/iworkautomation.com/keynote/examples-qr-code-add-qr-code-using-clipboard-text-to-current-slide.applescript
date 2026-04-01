use framework "Foundation"
use framework "CoreImage"
use framework "AppKit"
use framework "CoreGraphics"
use scripting additions

property targetMinimumDimension : 400

try
	tell application "Keynote"
		activate
		if playing is true then tell the front document to stop
		if not (exists document 1) then error number -128
		if (clipboard info for «class utf8») is not {} then
			set clipboardText to (get the clipboard as «class utf8»)
		else
			error "There is no text on the clipboard to convert into a QR code image."
		end if
	end tell
	
	-- derive a file path for the created image file
	set theUUID to current application's NSUUID's UUID()'s UUIDString()
	set fileManager to current application's NSFileManager's defaultManager()
	set theURL to (fileManager's URLsForDirectory:(current application's NSPicturesDirectory) inDomains:(current application's NSUserDomainMask))'s firstObject()
	set the targetItemHFSPath to (theURL as string) & (theUUID as string) & ".jpg"
	set targetItemPOSIXPath to POSIX path of targetItemHFSPath
	
	set thisImageObject to my createFullSizeQRCodeImageObjectForString(clipboardText)
	my writeNSImageObjectToFileAsJPEG(thisImageObject, targetItemPOSIXPath, false)
	
	set the targetFile to targetItemHFSPath as alias
	tell application "Keynote"
		activate
		if not (exists document 1) then
			make new document
		end if
		tell front document
			set documentWidth to the width of it
			set documentHeight to the height of it
			tell current slide
				-- add the image to the slide and size to desired dimension
				set thisImage to make new image with properties {file:targetFile, width:targetMinimumDimension, height:targetMinimumDimension}
				-- center the added image on the slide
				set the position of thisImage to {(documentWidth - targetMinimumDimension) div 2, (documentHeight - targetMinimumDimension) div 2}
			end tell
		end tell
	end tell
	
	-- SInce the image is automatically added to document bundle, move the source image file to trash
	set fileManager to current application's NSFileManager's defaultManager()
	set thisPOSIXPath to current application's NSString's stringWithString:targetItemPOSIXPath
	set resultingURL to missing value
	set URLOfItemToTrash to (current application's |NSURL|'s fileURLWithPath:thisPOSIXPath)
	(fileManager's trashItemAtURL:URLOfItemToTrash resultingItemURL:resultingURL |error|:(missing value))
	
	say "Done!"
on error errorMessage number errorNumber
	if errorNumber is not -128 then
		set spokenErrorTitle to "I was unable to complete your request: "
		set cfgutil to "/usr/bin/say"
		set theTask to (current application's NSTask's launchedTaskWithLaunchPath:cfgutil arguments:{(spokenErrorTitle & errorMessage)})
		tell application (POSIX path of (path to frontmost application))
			activate
			display alert "Unable to Complete Request:" message errorMessage buttons {"Cancel"} default button 1
		end tell
		theTask's terminate()
	end if
end try

on createFullSizeQRCodeImageObjectForString(thisString)
	-- returns a full-size NSImage object
	
	set thisString to current application's NSString's stringWithString:thisString
	
	set thisData to thisString's dataUsingEncoding:(current application's NSUTF8StringEncoding)
	
	set anImageFilter to current application's CIFilter's filterWithName:"CIQRCodeGenerator"
	anImageFilter's setDefaults()
	anImageFilter's setValue:thisData forKey:"inputMessage"
	anImageFilter's setValue:"L" forKey:"inputCorrectionLevel"
	
	set baseImage to anImageFilter's outputImage()
	
	set aTransform to current application's CGAffineTransform's CGAffineTransformMakeScale(100.0, 100.0)
	
	set outputImage to baseImage's imageByApplyingTransform:aTransform
	
	set imageRepresentation to current application's NSCIImageRep's imageRepWithCIImage:outputImage
	
	set resultingImageObject to current application's NSImage's alloc()'s initWithSize:(imageRepresentation's |size|())
	
	resultingImageObject's addRepresentation:imageRepresentation
	
	return resultingImageObject
end createFullSizeQRCodeImageObjectForString

on createScaledQRCodeImageObjectForString(thisString, targetWidth, targetHeight)
	-- returns a scaled NSImage object
	
	set thisString to current application's NSString's stringWithString:thisString
	
	set thisData to thisString's dataUsingEncoding:(current application's NSUTF8StringEncoding)
	
	set anImageFilter to current application's CIFilter's filterWithName:"CIQRCodeGenerator"
	anImageFilter's setDefaults()
	anImageFilter's setValue:thisData forKey:"inputMessage"
	anImageFilter's setValue:"L" forKey:"inputCorrectionLevel"
	
	set baseImage to anImageFilter's outputImage()
	
	set baseImageSize to baseImage's extent()'s |size|()
	
	set xScale to targetWidth / (baseImageSize's width())
	set yScale to targetHeight / (baseImageSize's height())
	
	set aTransform to current application's CGAffineTransform's CGAffineTransformMakeScale(xScale, yScale)
	
	set outputImage to baseImage's imageByApplyingTransform:aTransform
	
	set imageRepresentation to current application's NSCIImageRep's imageRepWithCIImage:outputImage
	
	set resultingImageObject to current application's NSImage's alloc()'s initWithSize:(imageRepresentation's |size|())
	
	resultingImageObject's addRepresentation:imageRepresentation
	
	return resultingImageObject
end createScaledQRCodeImageObjectForString

on writeNSImageObjectToFileAsJPEG(thisImageObject, targetImageFilePath, shouldRevealInFinder)
	-- create JPEG data for the image object
	set tiffData to thisImageObject's TIFFRepresentation()
	set imageRep to current application's NSBitmapImageRep's imageRepWithData:tiffData
	set theProps to current application's NSDictionary's dictionaryWithObject:1.0 forKey:(current application's NSImageCompressionFactor)
	set imageData to (imageRep's representationUsingType:(current application's NSJPEGFileType) |properties|:theProps)
	
	-- write the JPEG data to file
	set theResult to (imageData's writeToFile:targetImageFilePath atomically:true |error|:(missing value)) as boolean
	if theResult is true then
		if shouldRevealInFinder is true then
			set theseURLs to {}
			set the end of theseURLs to (current application's NSURL's fileURLWithPath:targetImageFilePath)
			-- reveal items in file viewer
			tell current application's NSWorkspace to set theWorkspace to sharedWorkspace()
			tell theWorkspace to activateFileViewerSelectingURLs:theseURLs
		end if
		return true
	else
		error "There was a problem writing the image object to file."
	end if
end writeNSImageObjectToFileAsJPEG
