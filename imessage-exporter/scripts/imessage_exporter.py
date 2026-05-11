#!/usr/bin/env python3
"""iMessage link extractor — extract URLs with context from specific contacts.

Pure SQLite, zero external dependencies. Reads ~/Library/Messages/chat.db (read-only).

Configuration is split into two files:
  - .env           Personal paths and identity (output dir, your name, db location)
  - config.json    Contact list and extraction settings

Both are gitignored. .env.example and config.example.json are committed templates.

Usage:
    python3 imessage_export.py export
    python3 imessage_export.py export --contact "Mary Hoey"
    python3 imessage_export.py export --force
    python3 imessage_export.py links
    python3 imessage_export.py contacts
    python3 imessage_export.py status
    python3 imessage_export.py discover --min-messages 5
    python3 imessage_export.py search "query"
"""

import argparse
import json
import os
import re
import sqlite3
import sys
from datetime import datetime, timedelta, timezone
from html.parser import HTMLParser
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

# WAL-safe Apple SQLite snapshot helper. Messages.app runs continuously and
# writes constantly — snapshot is critical to catch recent messages in WAL.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "bin" / "lib"))
from apple_sqlite_snapshot import snapshot_open_persistent  # noqa: E402


# --- Constants ---

SCRIPT_DIR = Path(__file__).resolve().parent
TOOL_DIR = SCRIPT_DIR.parent
ENV_PATH = TOOL_DIR / ".env"
CONFIG_PATH = TOOL_DIR / "config.json"
STATE_PATH = SCRIPT_DIR / ".export-state.json"

DEFAULT_CHAT_DB = "~/Library/Messages/chat.db"
DEFAULT_OUTPUT_PATH = "~/imessage-export-output"
DEFAULT_MY_NAME = "Me"

# Apple epoch: 2001-01-01 00:00:00 UTC (Core Data / NSDate reference)
APPLE_EPOCH_OFFSET = 978307200

# URL regex — matches http(s) URLs in message text
URL_PATTERN = re.compile(
    r'https?://[^\s<>\"\')\]}>]+',
    re.IGNORECASE
)


# --- .env + config loading ---

def load_env(path):
    """Minimal .env parser — KEY=VALUE per line, # comments, optional quotes."""
    env = {}
    if not path.exists():
        return env
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        key, _, val = line.partition("=")
        key = key.strip()
        val = val.strip()
        # Strip matching surrounding quotes
        if len(val) >= 2 and val[0] == val[-1] and val[0] in ('"', "'"):
            val = val[1:-1]
        env[key] = val
    return env


def load_config():
    """Merge .env (paths + identity) and config.json (data)."""
    env = load_env(ENV_PATH)
    # Allow process env to override file
    for k in ("OUTPUT_PATH", "MY_NAME", "CHAT_DB"):
        if k in os.environ:
            env[k] = os.environ[k]

    if not CONFIG_PATH.exists():
        print(f"ERROR: config.json not found at {CONFIG_PATH}", file=sys.stderr)
        print("Copy config.example.json to config.json and fill in your contacts.",
              file=sys.stderr)
        sys.exit(1)

    with open(CONFIG_PATH) as f:
        data = json.load(f)

    cfg = {
        "chat_db": os.path.expanduser(env.get("CHAT_DB", DEFAULT_CHAT_DB)),
        "output_path": os.path.expanduser(env.get("OUTPUT_PATH", DEFAULT_OUTPUT_PATH)),
        "my_name": env.get("MY_NAME", DEFAULT_MY_NAME),
        "contacts": data.get("contacts", []),
        "context_messages_before": data.get("context_messages_before", 2),
        "context_messages_after": data.get("context_messages_after", 2),
        "exclude_domains": data.get("exclude_domains", []),
    }
    return cfg


def load_state():
    """Load export state (tracks last exported message date per contact)."""
    if STATE_PATH.exists():
        with open(STATE_PATH) as f:
            return json.load(f)
    return {"contacts": {}, "last_run": None}


def save_state(state):
    """Persist export state."""
    state["last_run"] = datetime.now(timezone.utc).isoformat()
    with open(STATE_PATH, "w") as f:
        json.dump(state, f, indent=2)


# --- Timestamp helpers ---

def imessage_ts_to_unix(ts):
    """Convert iMessage timestamp to Unix timestamp.

    macOS 10.13+ uses nanoseconds since 2001-01-01.
    Earlier versions use seconds since 2001-01-01.
    Auto-detect via threshold.
    """
    if ts is None or ts == 0:
        return 0.0
    # Nanoseconds if > 1 trillion
    if ts > 1e12:
        ts = ts / 1e9
    return ts + APPLE_EPOCH_OFFSET


def imessage_ts_to_iso(ts):
    """Convert iMessage timestamp to ISO 8601 string."""
    unix_ts = imessage_ts_to_unix(ts)
    if unix_ts == 0.0:
        return None
    return datetime.fromtimestamp(unix_ts, tz=timezone.utc).isoformat()


def imessage_ts_to_datetime(ts):
    """Convert iMessage timestamp to datetime object."""
    unix_ts = imessage_ts_to_unix(ts)
    if unix_ts == 0.0:
        return None
    return datetime.fromtimestamp(unix_ts, tz=timezone.utc)


def imessage_ts_to_date_str(ts):
    """Convert iMessage timestamp to YYYY-MM-DD string."""
    dt = imessage_ts_to_datetime(ts)
    if dt is None:
        return "unknown-date"
    return dt.strftime("%Y-%m-%d")


def imessage_ts_to_time_str(ts):
    """Convert iMessage timestamp to HH:MM string."""
    dt = imessage_ts_to_datetime(ts)
    if dt is None:
        return "??:??"
    return dt.strftime("%H:%M")


