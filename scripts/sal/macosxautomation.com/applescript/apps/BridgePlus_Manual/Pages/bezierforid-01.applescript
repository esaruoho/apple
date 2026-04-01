use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theNSBezierPath to current application's NSBezierPath's bezierPath()
set theVals to {10, 15, 20, 25, 30, 40, 60}
set theTotal to item 1 of (current application's SMSForder's sumMaxMinOf:theVals |error|:(missing value)) as list
set startDeg to -90
set theCentre to {200, 200}
set theRadius to 100
repeat with aVal in theVals
	set endDeg to startDeg   aVal / theTotal * 360
	set theNSBezierPath to current application's NSBezierPath's bezierPath()
	(theNSBezierPath's appendBezierPathWithArcWithCenter:theCentre radius:theRadius startAngle:startDeg endAngle:endDeg)
	(theNSBezierPath's lineToPoint:theCentre)
	theNSBezierPath's closePath()
	set startDeg to endDeg
	set idProps to (current application's SMSForder's bezierForID:theNSBezierPath) as record
	-->	{path type:closed path, entire path:{{{104.894348370485, 230.901699437495}, {104.894348370485, 230.901699437495}, {87.827811027302, 178.376298419793}}, {{116.572899544804, 121.960885713668}, {169.098300562505, 104.894348370485}, {179.078270045052, 101.651659717802}}, {{189.506439090051, 100.0}, {200.0, 100.0}, {200.0, 100.0}}, {200.0, 200.0}}}
	tell application id "com.adobe.InDesign" -- Adobe InDesign CC 2014.app
		tell document 1
			make rectangle with properties {stroke weight:0.5}
			set properties of path 1 of page item 1 to idProps
		end tell
	end tell
end repeat
