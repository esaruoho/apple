use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theNSBezierPath to current application's NSBezierPath's bezierPath()
set theVals to {10, 15, 20, 25, 30, 40, 60}
set theTotal to item 1 of (current application's SMSForder's sumMaxMinOf:theVals |error|:(missing value)) as list
set startDeg to 90
set theCentre to {200, -200}
set theRadius to 100
repeat with aVal in theVals
	set endDeg to startDeg   aVal / theTotal * 360
	set theNSBezierPath to current application's NSBezierPath's bezierPath()
	(theNSBezierPath's appendBezierPathWithArcWithCenter:theCentre radius:theRadius startAngle:startDeg endAngle:endDeg)
	(theNSBezierPath's lineToPoint:theCentre)
	theNSBezierPath's closePath()
	set startDeg to endDeg
	set aiProps to (current application's SMSForder's bezierForAI:theNSBezierPath) as record
	-->	{entire path:{{anchor:{295.105651629515, -230.901699437495}, left direction:{295.105651629515, -230.901699437495}, right direction:{312.172188972699, -178.376298419793}}, {anchor:{230.901699437495, -104.894348370485}, left direction:{283.427100455196, -121.960885713668}, right direction:{220.921729954948, -101.651659717802}}, {anchor:{200.0, -100.0}, left direction:{210.493560909949, -100.0}, right direction:{200.0, -100.0}}, {anchor:{200.0, -200.0}, left direction:{200.0, -200.0}, right direction:{200.0, -200.0}}}, closed:true}
	tell application id "com.adobe.illustrator" -- Adobe Illustrator
		tell document 1
			make path item with properties {stroked:true, stroke width:0.5}
			set properties of path item 1 to aiProps
		end tell
	end tell
end repeat
