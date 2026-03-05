# Music — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 31 commands, 26 classes, 3 suites

```applescript
tell application "Music"
    -- commands go here
end tell
```

## Standard Suite

> Common terms for most applications

### Commands

#### `print`

Print the specified object(s)

- **Direct parameter**: `specifier` *(optional)* — list of objects to print
- **print dialog**: `boolean` *(optional)* — Should the application show the print dialog
- **with properties**: `print settings` *(optional)* — the print settings
- **kind**: `eKnd` *(optional)* — the kind of printout desired
- **theme**: `text` *(optional)* — name of theme to use for formatting the printout

#### `close`

Close an object

- **Direct parameter**: `specifier` — the object to close

#### `count`

Return the number of elements of a particular class within an object

- **Direct parameter**: `specifier` — the object whose elements are to be counted
- **each**: `type` — the class of the elements to be counted. Keyword 'each' is optional in AppleScript
- **Returns**: `integer` — the number of elements

#### `delete`

Delete an element from an object

- **Direct parameter**: `specifier` — the element to delete

#### `duplicate`

Duplicate one or more object(s)

- **Direct parameter**: `specifier` — the object(s) to duplicate
- **to**: `location specifier` *(optional)* — the new location for the object(s)
- **Returns**: `specifier` — to the duplicated object(s)

#### `exists`

Verify if an object exists

- **Direct parameter**: `specifier` — the object in question
- **Returns**: `boolean` — true if it exists, false if not

#### `make`

Make a new element

- **new**: `type` — the class of the new element. Keyword 'new' is optional in AppleScript
- **at**: `location specifier` *(optional)* — the location at which to insert the element
- **with properties**: `record` *(optional)* — the initial values for the properties of the element
- **Returns**: `specifier` — to the new object(s)

#### `move`

Move playlist(s) to a new location

- **Direct parameter**: `playlist` — the playlist(s) to move
- **to**: `location specifier` — the new location for the playlist(s)

#### `open`

Open the specified object(s)

- **Direct parameter**: `specifier` — list of objects to open

#### `run`

Run the application


#### `quit`

Quit the application


#### `save`

Save the specified object(s)

- **Direct parameter**: `specifier` — the object(s) to save

### Enumerations

#### `eKnd`

- `track listing` — a basic listing of tracks within a playlist
- `album listing` — a listing of a playlist grouped by album
- `cd insert` — a printout of the playlist for jewel case inserts

#### `enum`

- `standard` — Standard PostScript error handling
- `detailed` — print a detailed report of PostScript errors

## Music Suite

> The event suite specific to Music

### Commands

#### `add`

add one or more files to a playlist

- **Direct parameter**: `specifier` — the file(s) to add
- **to**: `location specifier` *(optional)* — the location of the added file(s)
- **Returns**: `track` — reference to added track(s)

#### `back track`

reposition to beginning of current track or go to previous track if already at start of current track


#### `convert`

convert one or more files or tracks

- **Direct parameter**: `specifier` — the file(s)/tracks(s) to convert
- **Returns**: `track` — reference to converted track(s)

#### `download`

download a cloud track or playlist

- **Direct parameter**: `item` — the shared track, URL track or playlist to download

#### `export`

export a source or playlist

- **Direct parameter**: `item` — the source or playlist to export
- **as**: `eExF` *(optional)* — the format to export for a playlist
- **to**: `file` *(optional)* — the destination of the export
- **Returns**: `text` — the exported data for the source or playlist, if not written to a file

#### `fast forward`

skip forward in a playing track


#### `next track`

advance to the next track in the current playlist


#### `pause`

pause playback


#### `play`

play the current track or the specified track or file.

- **Direct parameter**: `specifier` *(optional)* — item to play
- **once**: `boolean` *(optional)* — If true, play this track once and then stop.

#### `playpause`

toggle the playing/paused state of the current track


#### `previous track`

return to the previous track in the current playlist


#### `refresh`

update file track information from the current information in the track’s file

- **Direct parameter**: `file track` — the file track to update

#### `resume`

disable fast forward/rewind and resume playback, if playing.


#### `reveal`

reveal and select a track or playlist

- **Direct parameter**: `item` — the item to reveal

