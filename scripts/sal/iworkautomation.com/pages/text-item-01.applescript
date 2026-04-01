set thisStory to "Lorem ipsum dolor sit amet
Aenean lacinia bibendum nulla sed consectetur. Etiam porta sem malesuada magna mollis euismod. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Cras mattis consectetur purus sit amet fermentum. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Sed posuere consectetur est at lobortis.
Nullam quis risus eget urna mollis ornare vel eu leo. Morbi leo risus, porta ac consectetur ac, vestibulum at eros. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam id dolor id nibh ultricies vehicula ut id elit.
Aenean eu leo quam. Pellentesque ornare sem lacinia quam venenatis vestibulum. Sed posuere consectetur est at lobortis. Morbi leo risus, porta ac consectetur ac, vestibulum at eros. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Etiam porta sem malesuada magna mollis euismod. Curabitur blandit tempus porttitor.
Nulla vitae elit libero, a pharetra augue. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec sed odio dui. Maecenas sed diam eget risus varius blandit sit amet non magna."

tell application "Pages"
	activate
	set thisDocument to ¬
		make new document with properties {document template:template "Tab Flyer"}
	tell thisDocument
		-- clear the document of template items
		set locked of every iWork item to false
		delete every iWork item
		
		tell current page
			set thisTextItem to ¬
				make new text item with properties ¬
					{height:648, width:240, position:{72, 72}}
			set object text of thisTextItem to thisStory
			tell object text of thisTextItem
				set properties to ¬
					{font:"Helvetica Neue", size:12, color:{10000, 10000, 10000}}
				set properties of first paragraph to ¬
					{font:"Helvetica Neue Condensed Bold", size:18, color:{0, 0, 0}}
			end tell
		end tell
	end tell
end tell