# --- Utility ---

def parse_since(since_str):
    """Parse a --since value into an iMessage timestamp (nanoseconds since 2001-01-01).

    Accepts: '3m' (3 months), '6m', '1y', '30d', or 'YYYY-MM-DD'.
    """
    if not since_str:
        return None

    now = datetime.now(timezone.utc)

    m = re.match(r'^(\d+)([dmy])$', since_str.lower())
    if m:
        num = int(m.group(1))
        unit = m.group(2)
        if unit == 'd':
            cutoff = now - timedelta(days=num)
        elif unit == 'm':
            cutoff = now - timedelta(days=num * 30)
        elif unit == 'y':
            cutoff = now - timedelta(days=num * 365)
        else:
            cutoff = now
    else:
        try:
            cutoff = datetime.strptime(since_str, "%Y-%m-%d").replace(tzinfo=timezone.utc)
        except ValueError:
            print(f"ERROR: Cannot parse --since '{since_str}'. Use '3m', '30d', '1y', or 'YYYY-MM-DD'.",
                  file=sys.stderr)
            sys.exit(1)

    unix_ts = cutoff.timestamp()
    apple_ts = unix_ts - APPLE_EPOCH_OFFSET
    return int(apple_ts * 1e9)  # nanoseconds


def _decode_typedstream_int(blob, pos):
    """Decode a typedstream variable-length integer.

    Apple's typedstream format uses a compact integer encoding:
    - 0x00-0x7F: literal value (0-127)
    - 0x80-0xBF: 2-byte: ((byte - 0x80) << 8) | next_byte (0-16383)
    - 0xC0-0xDF: 3-byte: ((byte - 0xC0) << 16) | (b1 << 8) | b2
    - 0xE0-0xEF: 4-byte: ((byte - 0xE0) << 24) | (b1 << 16) | (b2 << 8) | b3

    Returns (value, bytes_consumed).
    """
    fb = blob[pos]
    if fb <= 0x7F:
        return fb, 1
    elif fb <= 0xBF:
        if pos + 1 >= len(blob):
            return fb, 1
        return ((fb - 0x80) << 8) | blob[pos + 1], 2
    elif fb <= 0xDF:
        if pos + 2 >= len(blob):
            return fb, 1
        return ((fb - 0xC0) << 16) | (blob[pos+1] << 8) | blob[pos+2], 3
    elif fb <= 0xEF:
        if pos + 3 >= len(blob):
            return fb, 1
        return ((fb - 0xE0) << 24) | (blob[pos+1] << 16) | (blob[pos+2] << 8) | blob[pos+3], 4
    return fb, 1


def extract_text_from_attributed_body(blob):
    """Extract plain text from iMessage attributedBody (typedstream) blob.

    On modern macOS, message text is stored in attributedBody rather than the
    text column. This parses the typedstream NSAttributedString to get the text.

    The blob is an Apple typedstream encoding of NSMutableAttributedString.
    The plain text is stored as an NSString counted byte string within it.
    """
    if not blob:
        return None
    blob = bytes(blob)

    idx = blob.find(b'NSString')
    if idx == -1:
        return None

    search_start = idx + 8
    plus_idx = blob.find(b'+', search_start)
    if plus_idx == -1 or plus_idx > search_start + 10:
        return None

    pos = plus_idx + 1
    if pos >= len(blob):
        return None

    length, consumed = _decode_typedstream_int(blob, pos)
    pos += consumed

    if length == 0 or length > 1_000_000:
        return None

    end = pos + length
    if end > len(blob):
        end = len(blob)

    raw = blob[pos:end]

    for marker in [b'\x86\x84', b'NSDictionary', b'NSParagraphStyle',
                   b'NSFont', b'NSColor']:
        cut = raw.find(marker)
        if cut > 0:
            raw = raw[:cut]
            break

    try:
        text = raw.decode('utf-8', errors='replace')
        text = ''.join(c for c in text if c == '\n' or c == '\t' or ord(c) >= 32)
        text = text.strip()
        if text and len(text) > 1:
            return text
    except Exception:
        pass

    return None


def get_message_text(row):
    """Get message text, falling back to attributedBody extraction."""
    text = row['text']
    if text and text.strip():
        return text.strip()

    try:
        body = row['attributedBody']
    except (KeyError, IndexError):
        body = None
    if body:
        extracted = extract_text_from_attributed_body(body)
        if extracted:
            return extracted

    return None


def slugify(text):
    """Create a filesystem-safe slug from text."""
    if not text:
        return "unknown"
    slug = re.sub(r'[^\w\s-]', '', text.lower())
    slug = re.sub(r'[\s_]+', '-', slug).strip('-')
    return slug[:80] or "unknown"


def extract_urls(text):
    """Extract all URLs from a message text string."""
    if not text:
        return []
    return URL_PATTERN.findall(text)


def should_exclude_url(url, exclude_domains):
    """Check if a URL should be excluded based on domain."""
    for domain in exclude_domains:
        if domain in url:
            return True
    return False


# --- URL metadata ---

class _MetaTagParser(HTMLParser):
    """Minimal HTML parser to extract <title> and og:/meta description tags."""

    def __init__(self):
        super().__init__()
        self.title = None
        self.og_title = None
        self.og_description = None
        self.meta_description = None
        self._in_title = False
        self._title_parts = []

    def handle_starttag(self, tag, attrs):
        if tag == 'title':
            self._in_title = True
            self._title_parts = []
        elif tag == 'meta':
            d = {k.lower(): v for k, v in attrs}
            name = d.get('name', '').lower()
            prop = d.get('property', '').lower()
            content = d.get('content', '')
            if prop == 'og:title':
                self.og_title = content
            elif prop == 'og:description':
                self.og_description = content
            elif name == 'description':
                self.meta_description = content

    def handle_data(self, data):
        if self._in_title:
            self._title_parts.append(data)

    def handle_endtag(self, tag):
        if tag == 'title' and self._in_title:
            self._in_title = False
            self.title = ''.join(self._title_parts).strip()


