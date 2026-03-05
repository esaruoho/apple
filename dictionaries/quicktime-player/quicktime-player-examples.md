# QuickTime Player — AppleScript Examples

> Ready-to-use AppleScript snippets for QuickTime Player
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate QuickTime Player
tell application "QuickTime Player" to activate
```

```applescript
-- Check if QuickTime Player is running
if application "QuickTime Player" is running then
    tell application "QuickTime Player" to activate
end if
```
