#!/usr/bin/osascript
-- tag-asobjc-full.applescript
--
-- Color-preserving ASObjC pilot. Sibling of tag-asobjc.applescript.
-- The plain pilot uses NSURLTagNamesKey (names-only, strips colors).
-- This one uses NSPropertyListSerialization on the raw xattr to round-trip
-- the full "Name\n<colorInt>" form that Finder + Python `bin/tag` use.
--
-- Pattern demonstrated:
--   1. shell out to `xattr -px` for the hex-encoded blob (Apple-shipped CLI)
--   2. decode hex -> NSData via NSData's initWithBase16... (manual hex parse)
--   3. NSPropertyListSerialization propertyListWithData -> NSArray
--   4. mutate
--   5. NSPropertyListSerialization dataWithPropertyList (binary v1) -> NSData
--   6. hex-encode -> shell out to `xattr -wx`
--
-- This is the recipe whenever ASObjC needs to touch arbitrary xattrs:
-- Foundation doesn't expose setxattr/getxattr publicly, so the `xattr`
-- CLI is the bridge (still Apple-native; ships with macOS).
--
-- Subcommands: list / set / clear (the irreducible color-preserving core).
-- For full CLI parity, port add/remove on top of these.

use framework "Foundation"
use scripting additions

property XATTR : "com.apple.metadata:_kMDItemUserTags"
property COLOR_NAMES : {"none", "gray", "green", "purple", "blue", "yellow", "red", "orange"}

-- ── helpers ──────────────────────────────────────────────────

on expandPath(p)
	if p starts with "~" then
		return do shell script "printf %s " & quoted form of p
	end if
	return p
end expandPath

on trim(s)
	return do shell script "printf %s " & quoted form of s & " | awk '{$1=$1;print}'"
end trim

on hexToData(hexStr)
	-- Foundation doesn't expose a public hex->NSData decoder. Two clean
	-- options: (a) parse byte pairs in ASObjC (ugly — can't write raw bytes
	-- to NSMutableData from AppleScript), or (b) round-trip through `xxd -r`
	-- via tempfile, then NSData's dataWithContentsOfFile. (b) is cleaner.
	set tmpHex to do shell script "mktemp /tmp/asobjc-hex.XXXXXX"
	set tmpBin to do shell script "mktemp /tmp/asobjc-bin.XXXXXX"
	do shell script "printf %s " & quoted form of hexStr & " | tr -d ' \\t\\n\\r' > " & quoted form of tmpHex
	do shell script "xxd -r -p " & quoted form of tmpHex & " > " & quoted form of tmpBin
	set finalData to (current application's NSData's dataWithContentsOfFile:tmpBin)
	do shell script "rm -f " & quoted form of tmpHex & " " & quoted form of tmpBin
	return finalData
end hexToData

on dataToHex(dataObj)
	-- write NSData to tempfile, run `xxd -p -c 1000000`, return hex string
	set tmpBin to do shell script "mktemp /tmp/asobjc-bin.XXXXXX"
	dataObj's writeToFile:tmpBin atomically:true
	set hexStr to do shell script "xxd -p -c 1000000 " & quoted form of tmpBin & " | tr -d '\\n'"
	do shell script "rm -f " & quoted form of tmpBin
	return hexStr
end dataToHex

-- ── xattr round-trip via NSPropertyListSerialization ─────────

