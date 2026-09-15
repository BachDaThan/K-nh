#!/usr/bin/env bash
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
        # BLUETOOTH_SCAN neverForLocation helps without location on API 31+
        if name == "android.permission.BLUETOOTH_SCAN":
            line = f'    <uses-permission android:name="{name}" android:usesPermissionFlags="neverForLocation"/>\n'
        elif name == "android.permission.NEARBY_WIFI_DEVICES":
            line = f'    <uses-permission android:name="{name}" android:usesPermissionFlags="neverForLocation"/>\n'
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
    feat = '    <uses-feature android:name="android.hardware.bluetooth_le" android:required="false"/>\n'
    t = t.replace("<application", feat + "    <application", 1)

p.write_text(t)
print("manifest mesh ok")

mains = list(Path("android").rglob("MainActivity.kt"))
print("MainActivity candidates:", [str(x) for x in mains])
for mp in mains:
    mt = mp.read_text()
    changed = False
    if "com.bachdathan.kinh.mesh.MeshPlugin" not in mt:
        mt = "import com.bachdathan.kinh.mesh.MeshPlugin\n" + mt
        changed = True
    if "import io.flutter.embedding.engine.FlutterEngine" not in mt:
        mt = mt.replace(
            "import io.flutter.embedding.android.FlutterActivity",
            "import io.flutter.embedding.android.FlutterActivity\nimport io.flutter.embedding.engine.FlutterEngine",
        )
        changed = True
    if "MeshPlugin()" not in mt:
        if "configureFlutterEngine" in mt:
            mt = mt.replace(
                "super.configureFlutterEngine(flutterEngine)",
                "super.configureFlutterEngine(flutterEngine)\n        flutterEngine.plugins.add(MeshPlugin())",
            )
            changed = True
        else:
            mt2, n = re.subn(
                r"class MainActivity\s*:\s*FlutterActivity\(\)\s*\{",
                """class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(MeshPlugin())
    }
""",
                mt,
                count=1,
            )
            if n:
                mt = mt2
                changed = True
            else:
                # empty body class MainActivity: FlutterActivity()
                mt2, n = re.subn(
                    r"class MainActivity\s*:\s*FlutterActivity\(\)\s*",
                    """class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(MeshPlugin())
    }
}
""",
                    mt,
                    count=1,
                )
                if n:
                    mt = mt2
                    changed = True
    if changed:
        mp.write_text(mt)
        print("MainActivity plugin registered:", mp)
    else:
        print("MainActivity already configured:", mp)
    print("--- MainActivity preview ---")
    print(mp.read_text()[:800])
PY

echo "MESH_INJECT=ok"
