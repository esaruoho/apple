#!/usr/bin/env python3
"""xpc-probe.py — Enumerate and map XPC services to Apple apps.

Discovers the "dark" automation surfaces that exist below AppleScript/sdef.
These are the actual backends that system utilities delegate to.

Usage:
    python3 bin/xpc-probe.py                # Full report
    python3 bin/xpc-probe.py --yaml         # Machine-readable YAML output
    python3 bin/xpc-probe.py --app home     # Filter by app category
    python3 bin/xpc-probe.py --count        # Service counts only
"""

import subprocess
import re
import sys
import os
from pathlib import Path
from collections import defaultdict

# App categories and their XPC keyword signatures
APP_CATEGORIES = {
    'system-settings': {
        'name': 'System Settings',
        'keywords': ['settings', 'preferences', 'systemui', 'managedclient', 'managedconfiguration'],
        'painpoint': 'SYSTEM-SETTINGS-001',
        'notes': 'ExtensionKit helpers, legacyagent for pre-Ventura prefs, ManagedSettings for Screen Time',
    },
    'home': {
        'name': 'Home / HomeKit',
        'keywords': ['home', 'homekit', 'matter', 'thread'],
        'painpoint': 'HOME-001',
        'notes': 'Full HomeKit stack as user-session agents. homed.xpc is the main entry. Matter/Thread for smart home.',
    },
    'preview': {
        'name': 'Preview',
        'keywords': ['preview', 'quicklook', 'ql'],
        'painpoint': 'PREVIEW-001',
        'notes': 'previewsd + quicklookd provide rendering. No sdef but 32+ XPC services.',
    },
    'photos': {
        'name': 'Photos',
        'keywords': ['photo', 'medialibrary', 'mediaanalysis'],
        'painpoint': 'PHOTOS-001',
        'notes': 'photolibraryd is the real engine. cloudphotod for iCloud. mediaanalysisd for ML.',
    },
    'messages': {
        'name': 'Messages',
        'keywords': ['messages', 'ichat', 'madrid', 'mobilesms', 'imessage'],
        'painpoint': 'MESSAGES-001',
        'notes': 'madrid = iMessage codename. BlastDoorService = security sandbox for attachments.',
    },
    'notes': {
        'name': 'Notes',
        'keywords': ['notes'],
        'painpoint': 'NOTES-001',
        'notes': 'Notes.datastore for content. LinkedNotesUIService for Quick Note. exchangenotesd for sync.',
    },
    'screenshots': {
        'name': 'Screenshots',
        'keywords': ['screenshot', 'screencapture', 'screencaptureui'],
        'notes': 'ScreenshotServices.framework consolidated in Sequoia. screencaptureui for UI.',
    },
    'disk-utility': {
        'name': 'Disk Utility',
        'keywords': ['diskmanage', 'diskutil', 'storagek', 'diskarbitrat'],
        'notes': 'diskmanagementd (root) is the authority. storagekitd is the modern replacement. DiskArbitration for mount events.',
    },
    'time-machine': {
        'name': 'Time Machine',
        'keywords': ['backup', 'timemachine'],
        'notes': 'backupd + backupd-helper. Migrated from periodic tasks to XPC Activity (DAS-CTS) in Sequoia.',
    },
    'siri-shortcuts': {
        'name': 'Siri / Shortcuts',
        'keywords': ['siri', 'shortcuts', 'workflow', 'intent', 'actionsd'],
        'notes': 'siriactionsd is the dispatch hub. VoiceShortcuts.xpc for voice triggers. 59+ services.',
    },
    'finder': {
        'name': 'Finder',
        'keywords': ['finder', 'filecoordination', 'fileprovider'],
        'notes': 'Well-exposed via sdef already. FileProvider for cloud storage extensions.',
    },
    'music': {
        'name': 'Music',
        'keywords': ['music', 'amp', 'itunes', 'mediaremote'],
        'notes': 'AMP = Apple Music Player. itunescloudd for cloud library. mediaremoted for Now Playing.',
    },
    'mail': {
        'name': 'Mail',
        'keywords': ['mail', 'messageutility'],
        'notes': 'email.maild is the engine. MailServiceAgent for extensions. mdworker.mail for Spotlight.',
    },
    'safari': {
        'name': 'Safari',
        'keywords': ['safari', 'webkit'],
        'notes': 'Rich extension ecosystem. webpushd for push notifications. SafeBrowsing service.',
    },
    'calendar': {
        'name': 'Calendar',
        'keywords': ['calendar', 'calendarnotification'],
        'notes': 'CalendarAgent is the sync engine. CalendarExtensionSupport for third-party calendars.',
    },
    'dock': {
        'name': 'Dock / Mission Control / Launchpad',
        'keywords': ['dock', 'launchpad', 'mission'],
        'notes': 'dock.server is the main daemon. dock.spaces = Mission Control. dock.launchpad = Launchpad.',
    },
    'spotlight': {
        'name': 'Spotlight',
        'keywords': ['spotlight', 'mds', 'mdworker', 'corespotlight'],
        'notes': 'mds = metadata server. mdworker for indexing. CoreSpotlight for app content indexing.',
    },
    'accessibility': {
        'name': 'Accessibility',
        'keywords': ['accessibility', 'axserver', 'voiceover', 'assistive'],
        'notes': 'AXServer for UI element tree. VoiceOver for screen reading. UniversalAccess for settings.',
    },
}


