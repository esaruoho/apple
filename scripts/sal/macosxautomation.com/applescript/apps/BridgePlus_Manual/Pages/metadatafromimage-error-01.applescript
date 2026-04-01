use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set fileAliasOrPath to "~/Desktop/Test/IMG_0829.JPG"
set theResult to current application's SMSForder's metadataFromImage:fileAliasOrPath |error|:(missing value)
ASify from theResult
--> {​​​​{​​​​​​​TIFF}:{​​​​​​​​​ResolutionUnit:2, ​​​​​​​​​Software:"9.0.2", ​​​​​​​​​DateTime:"2015:10:12 15:12:55", [...]}, ​​​​​​​{Exif}:{​​​​​​​​​DateTimeOriginal:"2015:10:12 15:12:55", ​​​​​​​​​MeteringMode:5, ​​​​​​​​​[...]}, ​​​​​​​{GPS}:{​​​​​​​​​ImgDirection:129.325396825397, ​​​​​​​​​LatitudeRef:"S", ​​​​​​​​​[...]}, ​​​​​​​ProfileName:"sRGB IEC61966-2.1", ​​​​​​​DPIWidth:72.0, ​​​​​​​DPIHeight:72.0, ​​​​​​​ColorModel:"RGB", ​​​​​​​{MakerApple}:{​​​​​​​​​7:1, ​​​​​​​​​3:{​​​​​​​​​​​flags:1, ​​​​​​​​​​​[...]​​​​​}​​​
theResult as record -- 10.11 only
--> {​​​​​​​​​​​{TIFF}:{​​​​​​​​​ResolutionUnit:2, ​​​​​​​​​Software:"9.0.2", ​​​​​​​​​DateTime:"2015:10:12 15:12:55", [...]}, ​​​​​​​{Exif}:{​​​​​​​​​DateTimeOriginal:"2015:10:12 15:12:55", ​​​​​​​​​MeteringMode:5, ​​​​​​​​​[...]}, ​​​​​​​{GPS}:{​​​​​​​​​ImgDirection:129.325396825397, ​​​​​​​​​LatitudeRef:"S", ​​​​​​​​​[...]}, ​​​​​​​ProfileName:"sRGB IEC61966-2.1", ​​​​​​​DPIWidth:72.0, ​​​​​​​DPIHeight:72.0, ​​​​​​​ColorModel:"RGB", ​​​​​​​{MakerApple}:{​​​​​​​​​7:1, ​​​​​​​​​3:{​​​​​​​​​​​flags:1, ​​​​​​​​​​​[...]​​​​​}​​​
theResult as record -- 10.9 and 10.10
-->	<reals will be single precision>

set fileAliasOrPath to "~/Desktop/Test/No such file"
set {theResult, theError} to current application's SMSForder's metadataFromImage:fileAliasOrPath |error|:(reference)
if theResult = missing value then error (theError's localizedDescription() as text)
-->	error number -2700  Image could not be read.