_METADATA_CACHE_PATH = SCRIPT_DIR / ".url-metadata-cache.json"


def _load_metadata_cache():
    if _METADATA_CACHE_PATH.exists():
        try:
            with open(_METADATA_CACHE_PATH) as f:
                return json.load(f)
        except Exception:
            pass
    return {}


def _save_metadata_cache(cache):
    with open(_METADATA_CACHE_PATH, "w") as f:
        json.dump(cache, f, indent=2)


def fetch_url_metadata(url, cache=None, timeout=5):
    """Fetch title and og:description for a URL. Returns {title, description}."""
    if cache is not None and url in cache:
        return cache[url]

    result = {'title': None, 'description': None}

    try:
        req = Request(url, headers={
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
            'Accept': 'text/html',
        })
        with urlopen(req, timeout=timeout) as resp:
            ctype = resp.headers.get('Content-Type', '')
            if 'html' not in ctype.lower() and 'html' not in url.lower():
                path = url.rstrip('/').rsplit('/', 1)[-1]
                result['title'] = path
                if cache is not None:
                    cache[url] = result
                return result

            data = resp.read(32768)
            charset = 'utf-8'
            if 'charset=' in ctype:
                charset = ctype.split('charset=')[-1].split(';')[0].strip()
            html = data.decode(charset, errors='replace')

        parser = _MetaTagParser()
        parser.feed(html)

        result['title'] = parser.og_title or parser.title
        result['description'] = parser.og_description or parser.meta_description

        for k in result:
            if result[k]:
                result[k] = result[k].strip()
                result[k] = re.sub(r'\s+', ' ', result[k])

    except (URLError, HTTPError, OSError, ValueError, UnicodeDecodeError):
        pass
    except Exception:
        pass

    if cache is not None:
        cache[url] = result
    return result


def enrich_urls_with_metadata(url_list, verbose=True):
    """Fetch metadata for a list of URL dicts, adding 'title' and 'description' keys."""
    cache = _load_metadata_cache()
    total = len(url_list)
    fetched = 0
    cached = 0

    for i, entry in enumerate(url_list):
        url = entry['url']
        was_cached = url in cache
        meta = fetch_url_metadata(url, cache=cache)
        entry['title'] = meta.get('title')
        entry['description'] = meta.get('description')

        if was_cached:
            cached += 1
        else:
            fetched += 1
            if fetched % 20 == 0:
                _save_metadata_cache(cache)
                if verbose:
                    print(f"    Fetching metadata: {fetched + cached}/{total} "
                          f"({cached} cached, {fetched} fetched)")

    _save_metadata_cache(cache)
    if verbose and fetched > 0:
        print(f"    Metadata: {cached} cached, {fetched} fetched")


# --- Database access ---

def check_db_access(db_path):
    """Verify we can read the iMessage database."""
    if not os.path.exists(db_path):
        return False, (
            f"iMessage database not found at: {db_path}\n"
            "This is the default macOS location. If you're on a different system, "
            "set CHAT_DB in .env."
        )
    try:
        conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
        conn.execute("SELECT COUNT(*) FROM message")
        conn.close()
        return True, None
    except sqlite3.OperationalError as e:
        if "unable to open" in str(e) or "not authorized" in str(e):
            return False, (
                f"Cannot read iMessage database: {e}\n\n"
                "Fix: Grant Full Disk Access to your terminal app:\n"
                "  1. Open System Settings\n"
                "  2. Go to Privacy & Security > Full Disk Access\n"
                "  3. Enable your terminal app (Terminal, iTerm2, etc.)\n"
                "  4. Restart the terminal app\n"
            )
        return False, f"Database error: {e}"


def get_db_connection(db_path):
    """Open read-only WAL-safe connection to iMessage database."""
    return snapshot_open_persistent(db_path, row_factory=sqlite3.Row)


# --- Query functions ---

def get_handles_for_identifier(conn, identifier):
    """Resolve a phone number or email to handle ROWIDs."""
    rows = conn.execute(
        "SELECT ROWID, id, service FROM handle WHERE id = ?",
        (identifier,)
    ).fetchall()

    if rows:
        return [dict(r) for r in rows]

    digits = re.sub(r'\D', '', identifier)
    if len(digits) >= 7:
        rows = conn.execute(
            "SELECT ROWID, id, service FROM handle"
        ).fetchall()
        matches = []
        for r in rows:
            handle_digits = re.sub(r'\D', '', r['id'])
            if len(handle_digits) >= 7:
                if handle_digits[-10:] == digits[-10:] or handle_digits == digits:
                    matches.append(dict(r))
        return matches

    return []


def get_chats_for_handle(conn, handle_rowid):
    """Find all chat ROWIDs involving a specific handle."""
    rows = conn.execute("""
        SELECT chat_id FROM chat_handle_join WHERE handle_id = ?
    """, (handle_rowid,)).fetchall()
    return [r['chat_id'] for r in rows]


