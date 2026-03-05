# Notes — AppleScript Examples

> Ready-to-use AppleScript snippets for Notes
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Notes
tell application "Notes" to activate
```

```applescript
-- Check if Notes is running
if application "Notes" is running then
    tell application "Notes" to activate
end if
```
