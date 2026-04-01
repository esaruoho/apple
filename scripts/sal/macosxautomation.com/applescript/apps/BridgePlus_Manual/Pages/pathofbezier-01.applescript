use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theNSBezierPath to current application's NSBezierPath's bezierPath()
set startDeg to 0
set endDeg to 45
set theCentre to {200, 200}
set theRadius to 100
theNSBezierPath's appendBezierPathWithArcWithCenter:theCentre radius:theRadius startAngle:startDeg endAngle:endDeg
theNSBezierPath's lineToPoint:theCentre
theNSBezierPath's closePath()
set theResult to current application's SMSForder's pathOfBezier:theNSBezierPath
ASify from theResult
-->	{path_points:{{{300.0, 200.0}, {300.0, 200.0}, {300.0, 226.521648983954}}, {{289.464315963458, 251.957040273851}, {270.710678118655, 270.710678118655}, {270.710678118655, 270.710678118655}}, {200.0, 200.0}}, is_closed:true}
theResult as record -- 10.11 only
-->	{path_points:{{{300.0, 200.0}, {300.0, 200.0}, {300.0, 226.521648983954}}, {{289.464315963458, 251.957040273851}, {270.710678118655, 270.710678118655}, {270.710678118655, 270.710678118655}}, {200.0, 200.0}}, is_closed:true}
theResult as record -- 10.9 and 10.10
-->	<as above, but real values lose precision>