def get_messages_with_urls(conn, chat_rowids, handle_rowids, after_date=None,
                           exclude_domains=None):
    """Get messages containing URLs from specified chats and handles."""
    if not chat_rowids:
        return []

    exclude_domains = exclude_domains or []

    placeholders = ','.join('?' * len(chat_rowids))
    params = list(chat_rowids)

    date_clause = ""
    if after_date is not None:
        date_clause = "AND m.date > ?"
        params.append(after_date)

    query = f"""
        SELECT DISTINCT m.ROWID, m.text, m.attributedBody, m.date, m.is_from_me,
               m.handle_id, m.associated_message_type,
               h.id as handle_identifier
        FROM message m
        JOIN chat_message_join cmj ON cmj.message_id = m.ROWID
        LEFT JOIN handle h ON m.handle_id = h.ROWID
        WHERE cmj.chat_id IN ({placeholders})
        AND (m.text IS NOT NULL OR m.attributedBody IS NOT NULL)
        AND (m.associated_message_type IS NULL OR m.associated_message_type = 0)
        {date_clause}
        ORDER BY m.date ASC
    """

    rows = conn.execute(query, params).fetchall()

    url_messages = []
    for r in rows:
        text = get_message_text(r)
        if not text:
            continue
        urls = extract_urls(text)
        urls = [u for u in urls if not should_exclude_url(u, exclude_domains)]
        if urls:
            msg = dict(r)
            msg['_text'] = text
            msg['urls'] = urls
            url_messages.append(msg)

    return url_messages


def get_context_messages(conn, chat_rowids, target_date, before=2, after=2):
    """Get N messages before and after a target message date from the same chats."""
    if not chat_rowids:
        return []

    placeholders = ','.join('?' * len(chat_rowids))

    before_query = f"""
        SELECT DISTINCT m.ROWID, m.text, m.attributedBody, m.date, m.is_from_me,
               m.handle_id, h.id as handle_identifier
        FROM message m
        JOIN chat_message_join cmj ON cmj.message_id = m.ROWID
        LEFT JOIN handle h ON m.handle_id = h.ROWID
        WHERE cmj.chat_id IN ({placeholders})
        AND (m.text IS NOT NULL OR m.attributedBody IS NOT NULL)
        AND (m.associated_message_type IS NULL OR m.associated_message_type = 0)
        AND m.date <= ?
        ORDER BY m.date DESC
        LIMIT ?
    """
    params_before = list(chat_rowids) + [target_date, before + 1]
    rows_before = conn.execute(before_query, params_before).fetchall()

    after_query = f"""
        SELECT DISTINCT m.ROWID, m.text, m.attributedBody, m.date, m.is_from_me,
               m.handle_id, h.id as handle_identifier
        FROM message m
        JOIN chat_message_join cmj ON cmj.message_id = m.ROWID
        LEFT JOIN handle h ON m.handle_id = h.ROWID
        WHERE cmj.chat_id IN ({placeholders})
        AND (m.text IS NOT NULL OR m.attributedBody IS NOT NULL)
        AND (m.associated_message_type IS NULL OR m.associated_message_type = 0)
        AND m.date > ?
        ORDER BY m.date ASC
        LIMIT ?
    """
    params_after = list(chat_rowids) + [target_date, after]
    rows_after = conn.execute(after_query, params_after).fetchall()

    all_rows = list(reversed(rows_before)) + list(rows_after)

    seen = set()
    result = []
    for r in all_rows:
        if r['ROWID'] not in seen:
            seen.add(r['ROWID'])
            msg = dict(r)
            text = get_message_text(r)
            if text:
                msg['_text'] = text
                result.append(msg)

    return sorted(result, key=lambda x: x['date'])


def get_all_handles(conn, min_messages=0):
    """List all handles in the database with message counts."""
    query = """
        SELECT h.ROWID, h.id, h.service, COUNT(m.ROWID) as msg_count
        FROM handle h
        LEFT JOIN message m ON m.handle_id = h.ROWID
        GROUP BY h.ROWID
        HAVING msg_count >= ?
        ORDER BY msg_count DESC
    """
    rows = conn.execute(query, (min_messages,)).fetchall()
    return [dict(r) for r in rows]


def get_all_messages(conn, chat_rowids, after_date=None):
    """Get ALL messages from specified chats."""
    if not chat_rowids:
        return []

    placeholders = ','.join('?' * len(chat_rowids))
    params = list(chat_rowids)

    date_clause = ""
    if after_date is not None:
        date_clause = "AND m.date > ?"
        params.append(after_date)

    query = f"""
        SELECT DISTINCT m.ROWID, m.text, m.attributedBody, m.date, m.is_from_me,
               m.handle_id, m.associated_message_type,
               h.id as handle_identifier
        FROM message m
        JOIN chat_message_join cmj ON cmj.message_id = m.ROWID
        LEFT JOIN handle h ON m.handle_id = h.ROWID
        WHERE cmj.chat_id IN ({placeholders})
        AND (m.text IS NOT NULL OR m.attributedBody IS NOT NULL)
        AND (m.associated_message_type IS NULL OR m.associated_message_type = 0)
        {date_clause}
        ORDER BY m.date ASC
    """

    rows = conn.execute(query, params).fetchall()

    result = []
    for r in rows:
        msg = dict(r)
        text = get_message_text(r)
        if text:
            msg['_text'] = text
            result.append(msg)
    return result


def get_message_count_for_handles(conn, handle_rowids):
    """Get total message count for a set of handles."""
    if not handle_rowids:
        return 0
    placeholders = ','.join('?' * len(handle_rowids))
    row = conn.execute(
        f"SELECT COUNT(*) as cnt FROM message WHERE handle_id IN ({placeholders})",
        handle_rowids
    ).fetchone()
    return row['cnt'] if row else 0


# --- Export logic ---

