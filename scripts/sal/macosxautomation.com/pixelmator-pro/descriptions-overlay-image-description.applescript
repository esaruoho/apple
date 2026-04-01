use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions

property backgroundShapeOpacity : 70
property defaultBackgroundColor : {6425, 6425, 6425}

tell application id "com.pixelmatorteam.pixelmator.x"
	activate
	tell the front document
		
		set imageDescription to the caption of the document info of it
		if imageDescription is "" then
			display dialog "This images does not have a description." & return & return & "Would you like to use placeholder text instead?" with icon 2
			set imageDescription to "Cras mattis consectetur purus sit amet fermentum. Integer posuere erat a ante venenatis dapibus posuere velit aliquet. Donec ullamcorper nulla non metus auctor fringilla. Integer posuere erat a ante venenatis dapibus posuere velit aliquet. Maecenas faucibus mollis interdum."
		end if
		
		set the docWidth to the width of it
		set the docHeight to the height of it
		
		set hypot to (the docWidth ^ 2 + docHeight ^ 2)
		
		if docWidth = docHeight then
			set fontSize to hypot div docWidth
		else if docWidth > docHeight then
			set fontSize to hypot div docWidth
		else
			set fontSize to hypot div docHeight
		end if
		set fontSize to fontSize div 100
		
		set descriptionOffset to docWidth div 10
		set textLayerWidth to docWidth - descriptionOffset * 2
		
		set textLayer to make new text layer with properties {text content:imageDescription, width:textLayerWidth, name:"Description"}
		tell textLayer
			tell its text content
				set font to "Helvetica"
				set size to fontSize
			end tell
			set horizontal alignment to left
			set textLayerHeight to height of it
			set position to {descriptionOffset, docHeight - textLayerHeight - descriptionOffset}
		end tell
		
		set shapeLayerWidth to docWidth - descriptionOffset
		set shapeLayer to make new rounded rectangle shape layer with properties {width:shapeLayerWidth, name:"Description Background", height:textLayerHeight + descriptionOffset div 1.5} at beginning of shape layers
		set fill color of styles of shapeLayer to defaultBackgroundColor
		set opacity of shapeLayer to backgroundShapeOpacity
		set shapeLayerHeight to height of shapeLayer
		set position of shapeLayer to {descriptionOffset div 2, docHeight - shapeLayerHeight - descriptionOffset div 1.5}
		
		move textLayer to before layer 1
		move shapeLayer to after layer 1
		
		set fill color of styles of shapeLayer to choose color default color defaultBackgroundColor
	end tell
end tell