#### `rewind`

skip backwards in a playing track


#### `search`

search a playlist for tracks matching the search string. Identical to entering search text in the Search field.

- **Direct parameter**: `playlist` — the playlist to search
- **for**: `text` — the search text
- **only**: `eSrA` *(optional)* — area to search (default is all)
- **Returns**: `track` — reference to found track(s)

#### `select`

select the specified object(s)

- **Direct parameter**: `specifier` — the object(s) to select

#### `stop`

stop playback


### Classes

#### `AirPlay device`

an AirPlay device

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `active` | `boolean` | r | is the device currently being played to? |
| `available` | `boolean` | r | is the device currently available? |
| `kind` | `eAPD` | r | the kind of the device |
| `network address` | `text` | r | the network (MAC) address of the device |
| `protected` | `boolean` | r | is the device password- or passcode-protected? |
| `selected` | `boolean` | rw | is the device currently selected? |
| `supports audio` | `boolean` | r | does the device support audio playback? |
| `supports video` | `boolean` | r | does the device support video playback? |
| `sound volume` | `integer` | rw | the output volume for the device (0 = minimum, 100 = maximum) |

#### `application`

The application program

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `AirPlay enabled` | `boolean` | r | is AirPlay currently enabled? |
| `converting` | `boolean` | r | is a track currently being converted? |
| `current AirPlay devices` | `` | rw | the currently selected AirPlay device(s) |
| `current encoder` | `encoder` | rw | the currently selected encoder (MP3, AIFF, WAV, etc.) |
| `current EQ preset` | `EQ preset` | rw | the currently selected equalizer preset |
| `current playlist` | `playlist` | r | the playlist containing the currently targeted track |
| `current stream title` | `text` | r | the name of the current track in the playing stream (provided by streaming server) |
| `current stream URL` | `text` | r | the URL of the playing stream or streaming web site (provided by streaming server) |
| `current track` | `track` | r | the current targeted track |
| `current visual` | `visual` | rw | the currently selected visual plug-in |
| `EQ enabled` | `boolean` | rw | is the equalizer enabled? |
| `fixed indexing` | `boolean` | rw | true if all AppleScript track indices should be independent of the play order of the owning playlist. |
| `frontmost` | `boolean` | rw | is this the active application? |
| `full screen` | `boolean` | rw | is the application using the entire screen? |
| `name` | `text` | r | the name of the application |
| `mute` | `boolean` | rw | has the sound output been muted? |
| `player position` | `real` | rw | the player’s position within the currently playing track in seconds. |
| `player state` | `ePlS` | r | is the player stopped, paused, or playing? |
| `selection` | `specifier` | r | the selection visible to the user |
| `shuffle enabled` | `boolean` | rw | are songs played in random order? |
| `shuffle mode` | `eShM` | rw | the playback shuffle mode |
| `song repeat` | `eRpt` | rw | the playback repeat mode |
| `sound volume` | `integer` | rw | the sound output volume (0 = minimum, 100 = maximum) |
| `version` | `text` | r | the version of the application |
| `visuals enabled` | `boolean` | rw | are visuals currently being displayed? |

**Contains**: `AirPlay device`, `browser window`, `encoder`, `EQ preset`, `EQ window`, `miniplayer window`, `playlist`, `playlist window`, `source`, `track`, `video window`, `visual`, `window`

#### `artwork`

a piece of art within a track or playlist

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `data` | `picture` | rw | data for this artwork, in the form of a picture |
| `description` | `text` | rw | description of artwork as a string |
| `downloaded` | `boolean` | r | was this artwork downloaded by Music? |
| `format` | `type` | r | the data format for this piece of artwork |
| `kind` | `integer` | rw | kind or purpose of this piece of artwork |
| `raw data` | `any` | rw | data for this artwork, in original format |

#### `audio CD playlist`

a playlist representing an audio CD

*Inherits from: `playlist`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `artist` | `text` | rw | the artist of the CD |
| `compilation` | `boolean` | rw | is this CD a compilation album? |
| `composer` | `text` | rw | the composer of the CD |
| `disc count` | `integer` | rw | the total number of discs in this CD’s album |
| `disc number` | `integer` | rw | the index of this CD disc in the source album |
| `genre` | `text` | rw | the genre of the CD |
| `year` | `integer` | rw | the year the album was recorded/released |

