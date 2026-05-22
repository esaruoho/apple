#!/usr/bin/osascript
-- tag-asobjc.applescript
--
-- ASObjC pilot reimplementation of `bin/tag` core I/O.
-- Replaces the xattr+plistlib (Python) read/write path with NSURL
-- resource values via NSURLTagNamesKey — Apple-supported, APFS-safe.
--
-- KNOWN LIMITATION (verified 2026-05-22): NSURLTagNamesKey is names-only
-- on both read and write. Color info ("Name\n<colorInt>") is silently
-- dropped. For color-preserving I/O, fall back to bin/tag (Python xattr)
-- or extend this pilot with NSPropertyListSerialization + an xattr-write
-- helper. See wiki/concepts/asobjc.md for the full finding + migration
-- path.
--
-- Subcommands implemented (the I/O-bound core):
--   list   <file>...
--   add    <spec>[,<spec>...] <file>...
--   set    <spec>[,<spec>...] <file>...
--   remove <name>[,<name>...] <file>...
--   clear  <file>...
--
-- Not implemented (not I/O-bound — call Python `tag` for these):
--   find / find-all / find-any  (mdfind passthrough)
--   link / rename / colors
--
-- Tag spec format matches the Python tool:
--   "Name"          -> no color
--   "Name:blue"     -> color by name
--   "Name:4"        -> color by index (0-7)
--
-- The on-disk encoding for a tag with color is "Name\n<int>" — same
-- raw form both tools see; ASObjC just passes the array unchanged.

use framework "Foundation"
use scripting additions

property COLOR_NAMES : {"none", "gray", "green", "purple", "blue", "yellow", "red", "orange"}
property COLOR_ALIASES : {grey:1}

-- ── helpers ──────────────────────────────────────────────────

on colorToInt(s)
	set s to do shell script "printf %s " & quoted form of s & " | tr '[:upper:]' '[:lower:]'"
	-- numeric?
	try
		set n to s as integer
		if n ≥ 0 and n ≤ 7 then return n
		error "color code " & n & " out of range (0-7)"
	end try
	repeat with i from 1 to count of COLOR_NAMES
		if item i of COLOR_NAMES is s then return i - 1
	end repeat
	if s is "grey" then return 1
	error "unknown color '" & s & "'"
end colorToInt

on parseSpec(spec)
	-- "Name" -> "Name", "Name:blue" -> "Name" & linefeed & "4"
	set spec to my trim(spec)
	if spec is "" then error "empty tag spec"
	if spec contains ":" then
		set AppleScript's text item delimiters to ":"
		set parts to text items of spec
		set AppleScript's text item delimiters to ""
		set nm to my trim(item 1 of parts)
		set cl to my trim(item 2 of parts)
		if nm is "" then error "empty tag name in spec"
		return nm & linefeed & (my colorToInt(cl) as text)
	end if
	return spec
end parseSpec

on nameOf(raw)
	set raw to raw as text
	if raw contains linefeed then
		set AppleScript's text item delimiters to linefeed
		set n to text item 1 of raw
		set AppleScript's text item delimiters to ""
		return n
	end if
	return raw
end nameOf

on colorOf(raw)
	set raw to raw as text
	if raw contains linefeed then
		set AppleScript's text item delimiters to linefeed
		set parts to text items of raw
		set AppleScript's text item delimiters to ""
		try
			return (item 2 of parts) as integer
		end try
	end if
	return 0
end colorOf

on fmtTag(raw)
	set n to my nameOf(raw)
	set c to my colorOf(raw)
	if c is 0 then return n
	return n & ":" & item (c + 1) of COLOR_NAMES
end fmtTag

on trim(s)
	return do shell script "printf %s " & quoted form of s & " | awk '{$1=$1;print}'"
end trim

on splitCommas(s)
	set AppleScript's text item delimiters to ","
	set parts to text items of s
	set AppleScript's text item delimiters to ""
	set out to {}
	repeat with p in parts
		set t to my trim(p as text)
		if t is not "" then set end of out to t
	end repeat
	return out
end splitCommas

on expandPath(p)
	if p starts with "~" then
		return do shell script "printf %s " & quoted form of p
	end if
	return p
end expandPath

-- ── ASObjC core I/O ──────────────────────────────────────────

on urlFor(path)
	set p to my expandPath(path)
	return current application's NSURL's fileURLWithPath:p
