tell application "Keynote"
	activate
	tell document 1
		set documentWidth to its width
		set documentHeight to its height
		set documentWidthThird to documentWidth div 3
		set documentHeightThird to documentHeight div 3
		tell current slide
			-- HORIZONTAL LINES
			set thisLine to make new line with properties {start point:{0, documentHeightThird}, end point:{documentWidth, documentHeightThird}, reflection showing:false, reflection value:100}
			set thisLine to make new line with properties {start point:{0, documentHeightThird * 2}, end point:{documentWidth, documentHeightThird * 2}, reflection showing:false, reflection value:100}
			-- VERTICAL LINES
			set thisLine to make new line with properties {start point:{documentWidthThird, 0}, end point:{documentWidthThird, documentHeight}, reflection showing:false, reflection value:100}
			set thisLine to make new line with properties {start point:{documentWidthThird * 2, 0}, end point:{documentWidthThird * 2, documentHeight}, reflection showing:false, reflection value:100}
		end tell
	end tell
end tell
