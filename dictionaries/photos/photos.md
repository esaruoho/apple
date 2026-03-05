# Photos — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 18 commands, 5 classes, 2 suites

```applescript
tell application "Photos"
    -- commands go here
end tell
```

## Standard Suite

> Common classes and commands for all applications.

### Commands

#### `count`

Return the number of elements of a particular class within an object.

- **Direct parameter**: `specifier` — The objects to be counted.
- **each**: `type` *(optional)* — The class of objects to be counted.
- **Returns**: `integer` — The count.

#### `exists`

Verify that an object exists.

- **Direct parameter**: `any` — The object(s) to check.
- **Returns**: `boolean` — Did the object(s) exist?

#### `open`

Open a photo library

- **Direct parameter**: `specifier` — The photo library to be opened.

#### `quit`

Quit the application.


### Classes

#### `application`

The application's top-level scripting object.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of the application. |
| `frontmost` | `boolean` | r | Is this the active application? |
| `version` | `text` | r | The version number of the application. |

## Photos Suite

> Classes and commands for Photos

### Commands

#### `import`

Import files into the library

- **Direct parameter**: `specifier` — The list of files to copy.
- **into**: `album` *(optional)* — The album to import into.
- **skip check duplicates**: `boolean` *(optional)* — Skip duplicate checking and import everything, defaults to false.
- **Returns**: `specifier` — The imported media items in an array

#### `export`

Export media items to the specified location as files

- **Direct parameter**: `specifier` — The list of media items to export.
- **to**: `file` — The destination of the export.
- **using originals**: `boolean` *(optional)* — Export the original files if true, otherwise export rendered jpgs. defaults to false.

#### `duplicate`

Duplicate an object.  Only media items can be duplicated

- **Direct parameter**: `specifier` — The media item to duplicate
- **Returns**: `media item` — The duplicated media item

#### `make`

Create a new object.  Only new albums and folders can be created.

- **new**: `type` — The class of the new object, allowed values are album or folder
- **named**: `text` *(optional)* — The name of the new object.
- **at**: `folder` *(optional)* — The parent folder for the new object.
- **Returns**: `specifier` — The new object.

#### `delete`

Delete an object.  Only albums and folders can be deleted.

- **Direct parameter**: `specifier` — The album or folder to delete.

#### `add`

Add media items to an album.

- **Direct parameter**: `specifier` — The list of media items to add.
- **to**: `album` — The album to add to.

#### `start slideshow`

Display an ad-hoc slide show from a list of media items, an album, or a folder.

- **using**: `specifier` — The media items to show.

#### `stop slideshow`

End the currently-playing slideshow.


#### `next slide`

Skip to next slide in currently-playing slideshow.


#### `previous slide`

Skip to previous slide in currently-playing slideshow.


#### `pause slideshow`

Pause the currently-playing slideshow.


#### `resume slideshow`

Resume the currently-playing slideshow.


#### `spotlight`

Show the image at path in the application, used to show spotlight search results

- **Direct parameter**: `specifier` — The full path to the image

#### `search`

search for items matching the search string. Identical to entering search text in the Search field in Photos

- **for**: `text` — The text to search for
- **Returns**: `specifier` — reference(s) to found media item(s)

### Classes

#### `media item`

A media item, such as a photo or video.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `keywords` | `` | rw | A list of keywords to associate with a media item |
| `name` | `text` | rw | The name (title) of the media item. |
| `description` | `text` | rw | A description of the media item. |
| `favorite` | `boolean` | rw | Whether the media item has been favorited. |
| `date` | `date` | rw | The date of the media item |
| `id` | `text` | r | The unique ID of the media item |
| `height` | `integer` | r | The height of the media item in pixels. |
| `width` | `integer` | r | The width of the media item in pixels. |
| `filename` | `text` | r | The name of the file on disk. |
| `altitude` | `real` | r | The GPS altitude in meters. |
| `size` | `integer` | rw | The selected media item file size. |
| `location` | `` | rw | The GPS latitude and longitude, in an ordered list of 2 numbers or missing values.  Latitude in range -90.0 to 90.0, longitude in range -180.0 to 180.0. |

#### `container`

Base class for collections that contains other items, such as albums and folders

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `text` | r | The unique ID of this container. |
| `name` | `text` | rw | The name of this container. |
| `parent` | `folder` | r | This container's parent folder, if any. |

#### `album`

An album. A container that holds media items

*Inherits from: `container`*

**Contains**: `media item`

#### `folder`

A folder. A container that holds albums and other folders, but not media items

*Inherits from: `container`*

**Contains**: `container`, `album`, `folder`