on readRawTags(path)
	set p to my expandPath(path)
	-- Probe whether the xattr exists; xattr -px returns nonzero if absent.
	try
		set hexStr to do shell script "xattr -px " & quoted form of XATTR & " " & quoted form of p & " 2>/dev/null"
	on error
		return {}
	end try
	if hexStr is "" then return {}
	set blob to my hexToData(hexStr)
	if blob is missing value then return {}
	set {plistObj, fmt, err} to (current application's NSPropertyListSerialization's ¬
		propertyListWithData:blob ¬
		options:0 ¬
		format:(reference) ¬
		|error|:(reference))
	if plistObj is missing value then error "plist parse failed: " & (err's localizedDescription() as text)
	return plistObj as list
end readRawTags

on writeRawTags(path, tags)
	set p to my expandPath(path)
	if (count of tags) is 0 then
		do shell script "xattr -d " & quoted form of XATTR & " " & quoted form of p & " 2>/dev/null || true"
		return
	end if
	set nsArr to current application's NSArray's arrayWithArray:tags
	set {blob, err} to (current application's NSPropertyListSerialization's ¬
		dataWithPropertyList:nsArr ¬
		format:(current application's NSPropertyListBinaryFormat_v1_0) ¬
		options:0 ¬
		|error|:(reference))
	if blob is missing value then error "plist serialize failed: " & (err's localizedDescription() as text)
	set hexStr to my dataToHex(blob)
	do shell script "xattr -wx " & quoted form of XATTR & " " & quoted form of hexStr & " " & quoted form of p
end writeRawTags

-- ── tag-spec parsing (same as tag-asobjc.applescript) ────────

on colorToInt(s)
	set s to do shell script "printf %s " & quoted form of s & " | tr '[:upper:]' '[:lower:]'"
	try
		set n to s as integer
		if n ≥ 0 and n ≤ 7 then return n
	end try
	repeat with i from 1 to count of COLOR_NAMES
		if item i of COLOR_NAMES is s then return i - 1
	end repeat
	if s is "grey" then return 1
	error "unknown color '" & s & "'"
end colorToInt

on parseSpec(spec)
	set spec to my trim(spec)
	if spec is "" then error "empty tag spec"
	if spec contains ":" then
		set AppleScript's text item delimiters to ":"
		set parts to text items of spec
		set AppleScript's text item delimiters to ""
		set nm to my trim(item 1 of parts)
		set cl to my trim(item 2 of parts)
		return nm & linefeed & (my colorToInt(cl) as text)
	end if
	return spec
end parseSpec

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

on fmtTag(raw)
	set raw to raw as text
	if raw contains linefeed then
		set AppleScript's text item delimiters to linefeed
		set parts to text items of raw
		set AppleScript's text item delimiters to ""
		set nm to item 1 of parts
		try
			set ci to (item 2 of parts) as integer
			if ci ≥ 0 and ci ≤ 7 then return nm & ":" & item (ci + 1) of COLOR_NAMES
		end try
		return nm
	end if
	return raw
end fmtTag

-- ── subcommands ──────────────────────────────────────────────

on cmdList(args)
	if (count of args) is 0 then error "usage: tag-asobjc-full list <file>..."
	set multi to (count of args) > 1
	repeat with a in args
		set p to a as text
		set tags to my readRawTags(p)
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

on cmdSet(args)
	if (count of args) < 2 then error "usage: tag-asobjc-full set <spec>[,<spec>...] <file>..."
	set specs to my splitCommas(item 1 of args)
	set newTags to {}
	repeat with s in specs
		set end of newTags to my parseSpec(s as text)
	end repeat
	set fileArgs to items 2 thru -1 of args
	repeat with a in fileArgs
		set p to a as text
		my writeRawTags(p, newTags)
		log "tag set: " & p
	end repeat
end cmdSet

on cmdClear(args)
	if (count of args) is 0 then error "usage: tag-asobjc-full clear <file>..."
	repeat with a in args
		set p to a as text
		my writeRawTags(p, {})
		log "tag clear: " & p
	end repeat
end cmdClear

-- ── dispatch ─────────────────────────────────────────────────

on run argv
	if (count of argv) is 0 then
		log "usage: tag-asobjc-full {list|set|clear} ..."
		return
	end if
	set sub to item 1 of argv
	set restArgs to {}
	if (count of argv) > 1 then set restArgs to items 2 thru -1 of argv

	if sub is "list" or sub is "ls" then
		my cmdList(restArgs)
	else if sub is "set" then
		my cmdSet(restArgs)
	else if sub is "clear" then
		my cmdClear(restArgs)
	else
		error "unknown subcommand '" & sub & "' — try: list set clear"
	end if
end run