def get_services(domain):
    """Get all Mach services from a launchctl domain."""
    result = subprocess.run(['launchctl', 'print', domain],
                          capture_output=True, text=True, timeout=10)
    services = []
    # Match both running services and Mach service endpoints
    for line in result.stdout.split('\n'):
        m = re.search(r'(com\.apple\.\S+)', line)
        if m:
            svc = m.group(1).rstrip('"').rstrip("'")
            services.append(svc)
    return sorted(set(services))


def get_launch_agents():
    """List plist files for user-level LaunchAgents."""
    agents = {}
    agent_dirs = [
        Path('/System/Library/LaunchAgents'),
        Path('/Library/LaunchAgents'),
        Path.home() / 'Library/LaunchAgents',
    ]
    for d in agent_dirs:
        if d.exists():
            for plist in d.glob('com.apple.*.plist'):
                label = plist.stem
                agents[label] = str(plist)
    return agents


def get_launch_daemons():
    """List plist files for system-level LaunchDaemons."""
    daemons = {}
    daemon_dirs = [
        Path('/System/Library/LaunchDaemons'),
        Path('/Library/LaunchDaemons'),
    ]
    for d in daemon_dirs:
        if d.exists():
            for plist in d.glob('com.apple.*.plist'):
                label = plist.stem
                daemons[label] = str(plist)
    return daemons


def categorize_services(services, domain_label):
    """Map services to app categories."""
    categorized = defaultdict(list)
    uncategorized = []

    for svc in services:
        svc_lower = svc.lower()
        matched = False
        for cat_id, cat_info in APP_CATEGORIES.items():
            for kw in cat_info['keywords']:
                if kw in svc_lower:
                    categorized[cat_id].append((svc, domain_label))
                    matched = True
                    break
            if matched:
                break
        if not matched:
            uncategorized.append((svc, domain_label))

    return categorized, uncategorized


