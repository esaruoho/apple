use scripting additions
use framework "Foundation"
use script "BridgePlus"
load framework

set theResult to current application's SMSForder's spotlightDataFor:(choose file)
ASify from theResult
-->	{kMDItemFSCreatorCode:0, kMDItemFSFinderFlags:0, kMDItemFSContentChangeDate:date "Monday, 16 November 2015 at 2:55:09 PM", kMDItemFSName:"Crash.txt", kMDItemDisplayName:"Crash.txt", kMDItemFSInvisible:false, kMDItemFSSize:66230, kMDItemFSTypeCode:0, kMDItemDateAdded:date "Monday, 16 November 2015 at 2:55:09 PM", kMDItemPhysicalSize:69632, kMDItemKind:"BBEdit text document", _kMDItemOwnerUserID:501, kMDItemContentTypeTree:{"public.plain-text", "public.text", "public.data", "public.item", "public.content"}, kMDItemFSOwnerUserID:501, kMDItemFSIsExtensionHidden:false, kMDItemLogicalSize:66230, kMDItemFSLabel:0, kMDItemContentModificationDate:date "Monday, 16 November 2015 at 2:55:09 PM", kMDItemContentType:"public.plain-text", kMDItemFSOwnerGroupID:20, kMDItemContentCreationDate:date "Monday, 16 November 2015 at 2:55:09 PM", kMDItemFSCreationDate:date "Monday, 16 November 2015 at 2:55:09 PM"}
theResult as record -- 10.11 only
-->	{kMDItemFSCreatorCode:0, kMDItemFSFinderFlags:0, kMDItemFSContentChangeDate:date "Monday, 16 November 2015 at 2:55:09 PM", kMDItemFSName:"Crash.txt", kMDItemDisplayName:"Crash.txt", kMDItemFSInvisible:false, kMDItemFSSize:66230, kMDItemFSTypeCode:0, kMDItemDateAdded:date "Monday, 16 November 2015 at 2:55:09 PM", kMDItemPhysicalSize:69632, kMDItemKind:"BBEdit text document", _kMDItemOwnerUserID:501, kMDItemContentTypeTree:{"public.plain-text", "public.text", "public.data", "public.item", "public.content"}, kMDItemFSOwnerUserID:501, kMDItemFSIsExtensionHidden:false, kMDItemLogicalSize:66230, kMDItemFSLabel:0, kMDItemContentModificationDate:date "Monday, 16 November 2015 at 2:55:09 PM", kMDItemContentType:"public.plain-text", kMDItemFSOwnerGroupID:20, kMDItemContentCreationDate:date "Monday, 16 November 2015 at 2:55:09 PM", kMDItemFSCreationDate:date "Monday, 16 November 2015 at 2:55:09 PM"}
theResult as record -- 10.9 and 10.10
-->	< as above, but dates will be NSDates instead of AS dates >
