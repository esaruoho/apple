# Image Events — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 13 commands, 16 classes, 3 suites

```applescript
tell application "Image Events"
    -- commands go here
end tell
```

## Disk-Folder-File Suite

> Terms and Events for controlling Disks, Folders, and Files

### Commands

#### `delete`

Delete disk item(s).

- **Direct parameter**: `disk item` — The disk item(s) to be deleted.

#### `move`

Move disk item(s) to a new location.

- **Direct parameter**: `specifier` — The disk item(s) to be moved.
- **to**: `specifier` — The new location for the disk item(s).
- **Returns**: `specifier` — 

#### `open`

Open disk item(s) with the appropriate application.

- **Direct parameter**: `specifier` — The disk item(s) to be opened.
- **Returns**: `file` — 

### Classes

#### `alias`

An alias in the file system

*Inherits from: `disk item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `creator type` | `` | rw | the OSType identifying the application that created the alias |
| `default application` | `` | rw | the application that will launch if the alias is opened |
| `file type` | `` | rw | the OSType identifying the type of data contained in the alias |
| `kind` | `text` | r | The kind of alias, as shown in Finder |
| `product version` | `text` | r | the version of the product (visible at the top of the "Get Info" window) |
| `short version` | `text` | r | the short version of the application bundle referenced by the alias |
| `stationery` | `boolean` | rw | Is the alias a stationery pad? |
| `type identifier` | `text` | r | The type identifier of the alias |
| `version` | `text` | r | the version of the application bundle referenced by the alias (visible at the bottom of the "Get Info" window) |

**Contains**: `alias`, `disk item`, `file`, `file package`, `folder`, `item`

#### `Classic domain object`

The Classic domain in the file system

*Inherits from: `domain`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `apple menu folder` | `folder` | r | The Apple Menu Items folder |
| `control panels folder` | `folder` | r | The Control Panels folder |
| `control strip modules folder` | `folder` | r | The Control Strip Modules folder |
| `desktop folder` | `folder` | r | The Classic Desktop folder |
| `extensions folder` | `folder` | r | The Extensions folder |
| `fonts folder` | `folder` | r | The Fonts folder |
| `launcher items folder` | `folder` | r | The Launcher Items folder |
| `preferences folder` | `folder` | r | The Classic Preferences folder |
| `shutdown folder` | `folder` | r | The Shutdown Items folder |
| `startup items folder` | `folder` | r | The StartupItems folder |
| `system folder` | `folder` | r | The System folder |

**Contains**: `folder`

#### `disk`

A disk in the file system

*Inherits from: `disk item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `capacity` | `number` | r | the total number of bytes (free or used) on the disk |
| `ejectable` | `boolean` | r | Can the media be ejected (floppies, CD's, and so on)? |
| `format` | `edfm` | r | the file system format of this disk |
| `free space` | `number` | r | the number of free bytes left on the disk |
| `ignore privileges` | `boolean` | rw | Ignore permissions on this disk? |
| `local volume` | `boolean` | r | Is the media a local volume (as opposed to a file server)? |
| `server` | `` | r | the server on which the disk resides, AFP volumes only |
| `startup` | `boolean` | r | Is this disk the boot disk? |
| `zone` | `` | r | the zone in which the disk's server resides, AFP volumes only |

**Contains**: `alias`, `disk item`, `file`, `file package`, `folder`, `item`

#### `disk item`

An item stored in the file system

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `busy status` | `boolean` | r | Is the disk item busy? |
| `container` | `disk item` | r | the folder or disk which has this disk item as an element |
| `creation date` | `date` | r | the date on which the disk item was created |
| `displayed name` | `text` | r | the name of the disk item as displayed in the User Interface |
| `id` | `text` | r | the unique ID of the disk item |
| `modification date` | `date` | rw | the date on which the disk item was last modified |
| `name` | `text` | rw | the name of the disk item |
| `name extension` | `text` | r | the extension portion of the name |
| `package folder` | `boolean` | r | Is the disk item a package? |
| `path` | `text` | r | the file system path of the disk item |
| `physical size` | `integer` | r | the actual space used by the disk item on disk |
| `POSIX path` | `text` | r | the POSIX file system path of the disk item |
| `size` | `integer` | r | the logical size of the disk item |
| `URL` | `text` | r | the URL of the disk item |
| `visible` | `boolean` | rw | Is the disk item visible? |
| `volume` | `text` | r | the volume on which the disk item resides |

#### `domain`

A domain in the file system

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `application support folder` | `folder` | r | The Application Support folder |
| `applications folder` | `folder` | r | The Applications folder |
| `desktop pictures folder` | `folder` | r | The Desktop Pictures folder |
| `Folder Action scripts folder` | `folder` | r | The Folder Action Scripts folder |
| `fonts folder` | `folder` | r | The Fonts folder |
| `id` | `text` | r | the unique identifier of the domain |
| `library folder` | `folder` | r | The Library folder |
| `name` | `text` | r | the name of the domain |
| `preferences folder` | `folder` | r | The Preferences folder |
| `scripting additions folder` | `folder` | r | The Scripting Additions folder |
| `scripts folder` | `folder` | r | The Scripts folder |
| `shared documents folder` | `folder` | r | The Shared Documents folder |
| `speakable items folder` | `folder` | r | The Speakable Items folder |
| `utilities folder` | `folder` | r | The Utilities folder |
| `workflows folder` | `folder` | r | The Automator Workflows folder |

**Contains**: `folder`

#### `file`

A file in the file system

*Inherits from: `disk item`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `creator type` | `` | rw | the OSType identifying the application that created the file |
| `default application` | `` | rw | the application that will launch if the file is opened |
| `file type` | `` | rw | the OSType identifying the type of data contained in the file |
| `kind` | `text` | r | The kind of file, as shown in Finder |
| `product version` | `text` | r | the version of the product (visible at the top of the "Get Info" window) |
| `short version` | `text` | r | the short version of the file |
| `stationery` | `boolean` | rw | Is the file a stationery pad? |
| `type identifier` | `text` | r | The type identifier of the file |
| `version` | `text` | r | the version of the file (visible at the bottom of the "Get Info" window) |

#### `file package`

A file package in the file system

*Inherits from: `file`*

**Contains**: `alias`, `disk item`, `file`, `file package`, `folder`, `item`

#### `folder`

A folder in the file system

*Inherits from: `disk item`*

**Contains**: `alias`, `disk item`, `file`, `file package`, `folder`, `item`

#### `local domain object`

The local domain in the file system

*Inherits from: `domain`*

**Contains**: `folder`

#### `network domain object`

The network domain in the file system

*Inherits from: `domain`*

**Contains**: `folder`

#### `system domain object`

The system domain in the file system

*Inherits from: `domain`*

**Contains**: `folder`

#### `user domain object`

The user domain in the file system

*Inherits from: `domain`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `desktop folder` | `folder` | r | The user's Desktop folder |
| `documents folder` | `folder` | r | The user's Documents folder |
| `downloads folder` | `folder` | r | The user's Downloads folder |
| `favorites folder` | `folder` | r | The user's Favorites folder |
| `home folder` | `folder` | r | The user's Home folder |
| `movies folder` | `folder` | r | The user's Movies folder |
| `music folder` | `folder` | r | The user's Music folder |
| `pictures folder` | `folder` | r | The user's Pictures folder |
| `public folder` | `folder` | r | The user's Public folder |
| `sites folder` | `folder` | r | The user's Sites folder |
| `temporary items folder` | `folder` | r | The Temporary Items folder |

**Contains**: `folder`

### Enumerations

#### `edfm`

- `Apple Photo format` — Apple Photo format
- `AppleShare format` — AppleShare format
- `audio format` — audio format
- `High Sierra format` — High Sierra format
- `ISO 9660 format` — ISO 9660 format
- `Mac OS Extended format` — Mac OS Extended format
- `Mac OS format` — Mac OS format
- `MSDOS format` — MSDOS format
- `NFS format` — NFS format
- `ProDOS format` — ProDOS format
- `QuickTake format` — QuickTake format
- `UDF format` — UDF format
- `UFS format` — UFS format
- `unknown format` — unknown format
- `WebDAV format` — WebDAV format

## Image Suite

> Terms and Events for controlling Images

### Commands

#### `close`

Close an image

- **Direct parameter**: `specifier` — the object for the command
- **saving**: `savo` *(optional)* — Specifies whether changes should be saved before closing.
- **saving in**: `text` *(optional)* — The file in which to save the image.

#### `crop`

Crop an image

- **Direct parameter**: `specifier` — the object for the command
- **to dimensions**: `specifier` — the width and height of the new image, respectively, in pixels, as a pair of integers

#### `embed`

Embed an image with an ICC profile

- **Direct parameter**: `specifier` — the object for the command
- **with source**: `profile` — the profile to embed in the image

#### `flip`

Flip an image

- **Direct parameter**: `specifier` — the object for the command
- **horizontal**: `boolean` *(optional)* — flip horizontally
- **vertical**: `boolean` *(optional)* — flip vertically

#### `match`

Match an image

- **Direct parameter**: `specifier` — the object for the command
- **to destination**: `profile` — the destination profile for the match

#### `pad`

Pad an image

- **Direct parameter**: `specifier` — the object for the command
- **to dimensions**: `specifier` — the width and height of the new image, respectively, in pixels, as a pair of integers
- **with pad color**: `specifier` *(optional)* — the RGB color values with which to pad the new image, as a list of integers

#### `rotate`

Rotate an image

- **Direct parameter**: `specifier` — the object for the command
- **to angle**: `real` — rotate using an angle

#### `save`

Save an image to a file in one of various formats

- **Direct parameter**: `specifier` — the object for the command
- **as**: `typv` *(optional)* — file type in which to save the image ( default is to make no change )
- **icon**: `boolean` *(optional)* — Shall an icon be added? ( default is false )
- **in**: `text` *(optional)* — file path in which to save the image, in HFS or POSIX form
- **PackBits**: `boolean` *(optional)* — Are the bytes to be compressed with PackBits? ( default is false, applies only to TIFF )
- **with compression level**: `cmlv` *(optional)* — specifies the compression level of the resultant file ( applies only to JPEG )
- **Returns**: `alias` — 

#### `scale`

Scale an image

- **Direct parameter**: `specifier` — the object for the command
- **by factor**: `real` *(optional)* — scale using a scalefactor
- **to size**: `integer` *(optional)* — scale using a max width/length

#### `unembed`

Remove any embedded ICC profiles from an image

- **Direct parameter**: `specifier` — the object for the command

### Classes

#### `display`

A monitor connected to the computer

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `display number` | `integer` | r | the number of the display |
| `display profile` | `profile` | r | the profile for the display |
| `name` | `text` | r | the name of the display |

#### `image`

An image contained in a file

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `bit depth` | `bitz` | r | bit depth of the image's color representation |
| `color space` | `pSpc` | r | color space of the image's color representation |
| `dimensions` | `` | r | the width and height of the image, respectively, in pixels |
| `embedded profile` | `profile` | r | the profile, if any, embedded in the image |
| `file type` | `` | r | file type of the image's file |
| `image file` | `file` | r | the file that contains the image |
| `location` | `disk item` | r | the folder or disk that encloses the file that contains the image |
| `name` | `text` | r | the name of the image |
| `resolution` | `` | r | the horizontal and vertical pixel density of the image, respectively, in dots per inch |

**Contains**: `metadata tag`, `profile`

#### `metadata tag`

A metadata tag: EXIF, IPTC, etc.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | the name of the tag |
| `value` | `` | r | the current setting of the tag |

#### `profile`

A ColorSync ICC profile.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `color space` | `pSpc` | r | the color space of the profile |
| `connection space` | `pPCS` | r | the connection space of the profile |
| `creation date` | `date` | r | the creation date of the profile |
| `creator` | `text` | r | the creator type of the profile |
| `device class` | `pCla` | r | the device class of the profile |
| `device manufacturer` | `text` | r | the device manufacturer of the profile |
| `device model` | `integer` | r | the device model of the profile |
| `location` | `` | r | the file location of the profile |
| `name` | `text` | r | the description text of the profile |
| `platform` | `text` | r | the intended platform of the profile |
| `preferred CMM` | `text` | r | the preferred CMM of the profile |
| `quality` | `pQua` | r | the quality of the profile |
| `rendering intent` | `pRdr` | r | the rendering intent of the profile |
| `size` | `integer` | r | the size of the profile in bytes |
| `version` | `text` | r | the version number of the profile |

### Enumerations

#### `bitz`

- `best` — best
- `black & white` — black & white
- `color` — color
- `four colors` — four colors
- `four grays` — four grays
- `grayscale` — grayscale
- `millions of colors` — millions of colors
- `millions of colors plus` — millions of colors plus
- `sixteen colors` — sixteen colors
- `sixteen grays` — sixteen grays
- `thousands of colors` — thousands of colors
- `two hundred fifty six colors` — two hundred fifty six colors
- `two hundred fifty six grays` — two hundred fifty six grays

#### `pCla`

- `abstract` — abstract profile
- `colorspace` — colorspace profile
- `input` — input device
- `link` — device-link profile
- `monitor` — display device
- `named` — named color space profile
- `output` — output device

#### `pPCS`

- `Lab` — Lab
- `XYZ` — XYZ

#### `cmlv`

- `high` — High compression
- `low` — Low compression
- `medium` — Medium compression

#### `typz`

- `BMP` — BMP
- `GIF` — GIF
- `JPEG` — JPEG
- `JPEG2` — JPEG2
- `MacPaint` — MacPaint
- `PDF` — PDF
- `Photoshop` — Photoshop
- `PICT` — PICT
- `PNG` — PNG
- `PSD` — PSD
- `QuickTime Image` — QuickTime Image
- `SGI` — SGI
- `Text` — Text
- `TGA` — TGA
- `TIFF` — TIFF

#### `pQua`

- `best` — best
- `draft` — draft
- `normal` — normal

#### `pSpc`

- `CMYK` — CMYK
- `Eight channel` — Eight channel
- `Eight color` — Eight color
- `Five channel` — Five channel
- `Five color` — Five color
- `Gray` — Gray
- `Lab` — Lab
- `Named` — Named
- `RGB` — RGB
- `Seven channel` — Seven channel
- `Seven color` — Seven color
- `Six channel` — Six channel
- `Six color` — Six color
- `XYZ` — XYZ

#### `pRdr`

- `absolute colorimetric intent` — absolute colorimetric
- `perceptual intent` — perceptual
- `relative colorimetric intent` — relative colorimetric
- `saturation intent` — saturation

#### `savo`

- `no` — Do not save the image.
- `yes` — Save the image.

#### `qual`

- `best` — best
- `high` — high
- `least` — least
- `low` — low
- `medium` — medium

#### `typv`

- `BMP` — BMP
- `JPEG` — JPEG
- `JPEG2` — JPEG2
- `PICT` — PICT
- `PNG` — PNG
- `PSD` — PSD
- `QuickTime Image` — QuickTime Image
- `TIFF` — TIFF

## Image Events Suite

> Terms and Events for controlling the Image Events application

### Enumerations

#### `saveable file format`

- `text` — Text File Format
