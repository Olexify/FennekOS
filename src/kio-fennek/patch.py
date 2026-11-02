#!/usr/bin/python3
"""Fennek OS change to KIO (what opens files in every KDE program), applied to Fedora's source during the image build
(build.sh): an .exe always goes to its app, fennek-run-exe, which asks or sandboxes. Stock KIO treats one with the
executable flag as a native program, and every .exe on an NTFS, exFAT or FAT drive has that flag, so it fails there; and
it refuses them outright when opened from Start search, the Search window or Launch.

If a new KIO changed the piece looked for, the build stops here with the piece named.

  patch.py KIO_SOURCE_DIR
"""
import pathlib, sys

p = pathlib.Path(sys.argv[1]) / "src" / "gui" / "openurljob.cpp"
t = p.read_text(encoding="utf-8")
old = """    // Binaries (e.g. /usr/bin/{konsole,ls}) and .exe files
    if (isBinary(mimeType)) {
"""
new = """    // Fennek OS: a local .exe goes to its app (fennek-run-exe), which asks or sandboxes
    if (m_url.isLocalFile()
        && (mimeType.inherits(QStringLiteral("application/x-ms-dos-executable")) || mimeType.inherits(QStringLiteral("application/vnd.microsoft.portable-executable")))) {
        openInPreferredApp();
        return;
    }

""" + old
assert t.count(old) == 1, f"openurljob.cpp: expected 1 of: {old[:80]!r}"
p.write_text(t.replace(old, new), encoding="utf-8")
