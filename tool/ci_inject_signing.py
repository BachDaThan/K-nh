#!/usr/bin/env python3
"""Inject release signingConfigs into Flutter-generated android/app/build.gradle."""
from pathlib import Path
import re
import shutil
import sys

root = Path(".")
app = root / "android" / "app"
gradle = app / "build.gradle"
props_app = app / "key.properties"
props_root = root / "android" / "key.properties"
jks_app = app / "kinh-release.jks"
jks_root = root / "android" / "kinh-release.jks"

if not gradle.exists():
    print("No android/app/build.gradle — skip")
    sys.exit(0)

# Normalize paths: key.properties + jks at android/app/ (storeFile relative to app/)
if props_root.exists() and not props_app.exists():
    props_app.write_text(props_root.read_text())
if jks_root.exists() and not jks_app.exists():
    shutil.copy(jks_root, jks_app)

if props_app.exists():
    lines = []
    for line in props_app.read_text().splitlines():
        if line.strip().startswith("storeFile="):
            lines.append("storeFile=kinh-release.jks")
        else:
            lines.append(line)
    props_app.write_text("\n".join(lines) + "\n")
    props_root.write_text(props_app.read_text())

t = gradle.read_text()
if "signingConfigs" in t and "keyAlias" in t:
    print("signingConfigs already present")
    sys.exit(0)

loader = """
def keystoreProperties = new Properties()
def keystorePropertiesFile = file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

"""
t = loader + t

inject = """
    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }
"""
if "    buildTypes {" in t:
    t = t.replace("    buildTypes {", inject + "\n    buildTypes {", 1)
else:
    print("WARN: no buildTypes block")
    gradle.write_text(t)
    sys.exit(0)

# Ensure release uses signingConfig
if "signingConfig signingConfigs.release" not in t:
    t = t.replace(
        "        release {",
        "        release {\n            signingConfig signingConfigs.release",
        1,
    )

gradle.write_text(t)
print("Patched", gradle)
