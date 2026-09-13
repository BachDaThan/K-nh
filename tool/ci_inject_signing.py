#!/usr/bin/env python3
"""Inject release signing into Flutter android app module (Groovy OR Kotlin DSL).

Exit 0 only if signingConfigs was applied (or already present).
Exit 1 if no gradle file or inject failed — CI must not ship unsigned/debug APKs.
"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

ROOT = Path(".")
APP = ROOT / "android" / "app"
PROPS_APP = APP / "key.properties"
PROPS_ROOT = ROOT / "android" / "key.properties"
JKS_APP = APP / "kinh-release.jks"
JKS_ROOT = ROOT / "android" / "kinh-release.jks"

GROOVY = APP / "build.gradle"
KTS = APP / "build.gradle.kts"


def die(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def ensure_files() -> None:
    if not JKS_APP.exists() and JKS_ROOT.exists():
        shutil.copy(JKS_ROOT, JKS_APP)
    if not JKS_APP.exists():
        die(f"Missing keystore: {JKS_APP}")

    # key.properties lives in android/app/ ; storeFile relative to app/
    if PROPS_ROOT.exists() and not PROPS_APP.exists():
        PROPS_APP.write_text(PROPS_ROOT.read_text(), encoding="utf-8")
    if not PROPS_APP.exists():
        die(f"Missing {PROPS_APP}")

    lines = []
    for line in PROPS_APP.read_text(encoding="utf-8").splitlines():
        if line.strip().startswith("storeFile="):
            lines.append("storeFile=kinh-release.jks")
        else:
            lines.append(line)
    text = "\n".join(lines).strip() + "\n"
    PROPS_APP.write_text(text, encoding="utf-8")
    PROPS_ROOT.write_text(text, encoding="utf-8")
    print("key.properties OK:\n", text)


def inject_groovy(path: Path) -> None:
    t = path.read_text(encoding="utf-8")
    if "signingConfigs" in t and "keyAlias" in t and "signingConfigs.release" in t:
        print("Groovy: signing already present")
        return

    loader = """
def keystoreProperties = new Properties()
def keystorePropertiesFile = file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

"""
    if "keystoreProperties" not in t:
        t = loader + t

    if "signingConfigs" not in t or "keyAlias" not in t:
        block = """
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
"""
        if "    buildTypes {" in t:
            t = t.replace("    buildTypes {", block + "\n    buildTypes {", 1)
        else:
            die("Groovy: no buildTypes block to inject signingConfigs")

    if "signingConfig signingConfigs.release" not in t:
        # Prefer release { inside buildTypes
        if "        release {" in t:
            t = t.replace(
                "        release {",
                "        release {\n            signingConfig signingConfigs.release",
                1,
            )
        else:
            die("Groovy: could not find release buildType")

    path.write_text(t, encoding="utf-8")
    print("Patched Groovy", path)


def inject_kts(path: Path) -> None:
    t = path.read_text(encoding="utf-8")
    if 'create("release")' in t and "keyAlias" in t and 'getByName("release")' in t:
        print("KTS: signing already present")
        return

    imports = """
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

"""
    if "keystoreProperties" not in t:
        # after plugins block if present
        if "plugins {" in t:
            # insert after first closing of plugins
            idx = t.find("plugins {")
            end = t.find("}", idx)
            # find matching - simple: first line that is just }
            depth = 0
            end = idx
            for i, ch in enumerate(t[idx:], idx):
                if ch == "{":
                    depth += 1
                elif ch == "}":
                    depth -= 1
                    if depth == 0:
                        end = i + 1
                        break
            t = t[:end] + "\n" + imports + t[end:]
        else:
            t = imports + t

    if 'create("release")' not in t:
        block = """
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
"""
        if "    buildTypes {" in t:
            t = t.replace("    buildTypes {", block + "\n    buildTypes {", 1)
        elif "buildTypes {" in t:
            t = t.replace("buildTypes {", block + "\n    buildTypes {", 1)
        else:
            die("KTS: no buildTypes block")

    if 'signingConfig = signingConfigs.getByName("release")' not in t:
        # Flutter template often has: release { signingConfig = signingConfigs.getByName("debug") }
        if 'getByName("debug")' in t and "release" in t:
            # replace only within release - crude but works for Flutter default
            t = t.replace(
                'signingConfig = signingConfigs.getByName("debug")',
                'signingConfig = signingConfigs.getByName("release")',
                1,
            )
        elif "release {" in t:
            t = t.replace(
                "release {",
                'release {\n            signingConfig = signingConfigs.getByName("release")',
                1,
            )
        else:
            die("KTS: could not wire release signingConfig")

    path.write_text(t, encoding="utf-8")
    print("Patched KTS", path)


def main() -> None:
    ensure_files()
    if KTS.exists():
        inject_kts(KTS)
        print("SIGNING_INJECT=ok kind=kts")
    elif GROOVY.exists():
        inject_groovy(GROOVY)
        print("SIGNING_INJECT=ok kind=groovy")
    else:
        die("Neither build.gradle nor build.gradle.kts found under android/app/")


if __name__ == "__main__":
    main()