**Contains**: `audio CD track`

#### `audio CD track`

a track on an audio CD

*Inherits from: `track`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `location` | `file` | r | the location of the file represented by this track |

#### `browser window`

the main window

*Inherits from: `window`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `selection` | `specifier` | r | the selected tracks |
| `view` | `playlist` | rw | the playlist currently displayed in the window |

#### `encoder`

converts a track to a specific file format

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `format` | `text` | r | the data format created by the encoder |

#### `EQ preset`

equalizer preset configuration

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `band 1` | `real` | rw | the equalizer 32 Hz band level (-12.0 dB to +12.0 dB) |
| `band 2` | `real` | rw | the equalizer 64 Hz band level (-12.0 dB to +12.0 dB) |
| `band 3` | `real` | rw | the equalizer 125 Hz band level (-12.0 dB to +12.0 dB) |
| `band 4` | `real` | rw | the equalizer 250 Hz band level (-12.0 dB to +12.0 dB) |
| `band 5` | `real` | rw | the equalizer 500 Hz band level (-12.0 dB to +12.0 dB) |
| `band 6` | `real` | rw | the equalizer 1 kHz band level (-12.0 dB to +12.0 dB) |
| `band 7` | `real` | rw | the equalizer 2 kHz band level (-12.0 dB to +12.0 dB) |
| `band 8` | `real` | rw | the equalizer 4 kHz band level (-12.0 dB to +12.0 dB) |
| `band 9` | `real` | rw | the equalizer 8 kHz band level (-12.0 dB to +12.0 dB) |
| `band 10` | `real` | rw | the equalizer 16 kHz band level (-12.0 dB to +12.0 dB) |
| `modifiable` | `boolean` | r | can this preset be modified? |
| `preamp` | `real` | rw | the equalizer preamp level (-12.0 dB to +12.0 dB) |
| `update tracks` | `boolean` | rw | should tracks which refer to this preset be updated when the preset is renamed or deleted? |

#### `EQ window`

the equalizer window

*Inherits from: `window`*

#### `file track`

a track representing an audio file (MP3, AIFF, etc.)

*Inherits from: `track`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `location` | `file` | rw | the location of the file represented by this track |

#### `folder playlist`

a folder that contains other playlists

*Inherits from: `user playlist`*

#### `item`

an item

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `class` | `type` | r | the class of the item |
| `container` | `specifier` | r | the container of the item |
| `id` | `integer` | r | the id of the item |
| `index` | `integer` | r | the index of the item in internal application order |
| `name` | `text` | rw | the name of the item |
| `persistent ID` | `text` | r | the id of the item as a hexadecimal string. This id does not change over time. |
| `properties` | `record` | rw | every property of the item |

#### `library playlist`

the main library playlist

*Inherits from: `playlist`*

**Contains**: `file track`, `URL track`, `shared track`

#### `miniplayer window`

the miniplayer window

*Inherits from: `window`*

#### `playlist`

a list of tracks/streams

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `description` | `text` | rw | the description of the playlist |
| `disliked` | `boolean` | rw | is this playlist disliked? |
| `duration` | `integer` | r | the total length of all tracks (in seconds) |
| `name` | `text` | rw | the name of the playlist |
| `favorited` | `boolean` | rw | is this playlist favorited? |
| `parent` | `playlist` | r | folder which contains this playlist (if any) |
| `size` | `integer` | r | the total size of all tracks (in bytes) |
| `special kind` | `eSpK` | r | special playlist kind |
| `time` | `text` | r | the length of all tracks in MM:SS format |
| `visible` | `boolean` | r | is this playlist visible in the Source list? |

**Contains**: `track`, `artwork`

#### `playlist window`

a sub-window showing a single playlist

*Inherits from: `window`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `selection` | `specifier` | r | the selected tracks |
| `view` | `playlist` | r | the playlist displayed in the window |

#### `radio tuner playlist`

the radio tuner playlist

*Inherits from: `playlist`*

**Contains**: `URL track`

#### `shared track`

a track residing in a shared library

