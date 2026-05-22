#!/usr/bin/osascript
-- asobjc-tag-demo.applescript
--
-- Minimum-viable AppleScriptObjective-C pilot for THIS skill.
-- Demonstrates the "missing tier" (see wiki/concepts/asobjc.md) by
-- reading Finder tags via NSURL's NSURLTagNamesKey resource value
-- instead of xattr+plistlib parsing of the binary metadata blob.
--
-- Why this is the right shape:
--   * `use framework "Foundation"` unlocks every Cocoa class
--   * NSURL resource values are Apple-supported, APFS-safe, no plist parsing
--   * Runs in plain osascript — no Swift, no Xcode, no compile step
--   * Zero third-party dependencies (skill rule: Apple-native only)
--
-- Usage:
--   osascript bin/asobjc-tag-demo.applescript /path/to/somefile
--   osascript bin/asobjc-tag-demo.applescript ~/Desktop/test.png
--
-- Output:
--   one tag per line, or "(no tags)" if the file has none.

use framework "Foundation"
use scripting additions

on run argv
	if (count of argv) is 0 then
		log "usage: osascript asobjc-tag-demo.applescript <path>"
		return
	end if

	set thePath to item 1 of argv

	-- POSIX expand ~ if present
	if thePath starts with "~" then
		set thePath to (do shell script "printf %s " & quoted form of thePath)
	end if

	set theURL to current application's NSURL's fileURLWithPath:thePath

	-- getResourceValue:forKey:error: is the Apple-supported way to read tags.
	-- The (reference) form is ASObjC's out-parameter convention.
	set {ok, tagList, theError} to theURL's getResourceValue:(reference) ¬
		forKey:(current application's NSURLTagNamesKey) ¬
		|error|:(reference)

	if not ok then
		log "error reading tags: " & (theError's localizedDescription() as text)
		return
	end if

	if tagList is missing value then
		log "(no tags)"
		return
	end if

	set tagsAS to tagList as list
	if (count of tagsAS) is 0 then
		log "(no tags)"
		return
	end if

	repeat with t in tagsAS
		log (t as text)
	end repeat
end run
