# Safari — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 10 commands, 1 classes, 1 suites

```applescript
tell application "Safari"
    -- commands go here
end tell
```

## Safari suite

> Safari specific classes

### Commands

#### `add reading list item`

Add a new Reading List item with the given URL. Allows a custom title and preview text to be specified.

- **Direct parameter**: `text` — URL of the Reading List item
- **and preview text**: `text` *(optional)* — Preview text for the Reading List item, usually the first few sentences of the article
- **with title**: `text` *(optional)* — Title of the Reading List item

#### `do JavaScript`

Applies a string of JavaScript code to a document.

- **Direct parameter**: `text` — The JavaScript code to evaluate.
- **in**: `specifier` *(optional)* — The tab that the JavaScript should be evaluated in.
- **Returns**: `any` — 

#### `email contents`

Emails the contents of a tab.

- **of**: `specifier` *(optional)* — The tab to send.

#### `search the web`

Searches the web using Safari's current search provider.

- **in**: `specifier` *(optional)* — The tab that the search results should shown in.
- **for**: `text` — The query to search for.

#### `show bookmarks`

Shows Safari's bookmarks.


#### `show extensions preferences`

Show Safari Extensions preferences.

- **Direct parameter**: `text` — The identifier of the extension to select.

#### `dispatch message to extension`

Dispatch a message to a Safari Extension.

- **Direct parameter**: `any` — A dictionary describing the message

#### `sync all plist to disk`

Make sure that all in-memory structures are in-sync with their on-disk counterparts.


#### `show privacy report`

Show Safari's Privacy Report


#### `show credit card settings`

Show Safari Credit Card Settings.


### Classes

#### `tab`

A Safari window tab.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `source` | `text` | r | The HTML source of the web page currently loaded in the tab. |
| `URL` | `text` | rw | The current URL of the tab. |
| `index` | `number` | r | The index of the tab, ordered left to right. |
| `text` | `text` | r | The text of the web page currently loaded in the tab. Modifications to text aren't reflected on the web page. |
| `visible` | `boolean` | r | Whether the tab is currently visible. |
| `name` | `text` | r | The name of the tab. |