*Inherits from: `track`*

#### `source`

a media source (library, CD, device, etc.)

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `capacity` | `double integer` | r | the total size of the source if it has a fixed size |
| `free space` | `double integer` | r | the free space on the source if it has a fixed size |
| `kind` | `eSrc` | r |  |

**Contains**: `audio CD playlist`, `library playlist`, `playlist`, `radio tuner playlist`, `subscription playlist`, `user playlist`

#### `subscription playlist`

a subscription playlist from Apple Music

*Inherits from: `playlist`*

**Contains**: `file track`, `URL track`

#### `track`

playable audio source

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `album` | `text` | rw | the album name of the track |
| `album artist` | `text` | rw | the album artist of the track |
| `album disliked` | `boolean` | rw | is the album for this track disliked? |
| `album favorited` | `boolean` | rw | is the album for this track favorited? |
| `album rating` | `integer` | rw | the rating of the album for this track (0 to 100) |
| `album rating kind` | `eRtK` | r | the rating kind of the album rating for this track |
| `artist` | `text` | rw | the artist/source of the track |
| `bit rate` | `integer` | r | the bit rate of the track (in kbps) |
| `bookmark` | `real` | rw | the bookmark time of the track in seconds |
| `bookmarkable` | `boolean` | rw | is the playback position for this track remembered? |
| `bpm` | `integer` | rw | the tempo of this track in beats per minute |
| `category` | `text` | rw | the category of the track |
| `cloud status` | `eClS` | r | the iCloud status of the track |
| `comment` | `text` | rw | freeform notes about the track |
| `compilation` | `boolean` | rw | is this track from a compilation album? |
| `composer` | `text` | rw | the composer of the track |
| `database ID` | `integer` | r | the common, unique ID for this track. If two tracks in different playlists have the same database ID, they are sharing the same data. |
| `date added` | `date` | r | the date the track was added to the playlist |
| `description` | `text` | rw | the description of the track |
| `disc count` | `integer` | rw | the total number of discs in the source album |
| `disc number` | `integer` | rw | the index of the disc containing this track on the source album |
| `disliked` | `boolean` | rw | is this track disliked? |
| `downloader account` | `text` | r | the account of the person who downloaded this track |
| `downloader name` | `text` | r | the name of the person who downloaded this track |
| `duration` | `real` | r | the length of the track in seconds |
| `enabled` | `boolean` | rw | is this track checked for playback? |
| `episode ID` | `text` | rw | the episode ID of the track |
| `episode number` | `integer` | rw | the episode number of the track |
| `EQ` | `text` | rw | the name of the EQ preset of the track |
| `finish` | `real` | rw | the stop time of the track in seconds |
| `gapless` | `boolean` | rw | is this track from a gapless album? |
| `genre` | `text` | rw | the music/audio genre (category) of the track |
| `grouping` | `text` | rw | the grouping (piece) of the track. Generally used to denote movements within a classical work. |
| `kind` | `text` | r | a text description of the track |
| `long description` | `text` | rw | the long description of the track |
| `favorited` | `boolean` | rw | is this track favorited? |
| `lyrics` | `text` | rw | the lyrics of the track |
| `media kind` | `eMdK` | rw | the media kind of the track |
| `modification date` | `date` | r | the modification date of the content of this track |
| `movement` | `text` | rw | the movement name of the track |
| `movement count` | `integer` | rw | the total number of movements in the work |
| `movement number` | `integer` | rw | the index of the movement in the work |
| `played count` | `integer` | rw | number of times this track has been played |
| `played date` | `date` | rw | the date and time this track was last played |
| `purchaser account` | `text` | r | the account of the person who purchased this track |
| `purchaser name` | `text` | r | the name of the person who purchased this track |
| `rating` | `integer` | rw | the rating of this track (0 to 100) |
| `rating kind` | `eRtK` | r | the rating kind of this track |
| `release date` | `date` | r | the release date of this track |
| `sample rate` | `integer` | r | the sample rate of the track (in Hz) |
| `season number` | `integer` | rw | the season number of the track |
| `shufflable` | `boolean` | rw | is this track included when shuffling? |
| `skipped count` | `integer` | rw | number of times this track has been skipped |
| `skipped date` | `date` | rw | the date and time this track was last skipped |
| `show` | `text` | rw | the show name of the track |
| `sort album` | `text` | rw | override string to use for the track when sorting by album |
| `sort artist` | `text` | rw | override string to use for the track when sorting by artist |
| `sort album artist` | `text` | rw | override string to use for the track when sorting by album artist |
| `sort name` | `text` | rw | override string to use for the track when sorting by name |
| `sort composer` | `text` | rw | override string to use for the track when sorting by composer |
| `sort show` | `text` | rw | override string to use for the track when sorting by show name |
| `size` | `double integer` | r | the size of the track (in bytes) |
| `start` | `real` | rw | the start time of the track in seconds |
| `time` | `text` | r | the length of the track in MM:SS format |
| `track count` | `integer` | rw | the total number of tracks on the source album |
| `track number` | `integer` | rw | the index of the track on the source album |
| `unplayed` | `boolean` | rw | is this track unplayed? |
| `volume adjustment` | `integer` | rw | relative volume adjustment of the track (-100% to 100%) |
| `work` | `text` | rw | the work name of the track |
| `year` | `integer` | rw | the year the track was recorded/released |

