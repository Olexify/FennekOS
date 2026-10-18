#!/usr/bin/env python3
"""Fennek OS version of a build: the newest milestone in system_files/usr/share/fennek/milestones.json, and as patch
number the days since that milestone came out (1.0.0 on release day, 1.0.12 twelve days later; a new milestone
starts again at 0). Names belong to milestones only; fixes and security updates are unnamed patches.

  python3 tools/fennek-version.py              -> 1.0.12
  python3 tools/fennek-version.py --selftest
"""
import datetime, json, pathlib, sys

FILE = pathlib.Path(__file__).resolve().parent.parent / "system_files/usr/share/fennek/milestones.json"


def version(milestones, today):
    m = milestones[0]
    return f'{m["version"]}.{max(0, (today - datetime.date.fromisoformat(m["date"])).days)}'


if __name__ == "__main__":
    if sys.argv[1:] == ["--selftest"]:
        ms = [{"version": "1.1", "date": "2026-11-01"}, {"version": "1.0", "date": "2026-10-18"}]
        assert version(ms, datetime.date(2026, 11, 1)) == "1.1.0"
        assert version(ms, datetime.date(2026, 11, 13)) == "1.1.12"
        assert version(ms, datetime.date(2026, 10, 30)) == "1.1.0", "never negative"
        m = json.loads(FILE.read_text())
        assert all({"version", "name", "tagline", "date", "highlights"} <= set(x) for x in m), "milestone fields"
        print("ok")
    else:
        print(version(json.loads(FILE.read_text()), datetime.datetime.now(datetime.timezone.utc).date()))
