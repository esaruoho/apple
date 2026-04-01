property placeholderText : "Cras justo odio, dapibus ac facilisis in, egestas eget quam. Praesent commodo cursus magna, vel scelerisque nisl consectetur et. Nulla vitae elit libero, a pharetra augue. Vestibulum id ligula porta felis euismod semper. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit.
	 
Cras mattis consectetur purus sit amet fermentum. Morbi leo risus, porta ac consectetur ac, vestibulum at eros. Maecenas sed diam eget risus varius blandit sit amet non magna. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit.
	 
Sed posuere consectetur est at lobortis. Maecenas faucibus mollis interdum. Etiam porta sem malesuada magna mollis euismod. Nullam id dolor id nibh ultricies vehicula ut id elit."

tell application "Keynote"
	activate
	if not (exists document 1) then error number -128
	tell the front document
		set documentWidth to its width
		set documentHeight to its height
		tell the current slide
			set shapeWidth to (documentWidth * 0.75)
			set shapeHeight to (documentHeight * 0.75)
			set shapeHorizontal to (documentWidth - shapeWidth) div 2
			set shapeVertical to (documentHeight - shapeHeight) div 2
			set thisShape to ¬
				make new shape with properties ¬
					{position:{shapeHorizontal, shapeVertical} ¬
						, width:shapeWidth ¬
						, height:shapeHeight ¬
						, opacity:100 ¬
						, object text:placeholderText}
		end tell
	end tell
end tell
