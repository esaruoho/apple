import importlib.machinery
import json
import os
import sqlite3
import tempfile
import time
import pytest

# Load apple/bin/sessions as a module
loader = importlib.machinery.SourceFileLoader("apple_sessions", "/Users/esaruoho/work/apple/bin/sessions")
apple_sessions = loader.load_module()

# Load ~/work/sessions/sessions.py as a module
loader_repo = importlib.machinery.SourceFileLoader("repo_sessions", "/Users/esaruoho/work/sessions/sessions.py")
repo_sessions = loader_repo.load_module()


def _make_proto_user_payload(text):
    def enc_varint(v):
        out = bytearray()
        while v > 0x7F:
            out.append((v & 0x7F) | 0x80)
            v >>= 7
        out.append(v & 0x7F)
        return bytes(out)

    def enc_len_delim(tag, data):
        tag_b = enc_varint((tag << 3) | 2)
        return tag_b + enc_varint(len(data)) + data

    user_bytes = text.encode("utf-8")
    tag19 = enc_len_delim(2, user_bytes)
    return enc_len_delim(19, tag19)


def _make_proto_asst_payload(text):
    def enc_varint(v):
        out = bytearray()
        while v > 0x7F:
            out.append((v & 0x7F) | 0x80)
            v >>= 7
        out.append(v & 0x7F)
        return bytes(out)

    def enc_len_delim(tag, data):
        tag_b = enc_varint((tag << 3) | 2)
        return tag_b + enc_varint(len(data)) + data

    asst_bytes = text.encode("utf-8")
    tag20 = enc_len_delim(1, asst_bytes)
    return enc_len_delim(20, tag20)


@pytest.fixture
def mock_antigravity_env(monkeypatch, tmp_path):
    agy_dir = tmp_path / "antigravity-cli"
    agy_dir.mkdir(parents=True)
    conv_dir = agy_dir / "conversations"
    conv_dir.mkdir(parents=True)

    sum_db = agy_dir / "conversation_summaries.db"
    con = sqlite3.connect(str(sum_db))
    con.execute("""CREATE TABLE conversation_summaries (
        conversation_id text PRIMARY KEY,
        title text NOT NULL DEFAULT '',
        preview text NOT NULL DEFAULT '',
        step_count integer NOT NULL DEFAULT 0,
        last_modified_time datetime NOT NULL,
        workspace_uris text NOT NULL
    )""")

    folder_match = "/tmp/test-workspace-alpha"
    folder_other = "/tmp/test-workspace-beta"

    # Row 1: matches alpha
    con.execute(
        """INSERT INTO conversation_summaries VALUES (?, ?, ?, ?, ?, ?)""",
        (
            "11111111-2222-3333-4444-555555555555",
            "Alpha Investigation",
            "first prompt preview",
            10,
            "2026-11-09 10:00:00+00:00",
            json.dumps([f"file://{folder_match}"]),
        ),
    )
    # Row 2: matches beta
    con.execute(
        """INSERT INTO conversation_summaries VALUES (?, ?, ?, ?, ?, ?)""",
        (
            "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
            "Beta Project Task",
            "beta prompt preview",
            5,
            "2026-11-09 09:00:00+00:00",
            json.dumps([f"file://{folder_other}"]),
        ),
    )
    con.commit()
    con.close()

    # Create conv db for row 1
    conv_db_1 = conv_dir / "11111111-2222-3333-4444-555555555555.db"
    c1 = sqlite3.connect(str(conv_db_1))
    c1.execute("CREATE TABLE steps (idx integer PRIMARY KEY, step_type integer, step_payload blob)")
    user_p1 = _make_proto_user_payload("What is the state of Alpha?")
    asst_p1 = _make_proto_asst_payload("Alpha is running optimally.")
    user_p2 = _make_proto_user_payload("Proceed with phase two.")
    asst_p2 = _make_proto_asst_payload("Phase two initiated.")
    c1.execute("INSERT INTO steps VALUES (?, ?, ?)", (0, 14, user_p1))
    c1.execute("INSERT INTO steps VALUES (?, ?, ?)", (1, 15, asst_p1))
    c1.execute("INSERT INTO steps VALUES (?, ?, ?)", (2, 14, user_p2))
    c1.execute("INSERT INTO steps VALUES (?, ?, ?)", (3, 15, asst_p2))
    c1.commit()
    c1.close()

    # Monkeypatch ANTIGRAVITY_DIRS in both modules
    monkeypatch.setattr(apple_sessions, "ANTIGRAVITY_DIRS", [str(agy_dir)])
    monkeypatch.setattr(repo_sessions, "ANTIGRAVITY_DIRS", [str(agy_dir)])

    return {
        "folder_match": folder_match,
        "folder_other": folder_other,
        "cid1": "11111111-2222-3333-4444-555555555555",
        "cid2": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
    }


