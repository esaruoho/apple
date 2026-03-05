# Bluetooth File Exchange — AppleScript Examples

> Ready-to-use AppleScript snippets for Bluetooth File Exchange
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Bluetooth File Exchange
tell application "Bluetooth File Exchange" to activate
```

```applescript
-- Check if Bluetooth File Exchange is running
if application "Bluetooth File Exchange" is running then
    tell application "Bluetooth File Exchange" to activate
end if
```
