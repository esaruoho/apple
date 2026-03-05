# Reminders — AppleScript Examples

> Ready-to-use AppleScript snippets for Reminders
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Reminders
tell application "Reminders" to activate
```

```applescript
-- Check if Reminders is running
if application "Reminders" is running then
    tell application "Reminders" to activate
end if
```
