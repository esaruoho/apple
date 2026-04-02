#!/usr/bin/env python3
"""
shortcut-gen.py — Generate signed .shortcut files from AppleScript workflow scripts.

Usage:
    python3 bin/shortcut-gen.py                      # Generate all shortcuts
    python3 bin/shortcut-gen.py finder                # Generate for one app
    python3 bin/shortcut-gen.py --install             # Generate + open for import
    python3 bin/shortcut-gen.py --install finder      # Generate + open for one app
    python3 bin/shortcut-gen.py --list                # List what would be generated
    python3 bin/shortcut-gen.py --phrases             # List Siri voice phrases
    python3 bin/shortcut-gen.py --setup               # Open Shortcuts Advanced prefs
    python3 bin/shortcut-gen.py --folder "My Folder"  # Set Shortcuts folder name

Prerequisites:
    Shortcuts.app → Settings → Advanced → Allow Running Scripts (one-time)

Output:
    shortcuts/<app>/<Shortcut-Name>.shortcut (signed, importable)

Each .shortcut wraps a workflow AppleScript in a "Run AppleScript" action.
Once imported, they're reachable via Siri, Spotlight, share sheet, and menu bar.

Pipeline: workflow-gen.py -> shortcut-gen.py -> Siri/Spotlight
"""

import plistlib
import subprocess
import sys
import os
from pathlib import Path

WORKFLOWS_DIR = Path(__file__).parent.parent / "scripts" / "workflows"
SHORTCUTS_DIR = Path(__file__).parent.parent / "shortcuts"

# Icon glyphs and colors for different app categories
# Glyph numbers from SF Symbols used by Shortcuts
APP_ICONS = {
    "finder":         {"glyph": 59493, "color": 463140863},   # blue, folder
    "music":          {"glyph": 59452, "color": 4292093695},   # pink, music note
    "mail":           {"glyph": 59422, "color": 431817727},    # blue, envelope
    "safari":         {"glyph": 59511, "color": 440166399},    # blue, compass
    "notes":          {"glyph": 59538, "color": 4294222079},   # yellow, note
    "reminders":      {"glyph": 59496, "color": 463140863},    # blue, checklist
    "calendar":       {"glyph": 59434, "color": 4282601983},   # red, calendar
    "photos":         {"glyph": 59470, "color": 4282601983},   # red, photo
    "messages":       {"glyph": 59428, "color": 1440546815},   # green, bubble
    "contacts":       {"glyph": 59438, "color": 3679049983},   # gray, person
    "terminal":       {"glyph": 59511, "color": 255},          # black, terminal
    "system-events":  {"glyph": 59458, "color": 3679049983},   # gray, gear
    "shortcuts":      {"glyph": 59511, "color": 4282601983},   # red, shortcuts
    "textedit":       {"glyph": 59538, "color": 3679049983},   # gray, doc
    "quicktime":      {"glyph": 59452, "color": 463140863},    # blue, play
    "homepod":        {"glyph": 59458, "color": 4292093695},   # pink, speaker
    "tv":             {"glyph": 59452, "color": 4292093695},   # pink, play
    "keynote":        {"glyph": 59511, "color": 463140863},    # blue, presentation
    "numbers":        {"glyph": 59496, "color": 1440546815},   # green, spreadsheet
    "pages":          {"glyph": 59538, "color": 463140863},    # blue, document
    "automator":      {"glyph": 59458, "color": 2071128063},   # purple, gear
    "script-editor":  {"glyph": 59511, "color": 255},          # gray, code
    "image-events":   {"glyph": 59470, "color": 4282601983},   # red, image
    "imovie":         {"glyph": 59452, "color": 2071128063},   # purple, film
    "system-information": {"glyph": 59458, "color": 3679049983}, # gray, info
    "preview":        {"glyph": 59470, "color": 463140863},    # blue, view
    "system-settings": {"glyph": 59458, "color": 3679049983},  # gray, gear
    "disk-utility":   {"glyph": 59458, "color": 3679049983},   # gray, disk
    "screenshot":     {"glyph": 59470, "color": 463140863},    # blue, camera
    "console":        {"glyph": 59511, "color": 255},          # black, terminal
    "time-machine":   {"glyph": 59434, "color": 1440546815},   # green, clock
    "accessibility":  {"glyph": 59458, "color": 463140863},    # blue, accessibility
    "hardware":       {"glyph": 59458, "color": 3679049983},   # gray, chip
}

