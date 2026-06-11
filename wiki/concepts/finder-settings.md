# Finder Settings via `defaults`

> Every checkbox in **Finder ▸ Settings** (formerly Preferences) is a key in the
> `com.apple.finder` preference domain — except *Show all filename extensions*,
> which is global. Drive the domain with `defaults`, then `killall Finder` to
> apply. No UI scripting, no Accessibility prompt: this is the Apple way.

Tool: [`bin/finder-settings`](../../bin/finder-settings) · slash: `/finder-settings`

## Key map (Advanced pane)

| UI label | Domain | Key | Type |
|---|---|---|---|
| Show all filename extensions | `NSGlobalDomain` | `AppleShowAllExtensions` | bool |
| Show warning before changing an extension | `com.apple.finder` | `FXEnableExtensionChangeWarning` | bool |
| Show warning before removing from iCloud Drive | `com.apple.finder` | `FXEnableRemoveFromICloudDriveWarning` | bool |
| Show warning before emptying the Bin | `com.apple.finder` | `WarnOnEmptyTrash` | bool |
| Remove items from the Bin after 30 days | `com.apple.finder` | `FXRemoveOldTrashItems` | bool |
| Keep folders on top → In windows when sorting by name | `com.apple.finder` | `_FXSortFoldersFirst` | bool |
| Keep folders on top → On Desktop | `com.apple.finder` | `_FXSortFoldersFirstOnDesktop` | bool |
| When performing a search | `com.apple.finder` | `FXDefaultSearchScope` | string |

### Search scope string values

| Value | Menu item |
|---|---|
| `SCev` | Search This Mac *(this is also the default when the key is unset)* |
| `SCcf` | Search the Current Folder |
| `SCsp` | Use the Previous Search Scope |

## General pane (bonus toggles the tool also exposes)

`ShowHardDrivesOnDesktop`, `ShowExternalHardDrivesOnDesktop`,
`ShowRemovableMediaOnDesktop`, `ShowMountedServersOnDesktop`, `FinderSpawnTab`
(*Open folders in tabs instead of new windows*) — all bool, `com.apple.finder`.

## Gotchas

- **`-default-` ≠ off.** An unset key means Finder uses its built-in default,
  which for several of these (warnings, `SCev`) reads as *on/This-Mac* in the
  UI even though no key exists. The tool prints `-default-` so you can tell an
  explicit `0` from "never touched".
- **Always relaunch.** Changes are invisible until `killall Finder` — the tool
  does this automatically after any write.
- **Sidebar pane is NOT here.** Sidebar Favorites live in `com.apple.sidebarlists`
  / the `sfl2` store and are not plain booleans — see
  [`finder-sidebar-locked.md`](finder-sidebar-locked.md).

## Esa's preset (`finder-settings apply`)

`AppleShowAllExtensions=true` · `_FXSortFoldersFirst=true` · `FXDefaultSearchScope=SCcf`
(show extensions, keep folders on top in windows, search the current folder).
