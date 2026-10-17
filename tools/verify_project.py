#!/usr/bin/env python3
"""
Static verifier for the ShiGuang Xcode project.
Run this BEFORE pushing to GitHub to catch issues that only Xcode would surface.
"""
from __future__ import annotations
import os
import re
import sys
import plistlib
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML not installed. pip install pyyaml", file=sys.stderr)
    sys.exit(2)

ROOT = Path(__file__).resolve().parent.parent
SCHEME = "ShiGuang"
PBXPROJ = ROOT / f"{SCHEME}.xcodeproj" / "project.pbxproj"
XCSCHEME = ROOT / f"{SCHEME}.xcodeproj" / "xcshareddata" / "xcschemes" / f"{SCHEME}.xcscheme"
INFO_PLIST = ROOT / SCHEME / "Info.plist"
WORKFLOW = ROOT / ".github" / "workflows" / "build-ipa.yml"

errors: list[str] = []
warnings: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)


def warn(msg: str) -> None:
    warnings.append(msg)


def check_balance(text: str, name: str) -> None:
    pairs = [("{", "}"), ("(", ")")]
    for open_c, close_c in pairs:
        if text.count(open_c) != text.count(close_c):
            err(f"{name}: unbalanced {open_c}{close_c} ({text.count(open_c)} vs {text.count(close_c)})")