DEFAULT_ICON = {"glyph": 59511, "color": 4282601983}


def read_applescript(script_path):
    """Read an AppleScript file, skip the header comments."""
    lines = script_path.read_text().split('\n')
    # Skip header lines (starting with --)
    code_lines = []
    past_header = False
    for line in lines:
        if not past_header and line.startswith('--'):
            continue
        if not past_header and line.strip() == '':
            continue
        past_header = True
        code_lines.append(line)
    return '\n'.join(code_lines).strip()


def get_description(script_path):
    """Get the description from the first line of the script."""
    first_line = script_path.read_text().split('\n')[0]
    if first_line.startswith('-- '):
        return first_line[3:]
    return script_path.stem


def siri_phrase_from_name(name):
    """Convert a Shortcut name to a natural Siri voice phrase.

    Follows Sal Soghoian's dictation command patterns:
    - Natural English sentences, not menu labels
    - Articles: "the", "a", "my" where humans would say them
    - Conversational verbs: "make" not "create", "show me" not "list"
    - Question forms for queries: "how many" not "count", "what's" not "get"
    - Deictic context: "this", "these" for selection-based actions
    - No app name residue in the phrase
    - Prepositions: "to", "from", "in" as natural joints

    Reference: dictationcommands.com (251 hand-crafted commands by Sal Soghoian)
    """
    # The stem is the script filename without extension, e.g. "finder-empty-trash"
    # The name arrives as Title Case: "Finder Empty Trash"
    # We key overrides on the lowercase-hyphenated stem for reliability.
    stem = name.replace(' ', '-').lower()

    if stem in PHRASE_OVERRIDES:
        return PHRASE_OVERRIDES[stem]

    # Fallback: strip app prefix, return action portion
    parts = name.split()
    if len(parts) < 2:
        return name
    app = parts[0].lower()
    action = ' '.join(parts[1:])
    if app == 'system' and len(parts) > 2 and parts[1].lower() == 'events':
        action = ' '.join(parts[2:])
    return action