def resolve_contact_handles(conn, contact):
    """Resolve all identifiers for a contact to handle ROWIDs and chat ROWIDs."""
    all_handle_rowids = []
    all_chat_rowids = []

    for identifier in contact['identifiers']:
        handles = get_handles_for_identifier(conn, identifier)
        for h in handles:
            if h['ROWID'] not in all_handle_rowids:
                all_handle_rowids.append(h['ROWID'])
            chats = get_chats_for_handle(conn, h['ROWID'])
            for c in chats:
                if c not in all_chat_rowids:
                    all_chat_rowids.append(c)

    return all_handle_rowids, all_chat_rowids


def get_sender_name(msg, contact_name, my_name, handle_rowids):
    """Determine the display name for a message sender."""
    if msg.get('is_from_me'):
        return my_name
    if msg.get('handle_id') in handle_rowids:
        return contact_name
    return msg.get('handle_identifier') or "Unknown"


def export_contact(conn, contact, cfg, state, force=False, since_ts=None, full=False, enrich=False):
    """Full export pipeline for one contact. Returns (total_count, new_count)."""
    name = contact['name']
    slug = slugify(name)
    output_path = Path(cfg['output_path'])
    exclude_domains = cfg.get('exclude_domains', [])
    my_name = cfg.get('my_name', 'Me')

    print(f"\n{'='*50}")
    print(f"Exporting: {name}" + (" (full conversation)" if full else " (links only)"))
    print(f"{'='*50}")

    handle_rowids, chat_rowids = resolve_contact_handles(conn, contact)

    if not handle_rowids:
        print(f"  WARNING: No handles found for identifiers: {contact['identifiers']}")
        print(f"  Run 'discover' to find correct identifiers.")
        return 0, 0

    if not chat_rowids:
        print(f"  WARNING: No chats found for {name}")
        return 0, 0

    print(f"  Resolved: {len(handle_rowids)} handle(s), {len(chat_rowids)} chat(s)")

    after_date = None
    contact_state = state['contacts'].get(slug, {})
    if since_ts is not None:
        after_date = since_ts
        print(f"  Since: {imessage_ts_to_iso(after_date)}")
    elif not force and contact_state.get('last_message_date'):
        after_date = contact_state['last_message_date']
        print(f"  Incremental: after {imessage_ts_to_iso(after_date)}")

    if full:
        return _export_contact_full(
            conn, contact, cfg, state, name, slug, output_path,
            exclude_domains, my_name, handle_rowids, chat_rowids,
            after_date, force, since_ts, enrich=enrich
        )
    else:
        return _export_contact_links(
            conn, contact, cfg, state, name, slug, output_path,
            exclude_domains, my_name, handle_rowids, chat_rowids,
            after_date, force, since_ts, enrich=enrich
        )


def _export_contact_full(conn, contact, cfg, state, name, slug, output_path,
                         exclude_domains, my_name, handle_rowids, chat_rowids,
                         after_date, force, since_ts, enrich=False):
    """Export full conversation + link index for one contact."""
    messages = get_all_messages(conn, chat_rowids, after_date=after_date)

    if not messages:
        print(f"  No messages found")
        return 0, 0

    url_count = 0
    all_urls = []
    for msg in messages:
        urls = extract_urls(msg.get('_text') or '')
        urls = [u for u in urls if not should_exclude_url(u, exclude_domains)]
        msg['urls'] = urls
        if urls:
            url_count += 1
            for u in urls:
                all_urls.append({
                    'url': u,
                    'date': msg['date'],
                    'date_str': imessage_ts_to_date_str(msg['date']),
                })

    print(f"  Found {len(messages)} messages ({url_count} with links)")

    contact_dir = output_path / slug
    os.makedirs(contact_dir, exist_ok=True)

    conv_md = render_full_conversation(
        name=name,
        identifiers=contact['identifiers'],
        tags=contact.get('tags', []),
        messages=messages,
        handle_rowids=handle_rowids,
        my_name=my_name,
    )

    conv_path = contact_dir / "conversation.md"
    conv_path.write_text(conv_md)
    print(f"  Written: {conv_path}")

    if all_urls:
        if enrich:
            print(f"  Enriching {len(all_urls)} URLs with metadata...")
            enrich_urls_with_metadata(all_urls)
        links_md = render_links_index(
            name=name,
            identifiers=contact['identifiers'],
            tags=contact.get('tags', []),
            urls=all_urls,
        )
        links_path = contact_dir / "links.md"
        links_path.write_text(links_md)
        print(f"  Written: {links_path}")

    last_date = messages[-1]['date']
    state['contacts'][slug] = {
        'name': name,
        'slug': slug,
        'total_messages': len(messages),
        'total_links': url_count,
        'last_message_date': last_date,
        'last_export': datetime.now(timezone.utc).isoformat(),
        'urls': all_urls,
    }

    return len(messages), len(messages)


