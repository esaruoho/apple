#!/usr/bin/env python3
"""
app-probe.py — Extract ALL automation knowledge from every Apple app.

Harvests 13 layers of automation intelligence from macOS app bundles:
  1. Scripting Dictionary (sdef)      7. Entitlements (codesign)
  2. URL Schemes (Info.plist)          8. Linked Frameworks (otool)
  3. Document Types (Info.plist)       9. Spotlight Metadata (mdls)
  4. App Intents / Siri Phrases       10. LaunchServices (lsregister)
  5. NSServices (Info.plist)           11. Plugin Extensions (.appex)
  6. User Activity Types (Info.plist)  12. Notification Actions (Info.plist)
                                       13. CLI Tools (/usr/bin)

Usage:
    python3 bin/app-probe.py                    # All apps, all layers
    python3 bin/app-probe.py Mail               # Single app
    python3 bin/app-probe.py --layer intents    # Only App Intents layer
    python3 bin/app-probe.py --layer url        # Only URL schemes
    python3 bin/app-probe.py --cli              # Include CLI tools (layer 13)
    python3 bin/app-probe.py --list             # Show available apps
    python3 bin/app-probe.py --ls               # Include LaunchServices (slow)

Output:
    dictionaries/<app>/
        <app>-probe.yaml       # Machine-readable: all 13 layers
        <app>-probe.md         # Human-readable: automation reference
    dictionaries/_probe-index.yaml  # Cross-app capabilities map

Zero external dependencies — stdlib only.
Inspired by Sal Soghoian's credo: "The power of the computer should reside
in the hands of the one using it."
"""

import subprocess
import sys
import os
import json
import re
import plistlib
import xml.etree.ElementTree as ET
from pathlib import Path

# ─── Unified App Registry ─────────────────────────────────────────────────────
# Superset of sdef-extract.py (31 apps) + extract-icons.sh (64 apps) + extras
# Format: { "Display Name": { "path": "/path/to/App.app", "category": "..." } }

APP_REGISTRY = {
    # ── System Apps ──
    "App Store":        {"path": "/System/Applications/App Store.app", "category": "system"},
    "Automator":        {"path": "/System/Applications/Automator.app", "category": "system"},
    "Books":            {"path": "/System/Applications/Books.app", "category": "system"},
    "Calculator":       {"path": "/System/Applications/Calculator.app", "category": "system"},
    "Calendar":         {"path": "/System/Applications/Calendar.app", "category": "system"},
    "Chess":            {"path": "/System/Applications/Chess.app", "category": "system"},
    "Clock":            {"path": "/System/Applications/Clock.app", "category": "system"},
    "Contacts":         {"path": "/System/Applications/Contacts.app", "category": "system"},
    "Dictionary":       {"path": "/System/Applications/Dictionary.app", "category": "system"},
    "FaceTime":         {"path": "/System/Applications/FaceTime.app", "category": "system"},
    "Find My":          {"path": "/System/Applications/FindMy.app", "category": "system"},
    "Font Book":        {"path": "/System/Applications/Font Book.app", "category": "system"},
    "Freeform":         {"path": "/System/Applications/Freeform.app", "category": "system"},
    "Home":             {"path": "/System/Applications/Home.app", "category": "system"},
    "Image Capture":    {"path": "/System/Applications/Image Capture.app", "category": "system"},
    "Launchpad":        {"path": "/System/Applications/Launchpad.app", "category": "system"},
    "Mail":             {"path": "/System/Applications/Mail.app", "category": "system"},
    "Maps":             {"path": "/System/Applications/Maps.app", "category": "system"},
    "Messages":         {"path": "/System/Applications/Messages.app", "category": "system"},
    "Mission Control":  {"path": "/System/Applications/Mission Control.app", "category": "system"},
    "Music":            {"path": "/System/Applications/Music.app", "category": "system"},
    "News":             {"path": "/System/Applications/News.app", "category": "system"},
    "Notes":            {"path": "/System/Applications/Notes.app", "category": "system"},
    "Passwords":        {"path": "/System/Applications/Passwords.app", "category": "system"},
    "Photo Booth":      {"path": "/System/Applications/Photo Booth.app", "category": "system"},
    "Photos":           {"path": "/System/Applications/Photos.app", "category": "system"},
    "Podcasts":         {"path": "/System/Applications/Podcasts.app", "category": "system"},
    "Preview":          {"path": "/System/Applications/Preview.app", "category": "system"},
    "QuickTime Player": {"path": "/System/Applications/QuickTime Player.app", "category": "system"},
    "Reminders":        {"path": "/System/Applications/Reminders.app", "category": "system"},
    "Shortcuts":        {"path": "/System/Applications/Shortcuts.app", "category": "system"},
    "Stickies":         {"path": "/System/Applications/Stickies.app", "category": "system"},
    "Stocks":           {"path": "/System/Applications/Stocks.app", "category": "system"},
    "System Settings":  {"path": "/System/Applications/System Settings.app", "category": "system"},
    "TextEdit":         {"path": "/System/Applications/TextEdit.app", "category": "system"},
    "Time Machine":     {"path": "/System/Applications/Time Machine.app", "category": "system"},
    "Tips":             {"path": "/System/Applications/Tips.app", "category": "system"},
    "TV":               {"path": "/System/Applications/TV.app", "category": "system"},
    "Voice Memos":      {"path": "/System/Applications/VoiceMemos.app", "category": "system"},
    "Weather":          {"path": "/System/Applications/Weather.app", "category": "system"},
    # ── Utilities ──
    "Activity Monitor":          {"path": "/System/Applications/Utilities/Activity Monitor.app", "category": "utility"},
    "AirPort Utility":           {"path": "/System/Applications/Utilities/AirPort Utility.app", "category": "utility"},
    "Audio MIDI Setup":          {"path": "/System/Applications/Utilities/Audio MIDI Setup.app", "category": "utility"},
    "Bluetooth File Exchange":   {"path": "/System/Applications/Utilities/Bluetooth File Exchange.app", "category": "utility"},
    "ColorSync Utility":         {"path": "/System/Applications/Utilities/ColorSync Utility.app", "category": "utility"},
    "Console":                   {"path": "/System/Applications/Utilities/Console.app", "category": "utility"},
    "Digital Color Meter":       {"path": "/System/Applications/Utilities/Digital Color Meter.app", "category": "utility"},
    "Disk Utility":              {"path": "/System/Applications/Utilities/Disk Utility.app", "category": "utility"},
    "Grapher":                   {"path": "/System/Applications/Utilities/Grapher.app", "category": "utility"},
    "Migration Assistant":       {"path": "/System/Applications/Utilities/Migration Assistant.app", "category": "utility"},
    "Screen Sharing":            {"path": "/System/Applications/Utilities/Screen Sharing.app", "category": "utility"},
    "Screenshot":                {"path": "/System/Applications/Utilities/Screenshot.app", "category": "utility"},
    "Script Editor":             {"path": "/System/Applications/Utilities/Script Editor.app", "category": "utility"},
    "System Information":        {"path": "/System/Applications/Utilities/System Information.app", "category": "utility"},
    "Terminal":                  {"path": "/System/Applications/Utilities/Terminal.app", "category": "utility"},
    "VoiceOver Utility":         {"path": "/System/Applications/Utilities/VoiceOver Utility.app", "category": "utility"},
    # ── CoreServices (hidden powerhouses) ──
    "Finder":           {"path": "/System/Library/CoreServices/Finder.app", "category": "core"},
    "System Events":    {"path": "/System/Library/CoreServices/System Events.app", "category": "core"},
    "Image Events":     {"path": "/System/Library/CoreServices/Image Events.app", "category": "core"},
    # ── Pro Apps + Third-Party Apple ──
    "Safari":           {"path": "/Applications/Safari.app", "category": "pro"},
    "Keynote":          {"path": "/Applications/Keynote.app", "category": "pro"},
    "Numbers":          {"path": "/Applications/Numbers.app", "category": "pro"},
    "Pages":            {"path": "/Applications/Pages.app", "category": "pro"},
    "Final Cut Pro":    {"path": "/Applications/Final Cut Pro.app", "category": "pro"},
    "Logic Pro":        {"path": "/Applications/Logic Pro.app", "category": "pro"},
    "iMovie":           {"path": "/Applications/iMovie.app", "category": "pro"},
}