# Hand-crafted Siri phrases following Sal Soghoian's dictation command patterns.
# Each phrase answers: "What would someone say out loud to make this happen?"
PHRASE_OVERRIDES = {
    # --- Accessibility (System Settings panes) ---
    'ax-system-settings-battery': 'open battery settings',
    'ax-system-settings-bluetooth': 'open Bluetooth settings',
    'ax-system-settings-displays': 'open display settings',
    'ax-system-settings-keyboard': 'open keyboard settings',
    'ax-system-settings-notifications': 'open notification settings',
    'ax-system-settings-privacy': 'open privacy settings',
    'ax-system-settings-sound': 'open sound settings',
    'ax-system-settings-wifi': 'open Wi-Fi settings',

    # --- Automator ---
    'automator-get-result': 'get the Automator result',
    'automator-list-actions': 'show me the Automator actions',
    'automator-new-workflow': 'make a new Automator workflow',
    'automator-run-workflow': 'run this workflow',
    'automator-save-as-app': 'save this workflow as an app',

    # --- Calendar ---
    'calendar-count-events-today': 'how many events are there today',
    'calendar-event-at-time': 'make an event at a time',
    'calendar-list-calendars': 'show me my calendars',
    'calendar-next-event': 'what is my next event',
    'calendar-quick-event': 'make a quick event',
    'calendar-reload': 'reload the calendar',
    'calendar-show-month': 'show the calendar for this month',
    'calendar-show-today': 'show the calendar for today',
    'calendar-show-week': 'show the calendar for this week',

    # --- Console ---
    'console-app-log': 'show the app log',
    'console-recent-errors': 'show me recent errors',
    'console-system-log': 'show the system log',

    # --- Contacts ---
    'contacts-count-contacts': 'how many contacts do I have',
    'contacts-list-groups': 'show me my contact groups',
    'contacts-new-contact': 'make a new contact',
    'contacts-search-contact': 'search my contacts',

    # --- Disk Utility ---
    'disk-utility-apfs-list': 'show me the APFS volumes',
    'disk-utility-disk-info': 'show me the disk info',
    'disk-utility-list-disks': 'show me all disks',

    # --- Finder ---
    'finder-airdrop-reveal': 'open AirDrop',
    'finder-close-all-windows': 'close all Finder windows',
    'finder-compress-selected': 'compress this',
    'finder-copy-path': 'copy the file path',
    'finder-count-items': 'how many items are in this folder',
    'finder-duplicate-selected': 'duplicate this',
    'finder-eject-all': 'eject all drives',
    'finder-empty-trash': 'empty the trash',
    'finder-empty-trash-confirm': 'empty the trash with confirmation',
    'finder-file-info': 'tell me about this file',
    'finder-get-selection': 'what is selected',
    'finder-get-window-path': 'where am I in Finder',
    'finder-hide-desktop-icons': 'hide the desktop icons',
    'finder-move-to-trash': 'move this to the trash',
    'finder-new-folder': 'make a new folder',
    'finder-new-window': 'open a new Finder window',
    'finder-new-window-desktop': 'open the Desktop folder',
    'finder-new-window-downloads': 'open the Downloads folder',
    'finder-open-current-dir': 'open the current directory in Finder',
    'finder-restart-finder': 'restart the Finder',
    'finder-reveal-downloads': 'show me the Downloads folder',
    'finder-set-wallpaper': 'change the wallpaper',
    'finder-show-desktop-icons': 'show the desktop icons',
    'finder-sort-by-name': 'sort by name',
    'finder-tag-clear': 'clear the tags',
    'finder-tag-orange': 'tag this orange',
    'finder-tag-red': 'tag this red',
    'finder-toggle-hidden-files': 'show hidden files',

    # --- Hardware ---
    'hardware-audio-devices': 'what audio devices are available',
    'hardware-battery-status': "what's the battery at",
    'hardware-bluetooth-devices': 'what Bluetooth devices are connected',
    'hardware-cpu-info': "how's the CPU doing",
    'hardware-disk-usage': 'how much disk space is left',
    'hardware-display-brightness': "what's the display brightness",
    'hardware-memory-pressure': "how's the memory",
    'hardware-usb-devices': 'what USB devices are connected',

    # --- HomePod ---
    'homepod-climate-dashboard': 'open the climate dashboard',
    'homepod-climate-log': 'show the climate log',
    'homepod-climate-reading': "what's the temperature",
    'homepod-climate-summary': 'give me the climate summary',
    'homepod-good-morning-scene': 'good morning',
    'homepod-good-night-scene': 'good night',
    'homepod-lights-off': 'turn the lights off',
    'homepod-lights-on': 'turn the lights on',
    'homepod-pause-music': 'pause the music on HomePod',
    'homepod-play-music': 'play music on HomePod',
    'homepod-set-volume': 'set the HomePod volume',

    # --- Image Events ---
    'image-events-convert-format': 'convert the image format',
    'image-events-flip': 'flip this image',
    'image-events-get-dimensions': 'what are the image dimensions',
    'image-events-resize': 'resize this image',
    'image-events-rotate': 'rotate this image',

    # --- iMovie ---
    'imovie-list-projects': 'show me my iMovie projects',
    'imovie-new-project': 'make a new iMovie project',

    # --- Keynote ---
    'keynote-current-slide': 'what slide is this',
    'keynote-export-pdf': 'export this presentation as a PDF',
    'keynote-list-slides': 'show me all the slides',
    'keynote-new-presentation': 'make a new presentation',
    'keynote-next-slide': 'next slide',
    'keynote-presenter-notes': 'read the presenter notes',
    'keynote-previous-slide': 'previous slide',
    'keynote-slide-count': 'how many slides are there',
    'keynote-start-slideshow': 'start the slideshow',
    'keynote-stop-slideshow': 'stop the slideshow',

    # --- Mail ---
    'mail-archive-selected': 'archive this email',
    'mail-check-mail': 'check my mail',
    'mail-compose': 'make a new email',
    'mail-compose-to': 'compose an email to someone',
    'mail-delete-junk': 'delete the junk mail',
    'mail-flag-selected': 'flag this email',
    'mail-forward-selected': 'forward this email',
    'mail-list-accounts': 'show me my mail accounts',
    'mail-mark-all-read': 'mark all as read',
    'mail-read-latest-subject': 'read the latest subject line',
    'mail-reply-to-selected': 'reply to this email',
    'mail-send-quick': 'send a quick email',
    'mail-unread-count': 'how many unread emails do I have',

    # --- Messages ---
    'messages-list-chats': 'show me my chats',
    'messages-send-clipboard': 'send the clipboard as a message',
    'messages-send-message': 'send a message',

    # --- Music ---
    'music-add-to-playlist': 'add this to a playlist',
    'music-airplay-list': 'show me the AirPlay devices',
    'music-count-library': 'how many songs are in my library',
    'music-create-playlist': 'make a new playlist',
    'music-current-stream-info': "what's streaming right now",
    'music-dislike-current': 'dislike this song',
    'music-get-lyrics': 'show me the lyrics',
    'music-list-playlists': 'show me my playlists',
    'music-love-current': 'love this song',
    'music-mute-toggle': 'mute the music',
    'music-next-track': 'next track',
    'music-now-playing': "what's playing",
    'music-now-playing-clipboard': 'copy what is playing to the clipboard',
    'music-play-playlist': 'play a playlist',
    'music-played-count-current': 'how many times have I played this',
    'music-playpause': 'play or pause the music',
    'music-previous-track': 'previous track',
    'music-rating-0-stars': 'remove the rating',
    'music-rating-1-star': 'rate this one star',
    'music-rating-2-stars': 'rate this two stars',
    'music-rating-3-stars': 'rate this three stars',
    'music-rating-4-stars': 'rate this four stars',
    'music-rating-5-stars': 'rate this five stars',
    'music-reveal-current': 'show this song in the library',
    'music-search-library': 'search my music library',
    'music-seek-backward-30': 'skip back thirty seconds',
    'music-seek-forward-30': 'skip forward thirty seconds',
    'music-set-eq-preset': 'set the equalizer preset',
    'music-stop': 'stop the music',
    'music-toggle-eq': 'turn the equalizer on',
    'music-toggle-fullscreen': 'go fullscreen',
    'music-toggle-repeat': 'turn repeat on',
    'music-toggle-shuffle': 'turn shuffle on',
    'music-toggle-visuals': 'turn the visuals on',
    'music-track-info-detail': 'tell me about this track',
    'music-volume-down': 'turn the volume down',
    'music-volume-up': 'turn the volume up',

    # --- Notes ---
    'notes-append-to-note': 'add to a note',
    'notes-count-notes': 'how many notes do I have',
    'notes-list-folders': 'show me my note folders',
    'notes-list-notes': 'show me my notes',
    'notes-new-note': 'make a new note',
    'notes-new-note-from-clipboard': 'make a new note from the clipboard',
    'notes-search-notes': 'search my notes',
    'notes-show-recent-note': 'show me the latest note',

    # --- Numbers ---
    'numbers-export-csv': 'export this as CSV',
    'numbers-export-pdf': 'export this spreadsheet as a PDF',
    'numbers-list-sheets': 'show me all the sheets',
    'numbers-new-spreadsheet': 'make a new spreadsheet',
    'numbers-sheet-count': 'how many sheets are there',
    'numbers-table-count': 'how many tables are there',

    # --- Pages ---
    'pages-character-count': 'how many characters are there',
    'pages-export-pdf': 'export this document as a PDF',
    'pages-list-documents': 'show me my Pages documents',
    'pages-new-document': 'make a new document',
    'pages-page-count': 'how many pages is this',
    'pages-word-count': 'how many words is this',

    # --- Photos ---
    'photos-count-photos': 'how many photos do I have',
    'photos-create-album': 'make a new album',
    'photos-export-selected': 'export these photos',
    'photos-favorite-selected': 'add this to favorites',
    'photos-favorites-count': 'how many favorites do I have',
    'photos-list-albums': 'show me my albums',
    'photos-search': 'search my photos',
    'photos-start-slideshow': 'start a slideshow',
    'photos-stop-slideshow': 'stop the slideshow',

    # --- Preview ---
    'preview-open-file': 'open a file in Preview',
    'preview-rotate-left': 'rotate this to the left',
    'preview-zoom-in': 'zoom in',
    'preview-zoom-out': 'zoom out',

    # --- QuickTime ---
    'quicktime-new-audio-recording': 'make a new audio recording',
    'quicktime-new-movie-recording': 'make a new movie recording',
    'quicktime-new-screen-recording': 'make a new screen recording',
    'quicktime-pause-frontmost': 'pause the recording',
    'quicktime-play-frontmost': 'play this from the beginning',
    'quicktime-present-fullscreen': 'present this fullscreen',

    # --- Reminders ---
    'reminders-complete-latest': 'complete the latest reminder',
    'reminders-count-incomplete': 'how many reminders are left',
    'reminders-flagged-reminders': 'show me the flagged reminders',
    'reminders-list-lists': 'show me my reminder lists',
    'reminders-quick-reminder': 'make a quick reminder',
    'reminders-reminder-due-today': 'what reminders are due today',
    'reminders-reminder-from-clipboard': 'make a reminder from the clipboard',
    'reminders-reminder-with-priority': 'make a reminder with priority',
    'reminders-show-today': "show me today's reminders",

    # --- Safari ---
    'safari-add-reading-list': 'add this to my reading list',
    'safari-close-all-tabs': 'close all the tabs',
    'safari-close-other-tabs': 'close the other tabs',
    'safari-current-title': 'what is the title of this page',
    'safari-current-url': "what's the URL",
    'safari-current-url-and-title': "what's the URL and title",
    'safari-do-javascript': 'run JavaScript on this page',
    'safari-list-all-tabs': 'show me all my tabs',
    'safari-open-url': 'open a URL',
    'safari-page-source': 'show me the page source',
    'safari-reload-tab': 'reload this page',
    'safari-search-web': 'search the web',
    'safari-show-bookmarks': 'show me my bookmarks',
    'safari-show-privacy-report': 'show the privacy report',
    'safari-tab-count': 'how many tabs are open',

    # --- Screenshot ---
    'screenshot-area': 'take a screenshot of an area',
    'screenshot-clipboard': 'take a screenshot to the clipboard',
    'screenshot-fullscreen': 'take a screenshot of the screen',
    'screenshot-window': 'take a screenshot of a window',

    # --- Script Editor ---
    'script-editor-compile': 'compile this script',
    'script-editor-get-result': 'get the script result',
    'script-editor-new-script': 'make a new script',
    'script-editor-open-dictionary': 'open the scripting dictionary',
    'script-editor-run': 'run this script',

    # --- Shortcuts ---
    'shortcuts-list-shortcuts': 'show me my shortcuts',
    'shortcuts-run-shortcut': 'run a shortcut',
    'shortcuts-run-shortcut-with-input': 'run a shortcut with input',
    'shortcuts-search-shortcuts': 'search my shortcuts',

    # --- System Events ---
    'system-events-hideallothers': 'hide the other apps',
    'system-events-mosaicknob': 'tile windows with the knob',
    'system-events-mosaicwindows': 'tile all the windows',
    'system-events-whiteboardbrowse': 'browse the whiteboards',
    'system-events-whiteboardknob': 'browse whiteboards with the knob',
    'system-events-whiteboardnext': 'next whiteboard',
    'system-events-whiteboardopen': 'open this whiteboard',
    'system-events-whiteboardprev': 'previous whiteboard',
    'system-events-battery-status': "what's the battery at",
    'system-events-bluetooth-toggle': 'turn Bluetooth on',
    'system-events-dark-mode-toggle': 'turn dark mode on',
    'system-events-disk-usage': 'how much disk space is left',
    'system-events-do-not-disturb': 'turn on do not disturb',
    'system-events-dock-add-recent-apps': 'add recent apps to the Dock',
    'system-events-dock-add-spacer': 'add a spacer to the Dock',
    'system-events-empty-clipboard': 'clear the clipboard',
    'system-events-get-frontmost-app': 'what app is this',
    'system-events-hide-dock': 'hide the Dock',
    'system-events-ip-address': "what's my IP address",
    'system-events-key-shortcut': 'press a keyboard shortcut',
    'system-events-list-running-apps': 'what apps are running',
    'system-events-notification-count': 'how many notifications are there',
    'system-events-reset-apple-events': 'reset the Apple Events permissions',
    'system-events-restart-menu-bar': 'restart the menu bar',
    'system-events-screen-lock': 'lock the screen',
    'system-events-screenshot-area': 'take a screenshot of an area',
    'system-events-screenshot-window': 'take a screenshot of a window',
    'system-events-show-dock': 'show the Dock',
    'system-events-spotlight-status': 'is Spotlight working',
    'system-events-trash-size': 'how big is the trash',
    'system-events-type-text': 'type some text',
    'system-events-uptime': 'how long has the computer been on',
    'system-events-volume-set': 'set the volume',
    'system-events-wifi-toggle': 'turn Wi-Fi on',

    # --- System Information ---
    'system-information-hardware': 'show me the hardware info',
    'system-information-network': 'show me the network info',
    'system-information-software': 'show me the software info',
    'system-information-storage': 'show me the storage info',

    # --- System Settings ---
    'system-settings-battery': 'open battery settings',
    'system-settings-bluetooth': 'open Bluetooth settings',
    'system-settings-displays': 'open display settings',
    'system-settings-general': 'open general settings',
    'system-settings-notifications': 'open notification settings',
    'system-settings-privacy': 'open privacy settings',
    'system-settings-sound': 'open sound settings',
    'system-settings-wifi': 'open Wi-Fi settings',

    # --- Terminal ---
    'terminal-clear-scrollback': 'clear the terminal',
    'terminal-new-tab': 'open a new terminal tab',
    'terminal-new-tab-at-path': 'open a new terminal tab here',
    'terminal-run-command': 'run a command in Terminal',
    'terminal-set-title': 'set the terminal title',
    'terminal-ssh-connect': 'connect to a server',

    # --- TextEdit ---
    'textedit-char-count': 'how many characters are in this',
    'textedit-new-document': 'make a new text document',
    'textedit-new-from-clipboard': 'make a new document from the clipboard',
    'textedit-save-as-txt': 'save this as plain text',
    'textedit-word-count': 'how many words are in this',

    # --- Time Machine ---
    'time-machine-latest-backup': 'when was the last backup',
    'time-machine-list-backups': 'show me all the backups',
    'time-machine-start-backup': 'start a backup',
    'time-machine-status': "what's the backup status",

    # --- TV ---
    'tv-list-playlists': 'show me my TV playlists',
    'tv-mute-toggle': 'mute the TV',
    'tv-next-track': 'next episode',
    'tv-now-playing': "what's playing on TV",
    'tv-playpause': 'play or pause the TV',
    'tv-previous-track': 'previous episode',
    'tv-reveal-current': 'show this in the library',
    'tv-search-library': 'search the TV library',
    'tv-volume-down': 'turn the TV volume down',
    'tv-volume-up': 'turn the TV volume up',
}


