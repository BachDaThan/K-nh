#!/usr/bin/env bash
# Sau `flutter create --platforms=android`
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG_DIR="android/app/src/main/kotlin/com/bachdathan/kinh/mesh"
mkdir -p "$PKG_DIR"
cp -f "$ROOT"/tool/android_mesh/src/main/kotlin/com/bachdathan/kinh/mesh/*.kt "$PKG_DIR/"
echo "Copied mesh Kotlin -> $PKG_DIR"
ls -la "$PKG_DIR"

python3 << 'PY'
from pathlib import Path
import re

p = Path("android/app/src/main/AndroidManifest.xml")
t = p.read_text()
perms = [
    "android.permission.BLUETOOTH",
    "android.permission.BLUETOOTH_ADMIN",
    "android.permission.BLUETOOTH_SCAN",
    "android.permission.BLUETOOTH_ADVERTISE",
    "android.permission.BLUETOOTH_CONNECT",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.NEARBY_WIFI_DEVICES",
    "android.permission.ACCESS_WIFI_STATE",
    "android.permission.CHANGE_WIFI_STATE",
    "android.permission.FOREGROUND_SERVICE",
    "android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.RECORD_AUDIO",
]
for name in perms:
    if name not in t:
        if name in (
            "android.permission.BLUETOOTH_SCAN",
            "android.permission.NEARBY_WIFI_DEVICES",
        ):
            line = (
                f'    <uses-permission android:name="{name}" '
                f'android:usesPermissionFlags="neverForLocation"/>\n'
            )
        else:
            line = f'    <uses-permission android:name="{name}"/>\n'
        t = t.replace("<application", line + "    <application", 1)

if "MeshForegroundService" not in t:
    svc = '''
        <service
            android:name="com.bachdathan.kinh.mesh.MeshForegroundService"
            android:exported="false"
            android:foregroundServiceType="connectedDevice"/>
'''
    t = t.replace("</application>", svc + "    </application>", 1)

if "bluetooth_le" not in t:
    feat = (
        '    <uses-feature android:name="android.hardware.bluetooth_le" '
        'android:required="false"/>\n'
    )
    t = t.replace("<application", feat + "    <application", 1)

p.write_text(t)
print("manifest mesh ok")


def inject_imports_after_package(src: str, imports: list[str]) -> str:
    """Kotlin requires package first; imports only after package line."""
    lines = src.splitlines(keepends=True)
    # find package line
    pkg_i = None
    for i, line in enumerate(lines):
        if line.startswith("package "):
            pkg_i = i
            break
    if pkg_i is None:
        # no package — put imports at top
        block = "".join(f"import {imp}\n" for imp in imports if f"import {imp}" not in src)
        return block + src

    existing = src
    to_add = [imp for imp in imports if f"import {imp}" not in existing]
    if not to_add:
        return src

    insert_at = pkg_i + 1
    # skip blank lines right after package
    while insert_at < len(lines) and lines[insert_at].strip() == "":
        insert_at += 1
    # skip existing imports block end
    while insert_at < len(lines) and lines[insert_at].startswith("import "):
        insert_at += 1

    block = "".join(f"import {imp}\n" for imp in to_add)
    # ensure a newline after package if needed
    if insert_at == pkg_i + 1 and not lines[pkg_i].endswith("\n"):
        pass
    lines.insert(insert_at, block if block.endswith("\n") else block + "\n")
    return "".join(lines)


mains = list(Path("android").rglob("MainActivity.kt"))
print("MainActivity candidates:", [str(x) for x in mains])
for mp in mains:
    mt = mp.read_text()
    # NEVER prepend import before package
    mt = inject_imports_after_package(
        mt,
        [
            "io.flutter.embedding.engine.FlutterEngine",
            "com.bachdathan.kinh.mesh.MeshPlugin",
        ],
    )

    if "MeshPlugin()" not in mt:
        if "configureFlutterEngine" in mt:
            if "MeshPlugin()" not in mt:
                mt = mt.replace(
                    "super.configureFlutterEngine(flutterEngine)",
                    "super.configureFlutterEngine(flutterEngine)\n"
                    "        flutterEngine.plugins.add(MeshPlugin())",
                )
        else:
            # class MainActivity : FlutterActivity() { ... }
            mt2, n = re.subn(
                r"class MainActivity\s*:\s*FlutterActivity\(\)\s*\{",
                "class MainActivity : FlutterActivity() {\n"
                "    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {\n"
                "        super.configureFlutterEngine(flutterEngine)\n"
                "        flutterEngine.plugins.add(MeshPlugin())\n"
                "    }\n",
                mt,
                count=1,
            )
            if n:
                mt = mt2
            else:
                # class MainActivity : FlutterActivity()
                mt2, n = re.subn(
                    r"class MainActivity\s*:\s*FlutterActivity\(\)\s*(?:\n|$)",
                    "class MainActivity : FlutterActivity() {\n"
                    "    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {\n"
                    "        super.configureFlutterEngine(flutterEngine)\n"
                    "        flutterEngine.plugins.add(MeshPlugin())\n"
                    "    }\n"
                    "}\n",
                    mt,
                    count=1,
                )
                if n:
                    mt = mt2
                else:
                    print("WARN: could not patch class body in", mp)

    # Sanity: package must be before any import
    pkg_pos = mt.find("package ")
    imp_pos = mt.find("import ")
    if pkg_pos < 0:
        print("WARN: no package in", mp)
    elif imp_pos >= 0 and imp_pos < pkg_pos:
        raise SystemExit(f"FATAL: import before package in {mp}")

    mp.write_text(mt)
    print("--- MainActivity ---")
    print(mp.read_text()[:900])
    print("--- end preview ---")

print("MESH_INJECT=ok")
PY