OUTPUT_DIR = Path(__file__).parent.parent / "dictionaries"

# ─── Helpers ──────────────────────────────────────────────────────────────────

def slug(name):
    """Convert app name to filesystem slug."""
    return name.lower().replace(' ', '-')


def yaml_escape(s):
    """Escape a string for YAML output."""
    if not isinstance(s, str):
        s = str(s)
    if any(c in s for c in (':', '#', '"', "'", '\n', '{', '}', '[', ']', ',', '&', '*', '!', '|', '>', '%', '@', '`')):
        return '"' + s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'
    if not s:
        return '""'
    return s


def load_info_plist(app_path):
    """Load and cache Info.plist from an app bundle."""
    plist_path = os.path.join(app_path, "Contents", "Info.plist")
    if not os.path.exists(plist_path):
        return None
    try:
        with open(plist_path, 'rb') as f:
            return plistlib.load(f)
    except Exception:
        return None


# ─── Layer 1: Scripting Dictionary ────────────────────────────────────────────

def extract_sdef(app_path):
    """Extract sdef scripting dictionary summary."""
    try:
        result = subprocess.run(
            ["sdef", app_path],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode != 0 or not result.stdout.strip():
            return None

        root = ET.fromstring(result.stdout)
        commands = root.findall('.//command')
        classes = [c for c in root.findall('.//class') if c.get('hidden') != 'yes']
        suites = root.findall('.//suite')

        return {
            "has_sdef": True,
            "suites": len(suites),
            "commands": len(commands),
            "classes": len(classes),
            "command_names": [c.get('name', '') for c in commands],
            "class_names": [c.get('name', '') for c in classes],
            "suite_names": [s.get('name', '') for s in suites],
        }
    except Exception:
        return None


# ─── Layer 2: URL Schemes ────────────────────────────────────────────────────

def extract_url_schemes(app_path, plist=None):
    """Extract URL schemes from Info.plist."""
    if plist is None:
        plist = load_info_plist(app_path)
    if not plist:
        return None

    url_types = plist.get('CFBundleURLTypes', [])
    if not url_types:
        return None

    schemes = []
    for ut in url_types:
        name = ut.get('CFBundleURLName', '')
        for scheme in ut.get('CFBundleURLSchemes', []):
            schemes.append({
                "scheme": scheme,
                "name": name,
                "is_default": ut.get('LSIsAppleDefaultForScheme', False),
            })

    return {"url_schemes": schemes} if schemes else None


# ─── Layer 3: Document Types ─────────────────────────────────────────────────

def extract_document_types(app_path, plist=None):
    """Extract supported document types from Info.plist."""
    if plist is None:
        plist = load_info_plist(app_path)
    if not plist:
        return None

    doc_types = plist.get('CFBundleDocumentTypes', [])
    if not doc_types:
        return None

    types = []
    for dt in doc_types:
        entry = {}
        if dt.get('CFBundleTypeName'):
            entry['name'] = dt['CFBundleTypeName']
        exts = dt.get('CFBundleTypeExtensions', [])
        if exts:
            entry['extensions'] = exts
        mime = dt.get('CFBundleTypeMIMETypes', [])
        if mime:
            entry['mime_types'] = mime
        role = dt.get('CFBundleTypeRole', '')
        if role:
            entry['role'] = role
        utis = dt.get('LSItemContentTypes', [])
        if utis:
            entry['content_types'] = utis
        if entry:
            types.append(entry)

    return {"document_types": types} if types else None


# ─── Layer 4: App Intents / Siri Phrases ─────────────────────────────────────

def extract_app_intents(app_path):
    """Extract App Intents metadata (Siri phrases, Shortcuts actions)."""
    # Search for extract.actionsdata in the app bundle
    actionsdata_path = None
    for root_dir, dirs, files in os.walk(app_path):
        if 'extract.actionsdata' in files:
            actionsdata_path = os.path.join(root_dir, 'extract.actionsdata')
            break
        # Don't recurse too deep
        depth = root_dir.replace(app_path, '').count(os.sep)
        if depth > 4:
            dirs.clear()

    if not actionsdata_path:
        return None

    try:
        with open(actionsdata_path, 'r') as f:
            data = json.load(f)
    except Exception:
        return None

    result = {}

    # Siri phrase templates
    intents = data.get('assistantIntents', [])
    if intents:
        phrases = []
        for intent in intents:
            templates = intent.get('phraseTemplates', [])
            for t in templates:
                key = t.get('key', '')
                if key:
                    phrases.append(key)
        if phrases:
            result['siri_phrases'] = phrases

    # Actions (Shortcuts actions)
    actions = data.get('actions', {})
    if actions:
        action_list = []
        # Handle both dict and list formats
        if isinstance(actions, list):
            items = [(str(i), a) for i, a in enumerate(actions) if isinstance(a, dict)]
        else:
            items = actions.items()
        for action_id, action_data in items:
            entry = {"id": action_id}
            title = action_data.get('title', {})
            if isinstance(title, dict) and title.get('key'):
                entry['title'] = title['key']
            desc = action_data.get('descriptionMetadata', {})
            if isinstance(desc, dict):
                summary = desc.get('descriptionText', {})
                if isinstance(summary, dict) and summary.get('key'):
                    entry['description'] = summary['key']
            # Parameters
            params = action_data.get('parameters', {})
            if isinstance(params, dict) and params:
                param_names = []
                for pid, pdata in params.items():
                    if isinstance(pdata, dict):
                        ptitle = pdata.get('title', {})
                        if isinstance(ptitle, dict) and ptitle.get('key'):
                            param_names.append(ptitle['key'])
                        else:
                            param_names.append(pid)
                    else:
                        param_names.append(pid)
                if param_names:
                    entry['parameters'] = param_names
            action_list.append(entry)
        if action_list:
            result['actions'] = action_list

    # Queries
    queries = data.get('queries', {})
    if queries:
        query_list = []
        if isinstance(queries, list):
            q_items = [(str(i), q) for i, q in enumerate(queries) if isinstance(q, dict)]
        else:
            q_items = queries.items()
        for qid, qdata in q_items:
            entry = {"id": qid}
            title = qdata.get('title', {}) if isinstance(qdata, dict) else {}
            if isinstance(title, dict) and title.get('key'):
                entry['title'] = title['key']
            query_list.append(entry)
        if query_list:
            result['queries'] = query_list

    # Entities
    entities = data.get('entities', {})
    if entities:
        if isinstance(entities, dict):
            result['entity_names'] = list(entities.keys())
        elif isinstance(entities, list):
            result['entity_names'] = [e.get('name', str(e)) if isinstance(e, dict) else str(e) for e in entities]

    # Enums
    enums = data.get('enums', {})
    if enums:
        if isinstance(enums, dict):
            result['enum_names'] = list(enums.keys())
        elif isinstance(enums, list):
            result['enum_names'] = [e.get('name', str(e)) if isinstance(e, dict) else str(e) for e in enums]

    # Auto Shortcuts
    auto_shortcuts = data.get('autoShortcuts', [])
    if auto_shortcuts:
        result['auto_shortcuts_count'] = len(auto_shortcuts)

    return result if result else None


# ─── Layer 5: NSServices ─────────────────────────────────────────────────────

def extract_services(app_path, plist=None):
    """Extract Services menu entries from Info.plist."""
    if plist is None:
        plist = load_info_plist(app_path)
    if not plist:
        return None

    services = plist.get('NSServices', [])
    if not services:
        return None

    entries = []
    for svc in services:
        entry = {}
        menu = svc.get('NSMenuItem', {})
        if isinstance(menu, dict):
            entry['menu_item'] = menu.get('default', '')
        entry['message'] = svc.get('NSMessage', '')
        entry['port'] = svc.get('NSPortName', '')
        send = svc.get('NSSendTypes', [])
        if send:
            entry['send_types'] = send
        ret = svc.get('NSReturnTypes', [])
        if ret:
            entry['return_types'] = ret
        entries.append(entry)

    return {"services": entries} if entries else None


# ─── Layer 6: User Activity Types ────────────────────────────────────────────

def extract_activity_types(app_path, plist=None):
    """Extract NSUserActivityTypes from Info.plist."""
    if plist is None:
        plist = load_info_plist(app_path)
    if not plist:
        return None

    activities = plist.get('NSUserActivityTypes', [])
    return {"activity_types": activities} if activities else None


# ─── Layer 7: Entitlements ────────────────────────────────────────────────────

def extract_entitlements(app_path):
    """Extract app entitlements via codesign."""
    try:
        result = subprocess.run(
            ["codesign", "-d", "--entitlements", ":-", app_path],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode != 0 or not result.stdout.strip():
            return None

        # Parse XML plist
        root = ET.fromstring(result.stdout)
        # Extract key names from the top-level dict
        keys = []
        dict_elem = root.find('.//dict')
        if dict_elem is not None:
            for key_elem in dict_elem.findall('key'):
                keys.append(key_elem.text)

        if not keys:
            return None

        # Categorize entitlements
        categories = {
            "sandbox": [],
            "network": [],
            "icloud": [],
            "privacy": [],
            "apple_intelligence": [],
            "other": [],
        }
        for k in keys:
            if 'sandbox' in k or 'security' in k:
                categories['sandbox'].append(k)
            elif 'network' in k or 'dns' in k:
                categories['network'].append(k)
            elif 'icloud' in k or 'ubiquity' in k or 'CloudKit' in k:
                categories['icloud'].append(k)
            elif 'tcc' in k.lower() or 'privacy' in k or 'personal-information' in k or 'addressbook' in k.lower():
                categories['privacy'].append(k)
            elif 'intelligence' in k.lower() or 'summarization' in k.lower() or 'generative' in k.lower() or 'modelmanager' in k.lower():
                categories['apple_intelligence'].append(k)
            else:
                categories['other'].append(k)

        # Remove empty categories
        categories = {k: v for k, v in categories.items() if v}

        return {
            "entitlements_count": len(keys),
            "categories": categories,
        }
    except Exception:
        return None


# ─── Layer 8: Linked Frameworks ───────────────────────────────────────────────

def extract_frameworks(app_path):
    """Extract linked frameworks via otool."""
    app_name = os.path.basename(app_path).replace('.app', '')
    binary = os.path.join(app_path, "Contents", "MacOS", app_name)
    if not os.path.exists(binary):
        # Try finding any binary in MacOS/
        macos_dir = os.path.join(app_path, "Contents", "MacOS")
        if os.path.isdir(macos_dir):
            bins = [f for f in os.listdir(macos_dir) if not f.startswith('.')]
            if bins:
                binary = os.path.join(macos_dir, bins[0])
            else:
                return None
        else:
            return None

    try:
        result = subprocess.run(
            ["otool", "-L", binary],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode != 0:
            return None

        frameworks = []
        for line in result.stdout.splitlines()[1:]:  # Skip first line (binary path)
            line = line.strip()
            match = re.search(r'/([^/]+)\.framework/', line)
            if match:
                fw = match.group(1)
                if fw not in frameworks:
                    frameworks.append(fw)

        # Notable frameworks for automation
        automation_relevant = [
            'AppIntents', 'Intents', 'IntentsUI', 'SiriKit',
            'Shortcuts', 'ShortcutsFoundation',
            'Automator', 'OSAKit', 'AppleScript',
            'CoreSpotlight', 'UserNotifications',
            'CloudKit', 'CoreData', 'SwiftData',
            'WebKit', 'SafariServices',
            'AVFoundation', 'CoreAudio', 'CoreMedia',
            'MapKit', 'CoreLocation',
            'Contacts', 'EventKit', 'Photos', 'MediaPlayer',
        ]
        notable = [f for f in frameworks if f in automation_relevant]

        return {
            "total_frameworks": len(frameworks),
            "notable_frameworks": notable,
            "all_frameworks": frameworks,
        }
    except Exception:
        return None


# ─── Layer 9: Spotlight Metadata ──────────────────────────────────────────────

def extract_spotlight(app_path):
    """Extract Spotlight metadata via mdls."""
    try:
        result = subprocess.run(
            ["mdls", app_path],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode != 0:
            return None

        metadata = {}
        for line in result.stdout.splitlines():
            if '=' in line:
                key, _, val = line.partition('=')
                key = key.strip()
                val = val.strip().strip('"')
                if val and val != '(null)':
                    # Only keep interesting keys
                    if key in ('kMDItemCFBundleIdentifier', 'kMDItemVersion',
                               'kMDItemContentType', 'kMDItemKind',
                               'kMDItemAppStoreCategory', 'kMDItemCopyright'):
                        metadata[key.replace('kMDItem', '')] = val

        return metadata if metadata else None
    except Exception:
        return None


# ─── Layer 10: LaunchServices (opt-in, expensive) ────────────────────────────

_LS_CACHE = None

def extract_launchservices(app_path):
    """Extract LaunchServices registration data. Expensive — cached."""
    global _LS_CACHE
    if _LS_CACHE is None:
        try:
            lsregister = "/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
            result = subprocess.run(
                [lsregister, "-dump"],
                capture_output=True, text=True, timeout=30
            )
            if result.returncode != 0:
                _LS_CACHE = {}
                return None
            _LS_CACHE = result.stdout
        except Exception:
            _LS_CACHE = {}
            return None

    if not _LS_CACHE:
        return None

    # Find this app's section in the dump
    app_basename = os.path.basename(app_path)
    lines = _LS_CACHE if isinstance(_LS_CACHE, str) else ""

    # Extract claimed UTIs and URL schemes from LS dump
    in_section = False
    claimed_utis = []
    claimed_schemes = []

    for line in lines.splitlines():
        if app_basename in line and 'path:' in line:
            in_section = True
            continue
        if in_section:
            if line.startswith('---'):
                break
            if 'claimed UTIs:' in line.lower() or 'bindings:' in line.lower():
                # Capture UTI lines following
                pass
            stripped = line.strip()
            if stripped.startswith('uti:'):
                claimed_utis.append(stripped.split(':', 1)[1].strip())
            elif 'scheme:' in stripped.lower():
                claimed_schemes.append(stripped)

    result = {}
    if claimed_utis:
        result['claimed_utis'] = claimed_utis[:20]  # Cap at 20
    if claimed_schemes:
        result['claimed_schemes'] = claimed_schemes[:10]

    return result if result else None


# ─── Layer 11: Plugin Extensions ──────────────────────────────────────────────

def extract_plugins(app_path):
    """Scan for .appex plugin extensions."""
    plugins_dir = os.path.join(app_path, "Contents", "PlugIns")
    if not os.path.isdir(plugins_dir):
        return None

    plugins = []
    try:
        for entry in os.listdir(plugins_dir):
            if entry.endswith('.appex'):
                name = entry.replace('.appex', '')
                plugin_info = {"name": name}

                # Try to read the plugin's Info.plist for its extension point
                plugin_plist_path = os.path.join(plugins_dir, entry, "Contents", "Info.plist")
                if os.path.exists(plugin_plist_path):
                    try:
                        with open(plugin_plist_path, 'rb') as f:
                            pplist = plistlib.load(f)
                        ext = pplist.get('NSExtension', {})
                        if isinstance(ext, dict):
                            point = ext.get('NSExtensionPointIdentifier', '')
                            if point:
                                plugin_info['extension_point'] = point
                    except Exception:
                        pass

                plugins.append(plugin_info)
    except Exception:
        return None

    return {"plugins": plugins} if plugins else None


# ─── Layer 12: Notification Actions ───────────────────────────────────────────

def extract_notifications(app_path, plist=None):
    """Extract notification action categories from Info.plist."""
    if plist is None:
        plist = load_info_plist(app_path)
    if not plist:
        return None

    notif = plist.get('UNUserNotificationCenter', {})
    if not notif or not isinstance(notif, dict):
        return None

    categories = notif.get('UNDefaultCategories', [])
    if not categories:
        return None

    result = []
    for cat in categories:
        entry = {"id": cat.get('UNCategoryIdentifier', '')}
        actions = cat.get('UNCategoryActions', [])
        if actions:
            entry['actions'] = []
            for a in actions:
                action = {
                    "id": a.get('UNActionIdentifier', ''),
                    "title": a.get('UNActionTitle', ''),
                }
                if a.get('UNActionDestructive'):
                    action['destructive'] = True
                if a.get('UNActionForeground'):
                    action['foreground'] = True
                entry['actions'].append(action)
        result.append(entry)

    return {"notification_categories": result} if result else None


# ─── Layer 13: CLI Tools ──────────────────────────────────────────────────────

CLI_TOOLS = [
    # Automation essentials
    {"name": "osascript", "description": "Execute AppleScript/JXA from command line"},
    {"name": "automator", "description": "Run Automator workflows from CLI"},
    {"name": "shortcuts", "description": "Run/list/view Shortcuts from CLI"},
    # File & metadata
    {"name": "mdls", "description": "List Spotlight metadata for a file"},
    {"name": "mdfind", "description": "Search via Spotlight index"},
    {"name": "mdutil", "description": "Manage Spotlight indexing"},
    {"name": "xattr", "description": "Display/modify extended attributes"},
    {"name": "ditto", "description": "Copy files preserving metadata"},
    {"name": "hdiutil", "description": "Manage disk images (.dmg)"},
    # System
    {"name": "defaults", "description": "Read/write macOS preferences"},
    {"name": "open", "description": "Open files/URLs/apps (the universal launcher)"},
    {"name": "pbcopy", "description": "Copy stdin to clipboard"},
    {"name": "pbpaste", "description": "Paste clipboard to stdout"},
    {"name": "say", "description": "Text-to-speech"},
    {"name": "screencapture", "description": "Take screenshots"},
    {"name": "sips", "description": "Scriptable image processing"},
    {"name": "afconvert", "description": "Audio file conversion"},
    {"name": "afplay", "description": "Play audio files"},
    {"name": "afinfo", "description": "Audio file info"},
    {"name": "networksetup", "description": "Network configuration"},
    {"name": "pmset", "description": "Power management settings"},
    {"name": "caffeinate", "description": "Prevent sleep"},
    {"name": "diskutil", "description": "Manage disks and volumes"},
    # Developer
    {"name": "plutil", "description": "Property list utility"},
    {"name": "PlistBuddy", "description": "Read/write plist files (at /usr/libexec/)"},
    {"name": "codesign", "description": "Code signing and verification"},
    {"name": "sdef", "description": "Extract scripting dictionaries"},
    {"name": "lsregister", "description": "LaunchServices database tool"},
    {"name": "swift", "description": "Swift REPL and scripting"},
    {"name": "xcodebuild", "description": "Build Xcode projects from CLI"},
    {"name": "xcrun", "description": "Run Xcode developer tools"},
    # Text processing
    {"name": "textutil", "description": "Convert text file formats (rtf, html, doc, docx)"},
    {"name": "qlmanage", "description": "QuickLook management/preview from CLI"},
]


def extract_cli_tools():
    """Check which CLI tools are available."""
    available = []
    for tool in CLI_TOOLS:
        name = tool['name']
        # Check standard paths
        paths = [f"/usr/bin/{name}", f"/usr/sbin/{name}", f"/usr/libexec/{name}"]
        found = False
        for p in paths:
            if os.path.exists(p):
                available.append({**tool, "path": p})
                found = True
                break
        if not found:
            # Try which
            try:
                result = subprocess.run(
                    ["which", name],
                    capture_output=True, text=True, timeout=5
                )
                if result.returncode == 0 and result.stdout.strip():
                    available.append({**tool, "path": result.stdout.strip()})
            except Exception:
                pass

    return available


# ─── YAML Generation ─────────────────────────────────────────────────────────

def generate_probe_yaml(app_name, app_path, layers):
    """Generate YAML from all extracted layers."""
    lines = []
    s = slug(app_name)

    lines.append(f"# {app_name} — Automation Probe")
    lines.append(f"# Extracted via: app-probe.py (13 layers)")
    lines.append(f"# Path: {app_path}")
    lines.append("")
    lines.append(f"app: {yaml_escape(app_name)}")
    lines.append(f"slug: {yaml_escape(s)}")
    lines.append(f"path: {yaml_escape(app_path)}")
    lines.append(f"layers_found: {len([v for v in layers.values() if v is not None])}")
    lines.append("")

    # Layer 1: sdef
    sdef = layers.get('sdef')
    if sdef:
        lines.append("# ─── Layer 1: Scripting Dictionary ───")
        lines.append("sdef:")
        lines.append(f"  has_sdef: true")
        lines.append(f"  suites: {sdef['suites']}")
        lines.append(f"  commands: {sdef['commands']}")
        lines.append(f"  classes: {sdef['classes']}")
        if sdef['command_names']:
            lines.append(f"  command_names:")
            for c in sdef['command_names']:
                lines.append(f"    - {yaml_escape(c)}")
        lines.append("")

    # Layer 2: URL Schemes
    urls = layers.get('url_schemes')
    if urls:
        lines.append("# ─── Layer 2: URL Schemes ───")
        lines.append("url_schemes:")
        for scheme in urls['url_schemes']:
            lines.append(f"  - scheme: {yaml_escape(scheme['scheme'])}")
            if scheme['name']:
                lines.append(f"    name: {yaml_escape(scheme['name'])}")
            if scheme['is_default']:
                lines.append(f"    is_default: true")
        lines.append("")

    # Layer 3: Document Types
    docs = layers.get('document_types')
    if docs:
        lines.append("# ─── Layer 3: Document Types ───")
        lines.append(f"document_types_count: {len(docs['document_types'])}")
        lines.append("document_types:")
        for dt in docs['document_types'][:30]:  # Cap for readability
            if dt.get('name'):
                lines.append(f"  - name: {yaml_escape(dt['name'])}")
            else:
                lines.append(f"  - name: \"(unnamed)\"")
            if dt.get('extensions'):
                lines.append(f"    extensions: {json.dumps(dt['extensions'])}")
            if dt.get('role'):
                lines.append(f"    role: {yaml_escape(dt['role'])}")
            if dt.get('content_types'):
                lines.append(f"    content_types: {json.dumps(dt['content_types'][:5])}")
        if len(docs['document_types']) > 30:
            lines.append(f"  # ... and {len(docs['document_types']) - 30} more")
        lines.append("")

    # Layer 4: App Intents
    intents = layers.get('app_intents')
    if intents:
        lines.append("# ─── Layer 4: App Intents / Siri Phrases ───")
        lines.append("app_intents:")
        if intents.get('siri_phrases'):
            lines.append(f"  siri_phrases:")
            for phrase in intents['siri_phrases']:
                lines.append(f"    - {yaml_escape(phrase)}")
        if intents.get('actions'):
            lines.append(f"  actions_count: {len(intents['actions'])}")
            lines.append(f"  actions:")
            for action in intents['actions']:
                lines.append(f"    - id: {yaml_escape(action['id'])}")
                if action.get('title'):
                    lines.append(f"      title: {yaml_escape(action['title'])}")
                if action.get('description'):
                    lines.append(f"      description: {yaml_escape(action['description'])}")
                if action.get('parameters'):
                    lines.append(f"      parameters: {json.dumps(action['parameters'])}")
        if intents.get('queries'):
            lines.append(f"  queries:")
            for q in intents['queries']:
                lines.append(f"    - id: {yaml_escape(q['id'])}")
                if q.get('title'):
                    lines.append(f"      title: {yaml_escape(q['title'])}")
        if intents.get('entity_names'):
            lines.append(f"  entities: {json.dumps(intents['entity_names'])}")
        if intents.get('enum_names'):
            lines.append(f"  enums: {json.dumps(intents['enum_names'])}")
        if intents.get('auto_shortcuts_count'):
            lines.append(f"  auto_shortcuts: {intents['auto_shortcuts_count']}")
        lines.append("")

    # Layer 5: Services
    services = layers.get('services')
    if services:
        lines.append("# ─── Layer 5: NSServices ───")
        lines.append("services:")
        for svc in services['services']:
            lines.append(f"  - menu_item: {yaml_escape(svc.get('menu_item', ''))}")
            if svc.get('message'):
                lines.append(f"    message: {yaml_escape(svc['message'])}")
            if svc.get('send_types'):
                lines.append(f"    send_types: {json.dumps(svc['send_types'])}")
            if svc.get('return_types'):
                lines.append(f"    return_types: {json.dumps(svc['return_types'])}")
        lines.append("")

    # Layer 6: Activity Types
    activities = layers.get('activity_types')
    if activities:
        lines.append("# ─── Layer 6: User Activity Types ───")
        lines.append("activity_types:")
        for a in activities['activity_types']:
            lines.append(f"  - {yaml_escape(a)}")
        lines.append("")

    # Layer 7: Entitlements
    ent = layers.get('entitlements')
    if ent:
        lines.append("# ─── Layer 7: Entitlements ───")
        lines.append(f"entitlements_count: {ent['entitlements_count']}")
        lines.append("entitlements:")
        for cat, keys in ent['categories'].items():
            lines.append(f"  {cat}:")
            for k in keys:
                lines.append(f"    - {yaml_escape(k)}")
        lines.append("")

    # Layer 8: Frameworks
    fw = layers.get('frameworks')
    if fw:
        lines.append("# ─── Layer 8: Linked Frameworks ───")
        lines.append(f"frameworks_count: {fw['total_frameworks']}")
        if fw['notable_frameworks']:
            lines.append("notable_frameworks:")
            for f in fw['notable_frameworks']:
                lines.append(f"  - {f}")
        lines.append("")

    # Layer 9: Spotlight
    spot = layers.get('spotlight')
    if spot:
        lines.append("# ─── Layer 9: Spotlight Metadata ───")
        lines.append("spotlight:")
        for k, v in spot.items():
            lines.append(f"  {k}: {yaml_escape(v)}")
        lines.append("")

    # Layer 10: LaunchServices
    ls = layers.get('launchservices')
    if ls:
        lines.append("# ─── Layer 10: LaunchServices ───")
        lines.append("launchservices:")
        if ls.get('claimed_utis'):
            lines.append("  claimed_utis:")
            for u in ls['claimed_utis']:
                lines.append(f"    - {yaml_escape(u)}")
        lines.append("")

    # Layer 11: Plugins
    plugins = layers.get('plugins')
    if plugins:
        lines.append("# ─── Layer 11: Plugin Extensions ───")
        lines.append("plugins:")
        for p in plugins['plugins']:
            lines.append(f"  - name: {yaml_escape(p['name'])}")
            if p.get('extension_point'):
                lines.append(f"    extension_point: {yaml_escape(p['extension_point'])}")
        lines.append("")

    # Layer 12: Notifications
    notif = layers.get('notifications')
    if notif:
        lines.append("# ─── Layer 12: Notification Actions ───")
        lines.append("notification_categories:")
        for cat in notif['notification_categories']:
            lines.append(f"  - id: {yaml_escape(cat['id'])}")
            if cat.get('actions'):
                lines.append(f"    actions:")
                for a in cat['actions']:
                    lines.append(f"      - id: {yaml_escape(a['id'])}")
                    lines.append(f"        title: {yaml_escape(a['title'])}")
                    if a.get('destructive'):
                        lines.append(f"        destructive: true")
        lines.append("")

    return '\n'.join(lines)


# ─── Markdown Generation ─────────────────────────────────────────────────────

def generate_probe_md(app_name, app_path, layers):
    """Generate human-readable markdown from all layers."""
    lines = []
    s = slug(app_name)
    layer_count = len([v for v in layers.values() if v is not None])

    lines.append(f"# {app_name} — Automation Probe")
    lines.append("")
    lines.append(f"> **{layer_count} automation layers** extracted from `{app_path}`")
    lines.append(f"> Generated by `app-probe.py`")
    lines.append("")

    # Layer 1: sdef
    sdef = layers.get('sdef')
    if sdef:
        lines.append("## 1. Scripting Dictionary (sdef)")
        lines.append("")
        lines.append(f"**{sdef['commands']} commands**, **{sdef['classes']} classes**, **{sdef['suites']} suites**")
        lines.append("")
        lines.append(f"See [`{s}.md`]({s}.md) for full reference and [`{s}-examples.md`]({s}-examples.md) for snippets.")
        lines.append("")
        if sdef['command_names']:
            lines.append("Commands: " + ", ".join(f"`{c}`" for c in sdef['command_names']))
            lines.append("")

    # Layer 2: URL Schemes
    urls = layers.get('url_schemes')
    if urls:
        lines.append("## 2. URL Schemes")
        lines.append("")
        lines.append("| Scheme | Name | Default |")
        lines.append("|--------|------|---------|")
        for scheme in urls['url_schemes']:
            default = "Yes" if scheme['is_default'] else ""
            lines.append(f"| `{scheme['scheme']}://` | {scheme['name']} | {default} |")
        lines.append("")
        lines.append("```bash")
        lines.append(f"# Open via URL scheme")
        if urls['url_schemes']:
            first = urls['url_schemes'][0]['scheme']
            lines.append(f"open \"{first}://\"")
        lines.append("```")
        lines.append("")

    # Layer 3: Document Types
    docs = layers.get('document_types')
    if docs:
        lines.append(f"## 3. Document Types ({len(docs['document_types'])} types)")
        lines.append("")
        # Show first 15 types
        shown = 0
        for dt in docs['document_types']:
            name = dt.get('name', '?')
            role = dt.get('role', '')
            if dt.get('extensions'):
                exts = ', '.join(f"`.{e}`" for e in dt['extensions'][:5])
                lines.append(f"- **{name}** — {exts} ({role})")
            elif dt.get('content_types'):
                uti = dt['content_types'][0]
                lines.append(f"- **{name}** — `{uti}` ({role})")
            else:
                lines.append(f"- **{name}** ({role})")
            shown += 1
            if shown >= 15:
                remaining = len(docs['document_types']) - shown
                if remaining > 0:
                    lines.append(f"- *...and {remaining} more types*")
                break
        lines.append("")

    # Layer 4: App Intents
    intents = layers.get('app_intents')
    if intents:
        lines.append("## 4. App Intents / Siri Phrases")
        lines.append("")
        if intents.get('siri_phrases'):
            lines.append("### Siri Phrases")
            lines.append("")
            for phrase in intents['siri_phrases']:
                lines.append(f'- *"{phrase}"*')
            lines.append("")
        if intents.get('actions'):
            lines.append(f"### Shortcuts Actions ({len(intents['actions'])})")
            lines.append("")
            lines.append("| Action | Title | Parameters |")
            lines.append("|--------|-------|------------|")
            for action in intents['actions']:
                title = action.get('title', '')
                params = ', '.join(action.get('parameters', [])[:3])
                lines.append(f"| `{action['id']}` | {title} | {params} |")
            lines.append("")
        if intents.get('queries'):
            lines.append(f"### Queries ({len(intents['queries'])})")
            lines.append("")
            for q in intents['queries']:
                title = q.get('title', '')
                lines.append(f"- `{q['id']}` — {title}")
            lines.append("")

    # Layer 5: Services
    services = layers.get('services')
    if services:
        lines.append("## 5. Services Menu")
        lines.append("")
        for svc in services['services']:
            lines.append(f"- **{svc.get('menu_item', '?')}** → `{svc.get('message', '')}`")
            if svc.get('send_types'):
                lines.append(f"  - Accepts: {', '.join(f'`{t}`' for t in svc['send_types'])}")
        lines.append("")

    # Layer 6: Activities
    activities = layers.get('activity_types')
    if activities:
        lines.append("## 6. User Activity Types (Handoff/Spotlight)")
        lines.append("")
        for a in activities['activity_types']:
            lines.append(f"- `{a}`")
        lines.append("")

    # Layer 7: Entitlements
    ent = layers.get('entitlements')
    if ent:
        lines.append(f"## 7. Entitlements ({ent['entitlements_count']} total)")
        lines.append("")
        for cat, keys in ent['categories'].items():
            lines.append(f"### {cat.replace('_', ' ').title()} ({len(keys)})")
            lines.append("")
            for k in keys[:10]:
                lines.append(f"- `{k}`")
            if len(keys) > 10:
                lines.append(f"- *...and {len(keys) - 10} more*")
            lines.append("")

    # Layer 8: Frameworks
    fw = layers.get('frameworks')
    if fw:
        lines.append(f"## 8. Linked Frameworks ({fw['total_frameworks']} total)")
        lines.append("")
        if fw['notable_frameworks']:
            lines.append("**Automation-relevant:**")
            lines.append("")
            for f in fw['notable_frameworks']:
                lines.append(f"- `{f}`")
            lines.append("")

    # Layer 9: Spotlight
    spot = layers.get('spotlight')
    if spot:
        lines.append("## 9. Spotlight Metadata")
        lines.append("")
        for k, v in spot.items():
            lines.append(f"- **{k}**: {v}")
        lines.append("")

    # Layer 11: Plugins
    plugins = layers.get('plugins')
    if plugins:
        lines.append(f"## 11. Plugin Extensions ({len(plugins['plugins'])})")
        lines.append("")
        for p in plugins['plugins']:
            ext = p.get('extension_point', '')
            lines.append(f"- **{p['name']}** — `{ext}`")
        lines.append("")

    # Layer 12: Notifications
    notif = layers.get('notifications')
    if notif:
        lines.append("## 12. Notification Actions")
        lines.append("")
        for cat in notif['notification_categories']:
            lines.append(f"### `{cat['id']}`")
            lines.append("")
            if cat.get('actions'):
                for a in cat['actions']:
                    dest = " (destructive)" if a.get('destructive') else ""
                    lines.append(f"- **{a['title']}** — `{a['id']}`{dest}")
            lines.append("")

    return '\n'.join(lines)


# ─── Cross-App Index ─────────────────────────────────────────────────────────

def generate_probe_index(all_results):
    """Generate cross-app capabilities index."""
    lines = []
    lines.append("# Apple App Automation Probe Index")
    lines.append("# Cross-app capabilities map — all 13 layers")
    lines.append("# Generated by app-probe.py")
    lines.append("")

    # ── URL Scheme Registry ──
    lines.append("# ─── URL Scheme Registry ───")
    lines.append("# Which app handles which URL scheme?")
    lines.append("url_schemes:")
    scheme_map = {}  # scheme -> app
    for app_name, data in sorted(all_results.items()):
        urls = data['layers'].get('url_schemes')
        if urls:
            for scheme in urls['url_schemes']:
                s = scheme['scheme']
                scheme_map.setdefault(s, []).append(slug(app_name))
    for scheme, apps in sorted(scheme_map.items()):
        lines.append(f"  {scheme}: {json.dumps(apps)}")
    lines.append("")

    # ── Document Type Registry ──
    lines.append("# ─── Document Type Summary ───")
    lines.append("document_types:")
    for app_name, data in sorted(all_results.items()):
        docs = data['layers'].get('document_types')
        if docs:
            count = len(docs['document_types'])
            exts = set()
            for dt in docs['document_types']:
                for e in dt.get('extensions', []):
                    exts.add(e)
            if exts:
                lines.append(f"  {slug(app_name)}: {json.dumps(sorted(exts)[:15])}")
    lines.append("")

    # ── App Intents Summary ──
    lines.append("# ─── App Intents Summary ───")
    lines.append("# Which apps have Siri/Shortcuts integration?")
    lines.append("app_intents:")
    for app_name, data in sorted(all_results.items()):
        intents = data['layers'].get('app_intents')
        if intents:
            actions_count = len(intents.get('actions', []))
            phrases_count = len(intents.get('siri_phrases', []))
            queries_count = len(intents.get('queries', []))
            lines.append(f"  {slug(app_name)}:")
            lines.append(f"    actions: {actions_count}")
            lines.append(f"    siri_phrases: {phrases_count}")
            lines.append(f"    queries: {queries_count}")
    lines.append("")

    # ── Services Map ──
    lines.append("# ─── Services Menu Map ───")
    lines.append("services:")
    for app_name, data in sorted(all_results.items()):
        services = data['layers'].get('services')
        if services:
            items = [svc.get('menu_item', '') for svc in services['services']]
            lines.append(f"  {slug(app_name)}: {json.dumps(items)}")
    lines.append("")

    # ── sdef Summary ──
    lines.append("# ─── Scripting Dictionary Summary ───")
    lines.append("sdef:")
    for app_name, data in sorted(all_results.items()):
        sdef = data['layers'].get('sdef')
        if sdef:
            lines.append(f"  {slug(app_name)}:")
            lines.append(f"    commands: {sdef['commands']}")
            lines.append(f"    classes: {sdef['classes']}")
    lines.append("")

    # ── Plugin Extensions Summary ──
    lines.append("# ─── Plugin Extensions ───")
    lines.append("plugins:")
    for app_name, data in sorted(all_results.items()):
        plugins = data['layers'].get('plugins')
        if plugins:
            names = [p['name'] for p in plugins['plugins']]
            lines.append(f"  {slug(app_name)}: {json.dumps(names)}")
    lines.append("")

    # ── Framework Support Matrix ──
    lines.append("# ─── Automation Framework Matrix ───")
    lines.append("# Which apps link which automation frameworks?")
    lines.append("framework_matrix:")
    fw_map = {}
    for app_name, data in sorted(all_results.items()):
        fw = data['layers'].get('frameworks')
        if fw and fw['notable_frameworks']:
            for f in fw['notable_frameworks']:
                fw_map.setdefault(f, []).append(slug(app_name))
    for framework, apps in sorted(fw_map.items()):
        lines.append(f"  {framework}: {json.dumps(apps)}")
    lines.append("")

    # ── Notification Actions Summary ──
    lines.append("# ─── Notification Actions ───")
    lines.append("notifications:")
    for app_name, data in sorted(all_results.items()):
        notif = data['layers'].get('notifications')
        if notif:
            count = sum(len(cat.get('actions', [])) for cat in notif['notification_categories'])
            lines.append(f"  {slug(app_name)}: {count} actions")
    lines.append("")

    # ── Summary Stats ──
    total_apps = len(all_results)
    sdef_count = sum(1 for d in all_results.values() if d['layers'].get('sdef'))
    intents_count = sum(1 for d in all_results.values() if d['layers'].get('app_intents'))
    url_count = sum(1 for d in all_results.values() if d['layers'].get('url_schemes'))
    services_count = sum(1 for d in all_results.values() if d['layers'].get('services'))
    plugins_count = sum(1 for d in all_results.values() if d['layers'].get('plugins'))

    lines.append("# ─── Summary ───")
    lines.append("summary:")
    lines.append(f"  total_apps_probed: {total_apps}")
    lines.append(f"  with_sdef: {sdef_count}")
    lines.append(f"  with_app_intents: {intents_count}")
    lines.append(f"  with_url_schemes: {url_count}")
    lines.append(f"  with_services: {services_count}")
    lines.append(f"  with_plugins: {plugins_count}")

    return '\n'.join(lines)


# ─── Main Probe ──────────────────────────────────────────────────────────────

def probe_app(app_name, app_path, layer_filter=None, include_ls=False):
    """Run all layers on a single app. Returns dict of results."""
    plist = load_info_plist(app_path)

    layers = {}

    extractors = {
        'sdef':           lambda: extract_sdef(app_path),
        'url_schemes':    lambda: extract_url_schemes(app_path, plist),
        'document_types': lambda: extract_document_types(app_path, plist),
        'app_intents':    lambda: extract_app_intents(app_path),
        'services':       lambda: extract_services(app_path, plist),
        'activity_types': lambda: extract_activity_types(app_path, plist),
        'entitlements':   lambda: extract_entitlements(app_path),
        'frameworks':     lambda: extract_frameworks(app_path),
        'spotlight':      lambda: extract_spotlight(app_path),
        'plugins':        lambda: extract_plugins(app_path),
        'notifications':  lambda: extract_notifications(app_path, plist),
    }

    if include_ls:
        extractors['launchservices'] = lambda: extract_launchservices(app_path)

    # Layer name aliases for --layer filter
    layer_aliases = {
        'sdef': 'sdef', 'scripting': 'sdef', 'dictionary': 'sdef',
        'url': 'url_schemes', 'urls': 'url_schemes', 'schemes': 'url_schemes',
        'docs': 'document_types', 'documents': 'document_types', 'doctypes': 'document_types',
        'intents': 'app_intents', 'siri': 'app_intents', 'shortcuts': 'app_intents',
        'services': 'services', 'nsservices': 'services',
        'activities': 'activity_types', 'activity': 'activity_types', 'handoff': 'activity_types',
        'entitlements': 'entitlements', 'ent': 'entitlements',
        'frameworks': 'frameworks', 'fw': 'frameworks',
        'spotlight': 'spotlight', 'mdls': 'spotlight',
        'ls': 'launchservices', 'launchservices': 'launchservices',
        'plugins': 'plugins', 'extensions': 'plugins', 'appex': 'plugins',
        'notifications': 'notifications', 'notif': 'notifications',
    }

    if layer_filter:
        resolved = layer_aliases.get(layer_filter.lower())
        if resolved and resolved in extractors:
            try:
                layers[resolved] = extractors[resolved]()
            except Exception as e:
                print(f"    Error in {resolved}: {e}")
                layers[resolved] = None
        else:
            print(f"    Unknown layer: {layer_filter}")
            print(f"    Available: {', '.join(sorted(set(layer_aliases.keys())))}")
            return None
    else:
        for layer_name, extractor in extractors.items():
            try:
                layers[layer_name] = extractor()
            except Exception as e:
                print(f"    Error in {layer_name}: {e}")
                layers[layer_name] = None

    return layers


def main():
    args = sys.argv[1:]

    # Parse flags
    layer_filter = None
    include_cli = False
    include_ls = False
    show_list = False
    app_names = []

    if '--help' in args or '-h' in args:
        print("app-probe.py — Extract ALL automation knowledge from every Apple app.")
        print("")
        print("Usage:")
        print("  python3 bin/app-probe.py                    # All apps, all layers")
        print("  python3 bin/app-probe.py Mail               # Single app")
        print("  python3 bin/app-probe.py --layer intents    # Only App Intents layer")
        print("  python3 bin/app-probe.py --layer url        # Only URL schemes")
        print("  python3 bin/app-probe.py --cli              # Include CLI tools (layer 13)")
        print("  python3 bin/app-probe.py --list             # Show available apps")
        print("  python3 bin/app-probe.py --ls               # Include LaunchServices (slow)")
        print("  python3 bin/app-probe.py --help             # Show this help")
        print("")
        print("Options:")
        print("  --layer LAYER  Only extract a specific layer (sdef, url, doc, intents,")
        print("                 services, activity, entitlements, frameworks, spotlight,")
        print("                 ls, plugins, notifications)")
        print("  --cli          Include CLI tools scan (layer 13)")
        print("  --ls           Include LaunchServices dump (slow)")
        print("  --list         Show all available apps and exit")
        print("  --help, -h     Show this help and exit")
        print("")
        print("Output:")
        print("  dictionaries/<app>/<app>-probe.yaml   Machine-readable probe results")
        print("  dictionaries/<app>/<app>-probe.md     Human-readable probe results")
        print("  dictionaries/_probe-index.yaml        Cross-app capabilities map")
        return

    i = 0
    while i < len(args):
        if args[i] == '--layer' and i + 1 < len(args):
            layer_filter = args[i + 1]
            i += 2
        elif args[i] == '--cli':
            include_cli = True
            i += 1
        elif args[i] == '--ls':
            include_ls = True
            i += 1
        elif args[i] == '--list':
            show_list = True
            i += 1
        else:
            app_names.append(args[i])
            i += 1

    if show_list:
        print("Available Apps for Probing:")
        print("")
        cats = {}
        for name, info in sorted(APP_REGISTRY.items()):
            cats.setdefault(info['category'], []).append((name, info['path']))
        for cat in ['system', 'utility', 'core', 'pro']:
            if cat in cats:
                print(f"  ── {cat.upper()} ──")
                for name, path in cats[cat]:
                    exists = os.path.exists(path)
                    status = "OK" if exists else "NOT FOUND"
                    print(f"  {name:30s} {status}")
                print()
        return

    # Select apps
    if app_names:
        apps = {}
        for name in app_names:
            # Try exact match first, then case-insensitive
            if name in APP_REGISTRY:
                apps[name] = APP_REGISTRY[name]
            else:
                found = False
                for reg_name in APP_REGISTRY:
                    if reg_name.lower() == name.lower():
                        apps[reg_name] = APP_REGISTRY[reg_name]
                        found = True
                        break
                if not found:
                    print(f"Unknown app: {name}")
                    print(f"Use --list to see available apps")
                    sys.exit(1)
    else:
        apps = APP_REGISTRY

    output_dir = OUTPUT_DIR
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"═══ Apple App Automation Probe ═══")
    print(f"Output: {output_dir}")
    print(f"Apps: {len(apps)}")
    if layer_filter:
        print(f"Layer filter: {layer_filter}")
    print()

    all_results = {}

    for app_name, info in sorted(apps.items()):
        app_path = info['path']
        if not os.path.exists(app_path):
            print(f"  {app_name}: NOT FOUND, skipping")
            continue

        print(f"  Probing: {app_name}...", end=" ", flush=True)

        layers = probe_app(app_name, app_path, layer_filter=layer_filter, include_ls=include_ls)
        if layers is None:
            continue

        found = [k for k, v in layers.items() if v is not None]
        print(f"{len(found)} layers ({', '.join(found)})")

        # Write per-app files
        s = slug(app_name)
        app_dir = output_dir / s
        app_dir.mkdir(parents=True, exist_ok=True)

        yaml_content = generate_probe_yaml(app_name, app_path, layers)
        md_content = generate_probe_md(app_name, app_path, layers)

        (app_dir / f"{s}-probe.yaml").write_text(yaml_content)
        (app_dir / f"{s}-probe.md").write_text(md_content)

        all_results[app_name] = {
            'path': app_path,
            'category': info['category'],
            'layers': layers,
        }

    # CLI tools (layer 13) — written to index only
    cli_data = None
    if include_cli:
        print(f"\n  Scanning CLI tools...", end=" ", flush=True)
        cli_data = extract_cli_tools()
        print(f"{len(cli_data)} tools found")

    # Generate cross-app index
    if all_results and not layer_filter:
        index_content = generate_probe_index(all_results)

        # Append CLI tools to index if requested
        if cli_data:
            cli_lines = ["\n# ─── Layer 13: CLI Tools ───", "cli_tools:"]
            for tool in cli_data:
                cli_lines.append(f"  - name: {tool['name']}")
                cli_lines.append(f"    path: {tool['path']}")
                cli_lines.append(f"    description: {yaml_escape(tool['description'])}")
            index_content += '\n' + '\n'.join(cli_lines)

        (output_dir / "_probe-index.yaml").write_text(index_content)
        print(f"\nProbe index: {output_dir / '_probe-index.yaml'}")

    # Summary
    if all_results:
        total_layers = sum(
            len([v for v in d['layers'].values() if v is not None])
            for d in all_results.values()
        )
        print(f"\n═══ Done: {len(all_results)} apps, {total_layers} total layer hits ═══")

        # Highlights
        intents_apps = [n for n, d in all_results.items() if d['layers'].get('app_intents')]
        if intents_apps:
            print(f"  App Intents: {', '.join(intents_apps)}")
        url_apps = [n for n, d in all_results.items() if d['layers'].get('url_schemes')]
        if url_apps:
            print(f"  URL Schemes: {', '.join(url_apps)}")
    else:
        print("\nNo apps probed.")


if __name__ == '__main__':
    main()