def main():
    args = sys.argv[1:]

    if '--help' in args or '-h' in args:
        print("Usage: python3 bin/xpc-probe.py [OPTIONS]")
        print()
        print("Map XPC services across macOS — the hidden automation layer.")
        print()
        print("Options:")
        print("  --yaml          Output as YAML (default: text summary)")
        print("  --count         Show service counts only")
        print("  --app NAME      Filter to services matching app name")
        print("  --help, -h      Show this help message")
        print()
        print("Output: dictionaries/_xpc-services.yaml (with --yaml)")
        sys.exit(0)

    yaml_mode = '--yaml' in args
    count_mode = '--count' in args
    filter_app = None
    if '--app' in args:
        idx = args.index('--app')
        if idx + 1 < len(args):
            filter_app = args[idx + 1].lower()

    uid = subprocess.run(['id', '-u'], capture_output=True, text=True).stdout.strip()

    print("═══ XPC Automation Surface Probe ═══")
    print()

    # Enumerate services
    print("Enumerating user-session services...")
    user_services = get_services(f'gui/{uid}')
    print(f"  User Mach services: {len(user_services)}")

    print("Enumerating system services...")
    system_services = get_services('system')
    print(f"  System Mach services: {len(system_services)}")

    # Get LaunchAgent/Daemon plists
    agents = get_launch_agents()
    daemons = get_launch_daemons()
    print(f"  LaunchAgent plists: {len(agents)}")
    print(f"  LaunchDaemon plists: {len(daemons)}")
    print()

    # Categorize
    user_cats, user_uncat = categorize_services(user_services, 'user')
    sys_cats, sys_uncat = categorize_services(system_services, 'system')

    # Merge categories
    all_cats = defaultdict(list)
    for cat_id in set(list(user_cats.keys()) + list(sys_cats.keys())):
        all_cats[cat_id] = sorted(set(user_cats.get(cat_id, []) + sys_cats.get(cat_id, [])))

    total_mapped = sum(len(v) for v in all_cats.values())
    total_unmapped = len(user_uncat) + len(sys_uncat)
    total = len(user_services) + len(system_services)

    print(f"Total: {total} services ({total_mapped} mapped to {len(all_cats)} apps, {total_unmapped} unmapped)")
    print()

    if count_mode:
        print(f"{'App':<30} {'Services':>8}  {'Has Painpoint':>13}")
        print("-" * 55)
        for cat_id in sorted(all_cats.keys(), key=lambda x: len(all_cats[x]), reverse=True):
            cat = APP_CATEGORIES[cat_id]
            pp = cat.get('painpoint', '-')
            print(f"{cat['name']:<30} {len(all_cats[cat_id]):>8}  {pp:>13}")
        return

    # Full report
    for cat_id in sorted(all_cats.keys(), key=lambda x: APP_CATEGORIES[x]['name']):
        cat = APP_CATEGORIES[cat_id]

        if filter_app and filter_app not in cat_id and filter_app not in cat['name'].lower():
            continue

        services = all_cats[cat_id]
        pp = cat.get('painpoint', '')
        painpoint_str = f" [Painpoint: {pp}]" if pp else ""

        if yaml_mode:
            print(f"{cat_id}:")
            print(f"  name: \"{cat['name']}\"")
            print(f"  service_count: {len(services)}")
            if pp:
                print(f"  painpoint: \"{pp}\"")
            print(f"  notes: \"{cat['notes']}\"")
            print(f"  services:")
            for svc, domain in services:
                print(f"    - service: \"{svc}\"")
                print(f"      domain: \"{domain}\"")
            print()
        else:
            print(f"### {cat['name']} ({len(services)} services){painpoint_str}")
            print(f"    {cat['notes']}")
            print()

            # Group by domain
            user_svcs = [s for s, d in services if d == 'user']
            sys_svcs = [s for s, d in services if d == 'system']

            if user_svcs:
                print(f"  User-session ({len(user_svcs)}):")
                for svc in user_svcs:
                    # Check if there's a LaunchAgent plist
                    plist = agents.get(svc, '')
                    plist_str = f"  <- {plist}" if plist else ""
                    print(f"    {svc}{plist_str}")

            if sys_svcs:
                print(f"  System ({len(sys_svcs)}):")
                for svc in sys_svcs:
                    plist = daemons.get(svc, '')
                    plist_str = f"  <- {plist}" if plist else ""
                    print(f"    {svc}{plist_str}")

            print()

    if not filter_app:
        print(f"═══ Summary: {total} XPC services across {len(all_cats)} app categories ═══")
        print()
        print("Automation tiers:")
        print("  Tier 1-4: AppleScript sdef, App Intents, URL schemes (covered by app-probe.py)")
        print("  Tier 5:   XPC user-session agents (this probe — accessible without root)")
        print("  Tier 6:   XPC system daemons (this probe — requires entitlements or root)")
        print()
        print("Next steps:")
        print("  - User-session services can be probed with xpcspy (Frida wrapper)")
        print("  - System services require entitlement-bearing test binaries")
        print("  - Use: dsdump + ipsw for static protocol extraction")
        print("  - Use: launchctl print gui/$(id -u) <service> for per-service detail")


if __name__ == '__main__':
    main()