def build_shortcut_plist(name, applescript_code, icon_config):
    """Build a .shortcut plist with native Run AppleScript action.

    Uses is.workflow.actions.runapplescript — the native AppleScript action
    in Shortcuts. Requires 'Allow Running Scripts' in Shortcuts > Advanced.
    """
    return {
        'WFWorkflowActions': [
            {
                'WFWorkflowActionIdentifier': 'is.workflow.actions.runapplescript',
                'WFWorkflowActionParameters': {
                    'Script': applescript_code,
                },
            }
        ],
        'WFWorkflowClientVersion': '2612.0.4',
        'WFWorkflowHasOutputFallback': False,
        'WFWorkflowHasShortcutInputVariables': False,
        'WFWorkflowIcon': {
            'WFWorkflowIconGlyphNumber': icon_config.get('glyph', 59511),
            'WFWorkflowIconStartColor': icon_config.get('color', 4282601983),
        },
        'WFWorkflowImportQuestions': [],
        'WFWorkflowInputContentItemClasses': [
            'WFStringContentItem',
        ],
        'WFWorkflowMinimumClientVersion': 900,
        'WFWorkflowMinimumClientVersionString': '900',
        'WFWorkflowOutputContentItemClasses': [],
        'WFWorkflowTypes': [],
    }