**Contains**: `artwork`

#### `URL track`

a track representing a network stream

*Inherits from: `track`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `address` | `text` | rw | the URL for this track |

#### `user playlist`

custom playlists created by the user

*Inherits from: `playlist`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `shared` | `boolean` | rw | is this playlist shared? |
| `smart` | `boolean` | r | is this a Smart Playlist? |
| `genius` | `boolean` | r | is this a Genius Playlist? |

**Contains**: `file track`, `URL track`, `shared track`

#### `video window`

the video window

*Inherits from: `window`*

#### `visual`

a visual plug-in

*Inherits from: `item`*

#### `window`

any window

*Inherits from: `item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `bounds` | `rectangle` | rw | the boundary rectangle for the window |
| `closeable` | `boolean` | r | does the window have a close button? |
| `collapseable` | `boolean` | r | does the window have a collapse button? |
| `collapsed` | `boolean` | rw | is the window collapsed? |
| `full screen` | `boolean` | rw | is the window full screen? |
| `position` | `point` | rw | the upper left position of the window |
| `resizable` | `boolean` | r | is the window resizable? |
| `visible` | `boolean` | rw | is the window visible? |
| `zoomable` | `boolean` | r | is the window zoomable? |
| `zoomed` | `boolean` | rw | is the window zoomed? |

### Enumerations

#### `ePlS`

- `stopped`
- `playing`
- `paused`
- `fast forwarding`
- `rewinding`

#### `eRpt`

- `off`
- `one`
- `all`

#### `eShM`

- `songs`
- `albums`
- `groupings`

#### `eSrc`

- `library`
- `audio CD`
- `MP3 CD`
- `radio tuner`
- `shared library`
- `iTunes Store`
- `unknown`

#### `eSrA`

- `albums` — albums only
- `all` — all text fields
- `artists` — artists only
- `composers` — composers only
- `displayed` — visible text fields
- `names` — track names only

#### `eSpK`

- `none`
- `folder`
- `Genius`
- `Library`
- `Music`
- `Purchased Music`

#### `eMdK`

- `song` — music track
- `music video` — music video track
- `movie` — movie track
- `TV show` — TV show track
- `unknown`

#### `eRtK`

- `user` — user-specified rating
- `computed` — computed rating

#### `eAPD`

- `computer`
- `AirPort Express`
- `Apple TV`
- `AirPlay device`
- `Bluetooth device`
- `HomePod`
- `TV`
- `unknown`

#### `eClS`

- `unknown`
- `purchased`
- `matched`
- `uploaded`
- `ineligible`
- `removed`
- `error`
- `duplicate`
- `subscription`
- `prerelease`
- `no longer available`
- `not uploaded`

#### `eExF`

- `plain text`
- `Unicode text`
- `XML`
- `M3U`
- `M3U8`

## Internet suite

> Standard terms for Internet scripting

### Commands

#### `open location`

Opens an iTunes Store or audio stream URL

- **Direct parameter**: `text` *(optional)* — the URL to open
