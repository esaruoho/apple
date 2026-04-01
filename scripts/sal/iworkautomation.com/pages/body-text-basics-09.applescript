tell application "Pages"
	activate
	
	set thisDocument to ¬
		make new document with properties {document template:template "Blank"}
	
	tell thisDocument
		-- replace body text
		set body text to "Curabitur blandit tempus porttitor. Donec sed odio dui. Donec id elit non mi porta gravida at eget metus. Etiam porta sem malesuada magna mollis euismod.

Donec ullamcorper nulla non metus auctor fringilla. Maecenas faucibus mollis interdum. Nulla vitae elit libero, a pharetra augue. Praesent commodo cursus magna, vel scelerisque nisl consectetur et. Integer posuere erat a ante venenatis dapibus posuere velit aliquet.

Donec sed odio dui. Vestibulum id ligula porta felis euismod semper. Praesent commodo cursus magna, vel scelerisque nisl consectetur et. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla vitae elit libero, a pharetra augue. Donec justo odio, dapibus ac facilisis in, egestas eget quam. Maecenas sed diam eget risus varius blandit sit amet non magna.

COPYRIGHT NOTICE"
		
		tell body text
			-- set body tet properties
			set font to "Verdana"
			set size to 18
			set color of it to "gray"
			
			-- replace character
			set (the first character) to "T"
			
			-- replace word
			set (every word of every paragraph where it is "Donec") to "Salnec"
			
			-- replace paragraph
			set (every paragraph where it begins with "COPYRIGHT NOTICE") to ¬
				"© ACME WIDGETS, INC. ALL RIGHTS RESERVED."
		end tell
	end tell
end tell