def sign_shortcut(unsigned_path, signed_path):
    """Sign a .shortcut file using the shortcuts CLI."""
    result = subprocess.run(
        ['shortcuts', 'sign', '--mode', 'anyone',
         '--input', str(unsigned_path), '--output', str(signed_path)],
        capture_output=True, text=True
    )
    return result.returncode == 0


def shortcut_name_from_script(script_path):
    """Convert script filename to a nice Shortcut name.
    finder-copy-path.applescript -> Finder Copy Path
    """
    stem = script_path.stem  # e.g., "finder-copy-path"
    return stem.replace('-', ' ').title()


def main():
    args = sys.argv[1:]

    install = '--install' in args
    args = [a for a in args if a != '--install']

    folder_name = 'Apple Workflows'
    if '--folder' in args:
        idx = args.index('--folder')
        if idx + 1 < len(args):
            folder_name = args[idx + 1]
            args = args[:idx] + args[idx+2:]

    if '--setup' in args:
        print("Opening Shortcuts Advanced preferences...")
        print("Check 'Allow Running Scripts' to enable script execution.")
        subprocess.run(['open', '-b', 'com.apple.shortcuts'])
        import time
        time.sleep(1)
        subprocess.run(['osascript', '-e',
            'tell application "System Events" to tell process "Shortcuts" to keystroke "," using command down'])
        # Click "Advanced" tab
        time.sleep(0.5)
        subprocess.run(['osascript', '-e', '''
            tell application "System Events"
                tell process "Shortcuts"
                    try
                        click button "Advanced" of toolbar 1 of window 1
                    end try
                end tell
            end tell
        '''])
        return

    if '--list' in args:
        print("Shortcuts that would be generated:\n")
        for app_dir in sorted(WORKFLOWS_DIR.iterdir()):
            if not app_dir.is_dir():
                continue
            scripts = sorted(app_dir.glob("*.applescript"))
            if scripts:
                app_display = app_dir.name.replace('-', ' ').title()
                print(f"  {app_display}:")
                for s in scripts:
                    print(f"    {shortcut_name_from_script(s)}")
        return

    if '--phrases' in args:
        print("Siri voice phrases (dictation commands):\n")
        for app_dir in sorted(WORKFLOWS_DIR.iterdir()):
            if not app_dir.is_dir():
                continue
            scripts = sorted(app_dir.glob("*.applescript"))
            if scripts:
                app_display = app_dir.name.replace('-', ' ').title()
                print(f"  {app_display}:")
                for s in scripts:
                    name = shortcut_name_from_script(s)
                    phrase = siri_phrase_from_name(name)
                    print(f'    "Hey Siri, {phrase}"')
        return

    # Filter apps
    filter_apps = [a.lower().replace(' ', '-') for a in args]

    SHORTCUTS_DIR.mkdir(parents=True, exist_ok=True)

    print("═══ Shortcut Generator ═══")
    print(f"Source:    {WORKFLOWS_DIR}")
    print(f"Output:    {SHORTCUTS_DIR}")
    if install:
        print(f"Mode:      Generate + Install")
    print()

    total = 0
    errors = 0
    generated_files = []

    for app_dir in sorted(WORKFLOWS_DIR.iterdir()):
        if not app_dir.is_dir():
            continue
        app_slug = app_dir.name

        if filter_apps and app_slug not in filter_apps:
            continue

        app_display = app_slug.replace('-', ' ').title()
        icon_config = APP_ICONS.get(app_slug, DEFAULT_ICON)

        out_dir = SHORTCUTS_DIR / app_slug
        out_dir.mkdir(parents=True, exist_ok=True)

        print(f"  {app_display}:")

        for script_path in sorted(app_dir.glob("*.applescript")):
            name = shortcut_name_from_script(script_path)
            code = read_applescript(script_path)
            desc = get_description(script_path)

            # Build plist
            plist_data = build_shortcut_plist(name, code, icon_config)

            # Write unsigned
            unsigned = out_dir / f"{script_path.stem}.unsigned.shortcut"
            with open(unsigned, 'wb') as f:
                plistlib.dump(plist_data, f, fmt=plistlib.FMT_BINARY)

            # Sign
            signed = out_dir / f"{script_path.stem}.shortcut"
            if sign_shortcut(unsigned, signed):
                unsigned.unlink()  # Clean up unsigned
                print(f"    {name}")
                generated_files.append(signed)
                total += 1
            else:
                print(f"    {name} [SIGN ERROR]")
                unsigned.unlink(missing_ok=True)
                errors += 1

    print(f"\n  Generated: {total} shortcuts ({errors} errors)")

    if install and generated_files:
        print(f"\n  Opening {len(generated_files)} shortcuts for import...")
        print(f"  You'll need to tap 'Add Shortcut' for each one.")
        print(f"  Tip: Move them to folder '{folder_name}' after import.")
        print()
        for f in generated_files:
            subprocess.run(['open', str(f)])
            # Small delay to not overwhelm the UI
            import time
            time.sleep(0.5)

    print(f"\n═══ Done: {total} shortcuts across {len(list(SHORTCUTS_DIR.iterdir()))} apps ═══")
    if not install:
        print(f"Run with --install to open for import into Shortcuts app.")
    print(f"\n  IMPORTANT: Enable 'Allow Running Scripts' in Shortcuts:")
    print(f"  Shortcuts.app → Settings → Advanced → Allow Running Scripts")


if __name__ == '__main__':
    main()