def _export_contact_links(conn, contact, cfg, state, name, slug, output_path,
                          exclude_domains, my_name, handle_rowids, chat_rowids,
                          after_date, force, since_ts, enrich=False):
    """Export only link-containing messages with context for one contact."""
    context_before = cfg.get('context_messages_before', 2)
    context_after = cfg.get('context_messages_after', 2)
    contact_state = state['contacts'].get(slug, {})

    url_messages = get_messages_with_urls(
        conn, chat_rowids, handle_rowids,
        after_date=after_date,
        exclude_domains=exclude_domains
    )

    if not url_messages and not force:
        if after_date is not None:
            print(f"  No new links since last export")
            return contact_state.get('total_links', 0), 0

    if force:
        url_messages = get_messages_with_urls(
            conn, chat_rowids, handle_rowids,
            after_date=since_ts,
            exclude_domains=exclude_domains
        )

    new_link_count = len(url_messages)
    print(f"  Found {new_link_count} messages with links")

    link_entries = []
    existing_entries = contact_state.get('entries', [])
    if not force:
        link_entries.extend(existing_entries)

    for msg in url_messages:
        context = get_context_messages(
            conn, chat_rowids, msg['date'],
            before=context_before, after=context_after
        )
        context_lines = []
        for ctx_msg in context:
            sender = get_sender_name(ctx_msg, name, my_name, handle_rowids)
            time_str = imessage_ts_to_time_str(ctx_msg['date'])
            text = ctx_msg.get('_text') or ""
            context_lines.append({
                'sender': sender,
                'time': time_str,
                'text': text,
            })

        entry = {
            'urls': msg['urls'],
            'date': msg['date'],
            'date_str': imessage_ts_to_date_str(msg['date']),
            'context': context_lines,
        }
        link_entries.append(entry)

    seen_keys = set()
    deduped_entries = []
    for entry in link_entries:
        key = (tuple(entry['urls']), entry['date'])
        if key not in seen_keys:
            seen_keys.add(key)
            deduped_entries.append(entry)
    link_entries = sorted(deduped_entries, key=lambda x: x['date'])

    total_links = len(link_entries)
    print(f"  Total links (all time): {total_links}")

    if total_links == 0:
        print(f"  No links to export")
        return 0, 0

    url_metadata = {}
    if enrich:
        flat_urls = []
        for entry in link_entries:
            for u in entry['urls']:
                flat_urls.append({'url': u})
        print(f"  Enriching {len(flat_urls)} URLs with metadata...")
        enrich_urls_with_metadata(flat_urls)
        for item in flat_urls:
            url_metadata[item['url']] = {
                'title': item.get('title'),
                'description': item.get('description'),
            }

    contact_dir = output_path / slug
    os.makedirs(contact_dir, exist_ok=True)

    markdown = render_contact_markdown(
        name=name,
        identifiers=contact['identifiers'],
        tags=contact.get('tags', []),
        link_entries=link_entries,
        url_metadata=url_metadata,
    )

    md_path = contact_dir / "links.md"
    md_path.write_text(markdown)
    print(f"  Written: {md_path}")

    last_date = max(e['date'] for e in link_entries)
    state['contacts'][slug] = {
        'name': name,
        'slug': slug,
        'total_links': total_links,
        'last_message_date': last_date,
        'last_export': datetime.now(timezone.utc).isoformat(),
        'entries': link_entries,
    }

    return total_links, new_link_count


def render_full_conversation(name, identifiers, tags, messages, handle_rowids, my_name):
    """Render full conversation as markdown with YAML frontmatter."""
    total = len(messages)
    url_count = sum(1 for m in messages if m.get('urls'))

    first_dt = imessage_ts_to_datetime(messages[0]['date']) if messages else None
    last_dt = imessage_ts_to_datetime(messages[-1]['date']) if messages else None

    first_msg = first_dt.isoformat() if first_dt else "unknown"
    last_msg = last_dt.isoformat() if last_dt else "unknown"
    exported_at = datetime.now(timezone.utc).isoformat()

    id_list = ', '.join(f'"{i}"' for i in identifiers)
    tag_list = ', '.join(['imessage'] + tags)

    lines = [
        "---",
        f'title: "Conversation with {name}"',
        f'contact: "{name}"',
        f"identifiers: [{id_list}]",
        "source: imessage",
        f"total_messages: {total}",
        f"total_links: {url_count}",
        f"first_message: {first_msg}",
        f"last_message: {last_msg}",
        f"exported_at: {exported_at}",
        f"tags: [{tag_list}]",
        "---",
        "",
        f"# Conversation with {name}",
        "",
        f"**{total} messages** ({url_count} with links)",
    ]

    current_date = None
    for msg in messages:
        date_str = imessage_ts_to_date_str(msg['date'])
        if date_str != current_date:
            current_date = date_str
            lines.append("")
            lines.append(f"## {date_str}")
            lines.append("")

        sender = get_sender_name(msg, name, my_name, handle_rowids)
        time_str = imessage_ts_to_time_str(msg['date'])
        text = msg.get('_text') or ""

        has_urls = bool(msg.get('urls'))
        if has_urls:
            lines.append(f"**{sender}** ({time_str}): {text} 🔗")
        else:
            lines.append(f"**{sender}** ({time_str}): {text}")

    lines.append("")
    return "\n".join(lines)


def render_links_index(name, identifiers, tags, urls):
    """Render a links-only index extracted from a full conversation."""
    exported_at = datetime.now(timezone.utc).isoformat()
    id_list = ', '.join(f'"{i}"' for i in identifiers)
    tag_list = ', '.join(['imessage'] + tags)

    lines = [
        "---",
        f'title: "Links shared by {name}"',
        f'contact: "{name}"',
        f"identifiers: [{id_list}]",
        "source: imessage",
        f"total_links: {len(urls)}",
        f"exported_at: {exported_at}",
        f"tags: [{tag_list}]",
        "---",
        "",
        f"# Links from {name}",
        "",
    ]

    current_date = None
    for entry in urls:
        if entry['date_str'] != current_date:
            current_date = entry['date_str']
            lines.append(f"## {current_date}")
            lines.append("")
        title = entry.get('title')
        desc = entry.get('description')
        if title:
            lines.append(f"- [{title}]({entry['url']})")
        else:
            lines.append(f"- {entry['url']}")
        if desc:
            lines.append(f"  > {desc}")
    lines.append("")
    return "\n".join(lines)


