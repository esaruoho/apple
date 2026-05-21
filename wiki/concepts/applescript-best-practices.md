# AppleScript Best Practices

1. **Activate apps**: Use `tell application "AppName" to activate`
2. **Check if running**: `if application "AppName" is running then`
3. **System Events for UI**: `tell application "System Events"` for keystroke simulation, menu clicks, window manipulation
4. **Error handling**: Wrap risky operations in `try ... on error ... end try`
5. **Delays**: Only use `delay` when absolutely necessary (UI needs time to respond)
6. **Finder operations**: Finder is always running on macOS — just activate it
7. **AppleScript + CLI combo**: Run `osascript script.scpt &` in background from bash — fire and forget
8. **Use scripting dictionaries**: Before writing a script, check `dictionaries/<app>.md` for available commands, classes, and properties
9. **Use `shortcuts run`**: The `shortcuts` CLI bridges AppleScript (depth) to App Intents (width) — Sal's AND not OR

