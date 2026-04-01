use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's tanValueOf:(45 / 180 * pi)
ASify from theResult
-->	1.0
theResult as real
-->	1.0
set theResult to current application's SMSForder's tanValueOf:{(30 / 180 * pi), (60 / 180 * pi), (90 / 180 * pi)}
ASify from theResult
-->	{0.57735026919, 1.732050807569, 1.63312393531954E 16}
theResult as list
-->	{0.57735026919, 1.732050807569, 1.63312393531954E 16}
