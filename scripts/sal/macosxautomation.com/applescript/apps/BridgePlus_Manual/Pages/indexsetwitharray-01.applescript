use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set listOrArray to {1, 2, 3, 4, 5, 6}
set theResult to current application's SMSForder's indexSetWithArray:listOrArray
-- no AS equivalent
-->	(NSIndexSet) <NSIndexSet: 0x7f96d9466e10>[number of indexes: 6 (in 1 ranges), indexes: (1-6)]