def render_contact_markdown(name, identifiers, tags, link_entries, url_metadata=None):
    """Render a contact's links as markdown with YAML frontmatter."""
    url_metadata = url_metadata or {}
    total = len(link_entries)

    first_dt = imessage_ts_to_datetime(link_entries[0]['date']) if link_entries else None
    last_dt = imessage_ts_to_datetime(link_entries[-1]['date']) if link_entries else None

    first_link = first_dt.isoformat() if first_dt else "unknown"
    last_link = last_dt.isoformat() if last_dt else "unknown"
    exported_at = datetime.now(timezone.utc).isoformat()

    id_list = ', '.join(f'"{i}"' for i in identifiers)
    tag_list = ', '.join(['imessage'] + tags)

    lines = [
        "---",
        f'title: "Links shared by {name}"',
        f'contact: "{name}"',
        f"identifiers: [{id_list}]",
        "source: imessage",
        f"total_links: {total}",
        f"first_link: {first_link}",
        f"last_link: {last_link}",
        f"exported_at: {exported_at}",
        f"tags: [{tag_list}]",
        "---",
        "",
        f"# Links shared by {name}",
    ]

    current_date = None
    for entry in link_entries:
        date_str = entry['date_str']
        if date_str != current_date:
            current_date = date_str
            lines.append("")
            lines.append(f"## {date_str}")

        for url in entry['urls']:
            meta = url_metadata.get(url, {})
            title = meta.get('title')
            desc = meta.get('description')

            lines.append("")
            if title:
                lines.append(f"### [{title}]({url})")
            else:
                lines.append(f"### {url}")
            if desc:
                lines.append(f"*{desc}*")
            lines.append("")

            for ctx in entry['context']:
                lines.append(
                    f"> **{ctx['sender']}** ({ctx['time']}): {ctx['text']}"
                )

            lines.append("")
            lines.append("---")

    lines.append("")
    return "\n".join(lines)


def build_all_links_index(cfg, state):
    """Build cross-contact _all-links.md index."""
    output_path = Path(cfg['output_path'])
    all_entries = []

    for slug, contact_state in state.get('contacts', {}).items():
        name = contact_state.get('name', slug)
        for entry in contact_state.get('entries', []):
            for url in entry.get('urls', []):
                all_entries.append({
                    'url': url,
                    'contact': name,
                    'date': entry['date'],
                    'date_str': entry['date_str'],
                })

    if not all_entries:
        return

    all_entries.sort(key=lambda x: x['date'], reverse=True)
    exported_at = datetime.now(timezone.utc).isoformat()

    lines = [
        "---",
        'title: "All iMessage Links"',
        "source: imessage",
        f"total_links: {len(all_entries)}",
        f"exported_at: {exported_at}",
        "tags: [imessage, index]",
        "---",
        "",
        "# All iMessage Links",
        "",
        f"Total: {len(all_entries)} links from {len(state.get('contacts', {}))} contacts",
        "",
    ]

    current_date = None
    for entry in all_entries:
        if entry['date_str'] != current_date:
            current_date = entry['date_str']
            lines.append(f"## {current_date}")
            lines.append("")

        lines.append(f"- [{entry['url']}]({entry['url']}) — **{entry['contact']}**")

    lines.append("")

    index_path = output_path / "_all-links.md"
    index_path.write_text("\n".join(lines))
    print(f"\nAll-links index: {index_path}")


def build_manifest(cfg, state):
    """Write a JSON manifest of all exports."""
    output_path = Path(cfg['output_path'])
    os.makedirs(output_path, exist_ok=True)

    manifest_contacts = {}
    for slug, cs in state.get('contacts', {}).items():
        manifest_contacts[slug] = {
            'name': cs.get('name'),
            'total_links': cs.get('total_links', 0),
            'last_export': cs.get('last_export'),
        }

    manifest = {
        "generated": datetime.now(timezone.utc).isoformat(),
        "output_path": cfg['output_path'],
        "total_contacts": len(manifest_contacts),
        "total_links": sum(c['total_links'] for c in manifest_contacts.values()),
        "contacts": manifest_contacts,
    }

    manifest_path = output_path / "_manifest.json"
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)
    print(f"Manifest: {manifest_path}")


# --- CLI commands ---

def cmd_export(args, cfg):
    """Export links from configured contacts."""
    ok, err = check_db_access(cfg['chat_db'])
    if not ok:
        print(f"ERROR: {err}", file=sys.stderr)
        sys.exit(1)

    contacts = cfg.get('contacts', [])
    if not contacts:
        print("No contacts configured in config.json.")
        print("Run 'discover' to find contact identifiers, then add them to config.json.")
        return

    if args.contact:
        contacts = [c for c in contacts if c['name'].lower() == args.contact.lower()]
        if not contacts:
            print(f"Contact '{args.contact}' not found in config.json")
            print("Configured contacts:")
            for c in cfg.get('contacts', []):
                print(f"  - {c['name']}")
            return

    conn = get_db_connection(cfg['chat_db'])
    state = load_state()

    since_ts = parse_since(getattr(args, 'since', None))

    total_links = 0
    total_new = 0

    for contact in contacts:
        try:
            links, new = export_contact(conn, contact, cfg, state,
                                        force=args.force, since_ts=since_ts,
                                        full=args.full, enrich=args.enrich)
            total_links += links
            total_new += new
        except Exception as e:
            print(f"  ERROR exporting '{contact['name']}': {e}", file=sys.stderr)
            import traceback
            traceback.print_exc()

    conn.close()
    save_state(state)
    build_all_links_index(cfg, state)
    build_manifest(cfg, state)

    print(f"\n{'='*50}")
    print(f"Total: {total_links} links ({total_new} new)")
    print(f"State saved: {STATE_PATH}")


def cmd_links(args, cfg):
    """Show extracted links summary."""
    state = load_state()

    if not state.get('contacts'):
        print("No links exported yet. Run 'export' first.")
        return

    for slug, cs in state['contacts'].items():
        name = cs.get('name', slug)
        total = cs.get('total_links', 0)
        last = cs.get('last_export', 'never')
        print(f"\n{name}: {total} links (last export: {last})")

        entries = cs.get('entries', [])
        recent = entries[-5:] if len(entries) > 5 else entries
        for entry in reversed(recent):
            date_str = entry.get('date_str', '?')
            for url in entry.get('urls', []):
                print(f"  [{date_str}] {url}")