end urlFor

on readTags(path)
	-- returns AppleScript list of raw tag strings (possibly empty)
	set theURL to my urlFor(path)
	set {ok, tagList, theError} to theURL's getResourceValue:(reference) ¬
		forKey:(current application's NSURLTagNamesKey) ¬
		|error|:(reference)
	if not ok then error "read failed: " & (theError's localizedDescription() as text)
	if tagList is missing value then return {}
	return tagList as list
end readTags

on writeTags(path, tags)
	-- tags is AppleScript list of raw strings; empty list -> clear
	set theURL to my urlFor(path)
	set nsTags to current application's NSArray's arrayWithArray:tags
	set {ok, theError} to theURL's setResourceValue:nsTags ¬
		forKey:(current application's NSURLTagNamesKey) ¬
		|error|:(reference)
	if not ok then error "write failed: " & (theError's localizedDescription() as text)
end writeTags

-- ── subcommands ──────────────────────────────────────────────

on cmdList(args)
	if (count of args) is 0 then error "usage: tag-asobjc list <file>..."
	set multi to (count of args) > 1
	repeat with a in args
		set p to a as text
		set tags to my readTags(p)
		if multi then log (p & ":")
		if (count of tags) is 0 and multi then log "  (no tags)"
		repeat with t in tags
			if multi then
				log "  " & my fmtTag(t)
			else
				log my fmtTag(t)
			end if
		end repeat
	end repeat
end cmdList

on cmdAdd(args)
	if (count of args) < 2 then error "usage: tag-asobjc add <spec>[,<spec>...] <file>..."
	set specs to my splitCommas(item 1 of args)
	set newTags to {}
	set newNames to {}
	repeat with s in specs
		set r to my parseSpec(s as text)
		set end of newTags to r
		set end of newNames to my nameOf(r)
	end repeat
	set fileArgs to items 2 thru -1 of args
	repeat with a in fileArgs
		set p to a as text
		set existing to my readTags(p)
		set kept to {}
		repeat with t in existing
			if newNames does not contain my nameOf(t) then set end of kept to t
		end repeat
		set merged to kept & newTags
		my writeTags(p, merged)
		log "tag add: " & p
	end repeat
end cmdAdd

on cmdSet(args)
	if (count of args) < 2 then error "usage: tag-asobjc set <spec>[,<spec>...] <file>..."
	set specs to my splitCommas(item 1 of args)
	set newTags to {}
	repeat with s in specs
		set end of newTags to my parseSpec(s as text)
	end repeat
	set fileArgs to items 2 thru -1 of args
	repeat with a in fileArgs
		set p to a as text
		my writeTags(p, newTags)
		log "tag set: " & p
	end repeat
end cmdSet

on cmdRemove(args)
	if (count of args) < 2 then error "usage: tag-asobjc remove <name>[,<name>...] <file>..."
	set drop to my splitCommas(item 1 of args)
	set fileArgs to items 2 thru -1 of args
	repeat with a in fileArgs
		set p to a as text
		set existing to my readTags(p)
		set kept to {}
		repeat with t in existing
			if drop does not contain my nameOf(t) then set end of kept to t
		end repeat
		if (count of kept) is not (count of existing) then
			my writeTags(p, kept)
			log "tag remove: " & p
		end if
	end repeat
end cmdRemove

on cmdClear(args)
	if (count of args) is 0 then error "usage: tag-asobjc clear <file>..."
	repeat with a in args
		set p to a as text
		my writeTags(p, {})
		log "tag clear: " & p
	end repeat
end cmdClear

-- ── dispatch ─────────────────────────────────────────────────

on run argv
	if (count of argv) is 0 then
		log "usage: tag-asobjc {list|add|set|remove|clear} ..."
		return
	end if
	set sub to item 1 of argv
	set restArgs to {}
	if (count of argv) > 1 then set restArgs to items 2 thru -1 of argv

	if sub is "list" or sub is "ls" then
		my cmdList(restArgs)
	else if sub is "add" then
		my cmdAdd(restArgs)
	else if sub is "set" then
		my cmdSet(restArgs)
	else if sub is "remove" or sub is "rm" then
		my cmdRemove(restArgs)
	else if sub is "clear" then
		my cmdClear(restArgs)
	else
		error "unknown subcommand '" & sub & "' — try: list add set remove clear"
	end if
end run
