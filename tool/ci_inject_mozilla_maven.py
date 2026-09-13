#!/usr/bin/env python3
"""Thêm maven.mozilla.org vào settings.gradle / settings.gradle.kts sau flutter create."""
from pathlib import Path
import sys

def patch_kts(p: Path) -> bool:
    t = p.read_text(encoding="utf-8")
    if "maven.mozilla.org" in t:
        print("mozilla maven already present (kts)")
        return True
    needle = "dependencyResolutionManagement"
    if needle not in t:
        # fallback: repositories block
        if "repositories {" in t and "maven.mozilla.org" not in t:
            t = t.replace(
                "repositories {",
                'repositories {\n        maven { url = uri("https://maven.mozilla.org/maven2/") }',
                1,
            )
            p.write_text(t, encoding="utf-8")
            print("patched repositories (kts)")
            return True
        print("WARN: no dependencyResolutionManagement in", p)
        return False
    # Insert inside repositories { under dependencyResolutionManagement
    idx = t.find(needle)
    repo = t.find("repositories {", idx)
    if repo < 0:
        return False
    insert_at = repo + len("repositories {")
    snippet = '\n        maven { url = uri("https://maven.mozilla.org/maven2/") }'
    t = t[:insert_at] + snippet + t[insert_at:]
    p.write_text(t, encoding="utf-8")
    print("Patched", p)
    return True

def patch_groovy(p: Path) -> bool:
    t = p.read_text(encoding="utf-8")
    if "maven.mozilla.org" in t:
        print("mozilla maven already present (groovy)")
        return True
    if "repositories {" in t:
        t = t.replace(
            "repositories {",
            "repositories {\n        maven { url 'https://maven.mozilla.org/maven2/' }",
            1,
        )
        p.write_text(t, encoding="utf-8")
        print("Patched", p)
        return True
    return False

def main() -> None:
    root = Path("android")
    kts = root / "settings.gradle.kts"
    groovy = root / "settings.gradle"
    ok = False
    if kts.exists():
        ok = patch_kts(kts) or ok
    if groovy.exists():
        ok = patch_groovy(groovy) or ok
    # also project-level build files
    for name in ("build.gradle.kts", "build.gradle"):
        bp = root / name
        if bp.exists() and "maven.mozilla.org" not in bp.read_text(encoding="utf-8"):
            pass
    if not ok:
        print("WARN: could not inject mozilla maven — Gecko dependency may fail")
        sys.exit(0)  # don't fail CI if chromium-only
    print("MOZILLA_MAVEN=ok")

if __name__ == "__main__":
    main()