def cmd_contacts(args, cfg):
    """List configured contacts with stats from database."""
    contacts = cfg.get('contacts', [])
    if not contacts:
        print("No contacts configured. Add contacts to config.json.")
        print("Run 'discover' to find contact identifiers.")
        return

    ok, err = check_db_access(cfg['chat_db'])
    if not ok:
        print(f"ERROR: {err}", file=sys.stderr)
        sys.exit(1)

    conn = get_db_connection(cfg['chat_db'])

    print(f"\n{'Contact':<25} {'Handles':>8} {'Messages':>10} {'Tags'}")
    print("-" * 65)

    for contact in contacts:
        handle_rowids, _ = resolve_contact_handles(conn, contact)
        msg_count = get_message_count_for_handles(conn, handle_rowids)
        tags = ', '.join(contact.get('tags', []))
        print(f"  {contact['name']:<23} {len(handle_rowids):>8} {msg_count:>10}  {tags}")

    conn.close()


def cmd_status(args, cfg):
    """Show export state."""
    state = load_state()
    print(f"Last run: {state.get('last_run', 'never')}")

    contacts = state.get('contacts', {})
    total_links = sum(cs.get('total_links', 0) for cs in contacts.values())
    print(f"Contacts: {len(contacts)}")
    print(f"Total links: {total_links}")

    if contacts:
        print(f"\n{'Contact':<25} {'Links':>6} {'Last export'}")
        print("-" * 55)
        for slug, cs in contacts.items():
            name = cs.get('name', slug)
            total = cs.get('total_links', 0)
            last = cs.get('last_export', 'never')
            if last and last != 'never':
                last = last[:19]
            print(f"  {name:<23} {total:>6}  {last}")


def cmd_discover(args, cfg):
    """List all handles in the iMessage database."""
    ok, err = check_db_access(cfg['chat_db'])
    if not ok:
        print(f"ERROR: {err}", file=sys.stderr)
        sys.exit(1)

    conn = get_db_connection(cfg['chat_db'])
    handles = get_all_handles(conn, min_messages=args.min_messages)
    conn.close()

    if not handles:
        print(f"No handles found with >= {args.min_messages} messages")
        return

    print(f"\n{'Handle':<40} {'Service':>10} {'Messages':>10}")
    print("-" * 65)

    for h in handles:
        print(f"  {h['id']:<38} {h['service']:>10} {h['msg_count']:>10}")

    print(f"\nTotal: {len(handles)} handles")
    print("\nTo add a contact, edit config.json:")
    print('  {"name": "Name", "identifiers": ["+1234567890"], "tags": ["tag"]}')


def cmd_search(args, cfg):
    """Full-text search across extracted link contexts."""
    state = load_state()
    query = args.query.lower()

    if not state.get('contacts'):
        print("No links exported yet. Run 'export' first.")
        return

    results = []
    for slug, cs in state['contacts'].items():
        name = cs.get('name', slug)
        for entry in cs.get('entries', []):
            for url in entry.get('urls', []):
                if query in url.lower():
                    results.append((name, entry, url))
                    continue
            for ctx in entry.get('context', []):
                if query in ctx.get('text', '').lower():
                    for url in entry.get('urls', []):
                        results.append((name, entry, url))
                    break

    if not results:
        print(f"No results for '{args.query}'")
        return

    print(f"\nFound {len(results)} result(s) for '{args.query}':\n")
    for name, entry, url in results:
        date_str = entry.get('date_str', '?')
        print(f"  [{date_str}] {name}: {url}")
        for ctx in entry.get('context', []):
            text = ctx.get('text', '')
            if query in text.lower():
                print(f"    > {ctx['sender']} ({ctx['time']}): {text[:120]}")
        print()


# --- Main ---

def main():
    parser = argparse.ArgumentParser(description="iMessage link extractor")
    sub = parser.add_subparsers(dest="command")

    p_export = sub.add_parser("export", help="Export links from configured contacts")
    p_export.add_argument("--contact", type=str, help="Export one contact only")
    p_export.add_argument("--force", action="store_true", help="Re-export everything")
    p_export.add_argument("--full", action="store_true",
                          help="Export full conversation text (not just links)")
    p_export.add_argument("--since", type=str,
                          help="Only export after this date (YYYY-MM-DD or '3m' for 3 months)")
    p_export.add_argument("--enrich", action="store_true",
                          help="Fetch og:title and og:description for each URL")

    sub.add_parser("links", help="Show extracted links summary")
    sub.add_parser("contacts", help="List configured contacts with stats")
    sub.add_parser("status", help="Show export state")

    p_discover = sub.add_parser("discover", help="List all handles in database")
    p_discover.add_argument("--min-messages", type=int, default=0,
                            help="Only show handles with N+ messages")

    p_search = sub.add_parser("search", help="Search across link contexts")
    p_search.add_argument("query", type=str, help="Search term")

    args = parser.parse_args()
    cfg = load_config()

    if args.command is None:
        parser.print_help()
        return

    if args.command == "export":
        cmd_export(args, cfg)
    elif args.command == "links":
        cmd_links(args, cfg)
    elif args.command == "contacts":
        cmd_contacts(args, cfg)
    elif args.command == "status":
        cmd_status(args, cfg)
    elif args.command == "discover":
        cmd_discover(args, cfg)
    elif args.command == "search":
        cmd_search(args, cfg)


if __name__ == "__main__":
    main()