def main() -> int:
    # 1. pbxproj exists & balanced
    if not PBXPROJ.exists():
        err(f"missing: {PBXPROJ}")
        return report()
    text = PBXPROJ.read_text(encoding="utf-8")
    check_balance(text, "project.pbxproj")
    if "rootObject" not in text:
        err("project.pbxproj: rootObject not found")

    # 2. UUID format check (24 hex chars)
    uuids = set(re.findall(r"\b[0-9A-Fa-f]{24}\b", text))
    if not uuids:
        err("no 24-char hex UUIDs found in pbxproj")

    # All UUID-like tokens that are NOT 24 chars or contain non-hex
    suspect = re.findall(r"\b[0-9A-Z]{20,28}\b", text)
    for tok in set(suspect):
        if len(tok) != 24 or not all(c in "0123456789ABCDEF" for c in tok):
            err(f"suspicious UUID: {tok} (len={len(tok)})")

    # 3. Referenced UUIDs all defined; defined UUIDs all referenced
    referenced = set()
    for m in re.finditer(r"\b([0-9A-F]{24})\b", text):
        referenced.add(m.group(1))
    # crude: a UUID is "defined" if it appears right before " /*"
    defined = set()
    for m in re.finditer(r"^\s*([0-9A-F]{24}) /\*", text, re.M):
        defined.add(m.group(1))
    # root group has no comment: `<id> = {` on its own line with no marker
    for m in re.finditer(r"^\s*([0-9A-F]{24}) = \{\s*$", text, re.M):
        defined.add(m.group(1))
    # cross-check: anything in `referenced` not in `defined` and not the rootObject
    undef = referenced - defined
    if undef:
        for u in sorted(undef)[:5]:
            err(f"referenced but not defined: {u}")
    orphans = defined - referenced
    # a definition always references itself, so filter self-hits
    real_orphans = set()
    for u in orphans:
        # count occurrences: definition + at least one reference
        occurrences = len(re.findall(rf"\b{re.escape(u)}\b", text))
        if occurrences < 2:
            real_orphans.add(u)
    for u in sorted(real_orphans)[:5]:
        warn(f"orphan UUID (defined but never referenced): {u}")

    # 4. All PBXFileReference paths exist on disk
    file_refs = re.findall(
        r"isa = PBXFileReference;[^}]*?path = ([^;]+);[^}]*?sourceTree = \"<group>\"",
        text,
    )
    # Build a quick path index from disk (files AND directories)
    all_entries = {p.name for p in (ROOT / SCHEME).rglob("*")}
    for ref in file_refs:
        ref = ref.strip().strip('"')
        # Skip variables / build products
        if "$" in ref or ref.endswith(".app"):
            continue
        # Xcode paths may be just the filename (relative to group)
        name = Path(ref).name
        if name not in all_entries:
            err(f"PBXFileReference path not on disk: {ref}")

    # 5. Every .swift on disk is in PBXSourcesBuildPhase; list has no ghosts
    sources_match = re.search(
        r"isa = PBXSourcesBuildPhase;.*?files = \((.*?)\);",
        text,
        re.S,
    )
    if not sources_match:
        err("PBXSourcesBuildPhase not found")
    else:
        sources_block = sources_match.group(1)
        build_file_ids = re.findall(r"([0-9A-F]{24}) /\* ([^*]+) in Sources \*/", sources_block)
        listed_swift = {name for _, name in build_file_ids}
        on_disk_swift = {p.name for p in (ROOT / SCHEME).rglob("*.swift")}
        missing_from_build = on_disk_swift - listed_swift
        ghost_in_build = listed_swift - on_disk_swift
        for f in sorted(missing_from_build):
            err(f".swift file on disk NOT in build phase: {f}")
        for f in sorted(ghost_in_build):
            err(f".swift file in build phase but NOT on disk: {f}")
        if len(listed_swift) != len(on_disk_swift):
            err(f"swift count mismatch: build phase has {len(listed_swift)}, disk has {len(on_disk_swift)}")

    # 6. Scheme BlueprintIdentifier matches a PBXNativeTarget
    if not XCSCHEME.exists():
        err(f"missing: {XCSCHEME}")
    else:
        scheme_text = XCSCHEME.read_text(encoding="utf-8")
        m = re.search(r'BlueprintIdentifier\s*=\s*"([0-9A-F]{24})"', scheme_text)
        if not m:
            err("xcscheme: BlueprintIdentifier missing or malformed")
        else:
            bp_id = m.group(1)
            # PBXNativeTarget id: appears as `<id> /* ShiGuang */ = { isa = PBXNativeTarget;`
            if not re.search(
                rf"^\s*{re.escape(bp_id)} /\* {re.escape(SCHEME)} \*/ = \{{\s*isa = PBXNativeTarget",
                text,
                re.M,
            ):
                err(f"scheme BlueprintIdentifier {bp_id} does not match PBXNativeTarget for {SCHEME}")

    # 7. Info.plist parses and has required keys
    if not INFO_PLIST.exists():
        err(f"missing: {INFO_PLIST}")
    else:
        try:
            with INFO_PLIST.open("rb") as f:
                plist = plistlib.load(f)
            required = [
                "CFBundleDisplayName",
                "CFBundleExecutable",
                "CFBundleIdentifier",
                "CFBundleShortVersionString",
                "CFBundleVersion",
                "UIRequiredDeviceCapabilities",
            ]
            for k in required:
                if k not in plist:
                    err(f"Info.plist missing key: {k}")
            caps = plist.get("UIRequiredDeviceCapabilities", [])
            if "arm64" not in caps:
                err("Info.plist: UIRequiredDeviceCapabilities must contain arm64")
            if "armv7" in caps:
                err("Info.plist: armv7 not allowed (32-bit legacy)")
        except Exception as e:
            err(f"Info.plist parse error: {e}")

    # 8. Workflow YAML parses, has no tabs
    if not WORKFLOW.exists():
        err(f"missing: {WORKFLOW}")
    else:
        wf_text = WORKFLOW.read_text(encoding="utf-8")
        for i, line in enumerate(wf_text.splitlines(), 1):
            if "\t" in line:
                err(f"workflow line {i} contains TAB (YAML forbids tabs)")
        try:
            yaml.safe_load(wf_text)
        except yaml.YAMLError as e:
            err(f"workflow YAML parse error: {e}")

    # 9. ExportOptions.plist parses
    eo = ROOT / "ExportOptions.plist"
    if eo.exists():
        try:
            with eo.open("rb") as f:
                plistlib.load(f)
        except Exception as e:
            err(f"ExportOptions.plist parse error: {e}")

    return report()


def report() -> int:
    print("=" * 60)
    print(f"warnings: {len(warnings)}")
    for w in warnings:
        print(f"  [warn] {w}")
    print(f"errors:   {len(errors)}")
    for e in errors:
        print(f"  [FAIL] {e}")
    print("=" * 60)
    if errors:
        print("RESULT: FAIL")
        return 1
    print("RESULT: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
