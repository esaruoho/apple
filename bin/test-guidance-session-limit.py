#!/usr/bin/env python3
from datetime import datetime
from importlib.machinery import SourceFileLoader
from pathlib import Path
from zoneinfo import ZoneInfo


guidance = SourceFileLoader(
    "guidance_mod",
    str(Path(__file__).with_name("guidance")),
).load_module()


def assert_true(value, message):
    if not value:
        raise AssertionError(message)


def test_weekly_limit_with_dated_reset():
    text = "You've hit your weekly limit · resets Jul 11 at 7am (Europe/Helsinki)"
    info = guidance.session_limit_info(text, {"recap": []})

    assert_true(info["limited"] is True, info)
    assert_true(info["reset_epoch"] > 0, info)
    assert_true(info["reset_text"] == "Jul 11 07:00", info)

    reset = datetime.fromtimestamp(
        info["reset_epoch"],
        ZoneInfo("Europe/Helsinki"),
    )
    assert_true(reset.month == 7, reset)
    assert_true(reset.day == 11, reset)
    assert_true(reset.hour == 7, reset)
    assert_true(reset.minute == 0, reset)


def test_session_limit_without_date_still_matches():
    text = "You've hit your session limit · resets 1am (Europe/Helsinki)"
    info = guidance.session_limit_info(text, {"recap": []})

    assert_true(info["limited"] is True, info)
    assert_true(info["reset_epoch"] > 0, info)
    assert_true(info["reset_text"] == "01:00", info)


if __name__ == "__main__":
    test_weekly_limit_with_dated_reset()
    test_session_limit_without_date_still_matches()
    print("ok")