def test_provider_glyphs():
    assert apple_sessions.PROVIDER_GLYPH["antigravity"] == "A"
    assert apple_sessions.PROVIDER_GLYPH["agy"] == "A"
    assert repo_sessions.PROVIDER_GLYPH["antigravity"] == "A"
    assert repo_sessions.PROVIDER_GLYPH["agy"] == "A"


def test_resume_and_new_argv():
    for mod in (apple_sessions, repo_sessions):
        r_cmd = mod.resume_argv("antigravity", "fake-uuid-123")
        assert r_cmd[-2:] == ["--conversation", "fake-uuid-123"]
        assert "--dangerously-skip-permissions" in r_cmd
        assert any(r_cmd[0].endswith(x) for x in ("agy", "antigravity"))

        r_cmd_agy = mod.resume_argv("agy", "fake-uuid-123")
        assert r_cmd_agy[-2:] == ["--conversation", "fake-uuid-123"]

        n_cmd = mod.new_argv("antigravity")
        assert "--dangerously-skip-permissions" in n_cmd
        assert any(n_cmd[0].endswith(x) for x in ("agy", "antigravity"))


def test_list_antigravity_scoped(mock_antigravity_env):
    folder = mock_antigravity_env["folder_match"]
    for mod in (apple_sessions, repo_sessions):
        rows = mod.list_antigravity(folder)
        assert len(rows) == 1
        r = rows[0]
        assert r.provider == "antigravity"
        assert r.uuid == mock_antigravity_env["cid1"]
        assert r.title == "Alpha Investigation"

        # load meta
        mod.load_antigravity_meta(r)
        assert r.turns == 2
        assert "What is the state of Alpha?" in r.snippet


def test_render_session_antigravity(mock_antigravity_env):
    folder = mock_antigravity_env["folder_match"]
    for mod in (apple_sessions, repo_sessions):
        rows = mod.list_antigravity(folder)
        assert len(rows) == 1
        rendered = mod.render_session(rows[0])
        assert "## USER\nWhat is the state of Alpha?" in rendered
        assert "## ASSISTANT\nAlpha is running optimally." in rendered
        assert "## USER\nProceed with phase two." in rendered
        assert "## ASSISTANT\nPhase two initiated." in rendered


def test_live_merlib_dump_antigravity_session():
    """Verify against real local machine state if ~/.gemini/antigravity-cli exists."""
    real_db = os.path.expanduser("~/.gemini/antigravity-cli/conversation_summaries.db")
    if not os.path.isfile(real_db):
        pytest.skip("No real Antigravity db on this machine")

    rows = apple_sessions.list_antigravity("/Users/esaruoho/work/merlib-dump")
    assert len(rows) >= 1
    target = next((r for r in rows if r.uuid == "fe14ca56-5978-4540-90ae-8c529d83727a"), None)
    assert target is not None
    assert target.title == "AI Skills Capabilities Inquiry"

    apple_sessions.load_antigravity_meta(target)
    assert target.turns == 30
    assert "are you able to use skills" in target.snippet

    rendered = apple_sessions.render_session(target)
    assert "## USER\nare you able to use skills" in rendered
    assert "## ASSISTANT" in rendered
