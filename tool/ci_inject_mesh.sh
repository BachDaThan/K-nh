#!/usr/bin/env bash
# Sau `flutter create --platforms=android`
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG_DIR="android/app/src/main/kotlin/com/bachdathan/kinh/mesh"
mkdir -p "$PKG_DIR"
cp -f "$ROOT"/tool/android_mesh/src/main/kotlin/com/bachdathan/kinh/mesh/*.kt "$PKG_DIR/"
echo "Copied mesh Kotlin -> $PKG_DIR"

python3 << 'PY'
from pathlib import Path
import re

# --- Manifest permissions + service ---
p = Path("android/app/src/main/AndroidManifest.xml")
t = p.read_text()
perms = [
    ('android.permission.BLUETOOTH', True),
    ('android.permission.BLUETOOTH_ADMIN', True),
    ('android.permission.BLUETOOTH_SCAN', False),
    ('android.permission.BLUETOOTH_ADVERTISE', False),
    ('android.permission.BLUETOOTH_CONNECT', False),
    ('android.permission.ACCESS_FINE_LOCATION', False),
    ('android.permission.NEARBY_WIFI_DEVICES', False),
    ('android.permission.ACCESS_WIFI_STATE', False),
    ('android.permission.CHANGE_WIFI_STATE', False),
    ('android.permission.FOREGROUND_SERVICE', False),
    ('android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE', False),
    ('android.permission.RECORD_AUDIO', False),
]
for name, _ in perms:
    if name not in t:
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

# uses-feature bluetooth le optional
if "bluetooth_le" not in t:
    feat = '    <uses-feature android:name="android.hardware.bluetooth_le" android:required="false"/>\n'
    t = t.replace("<application", feat + "    <application", 1)

p.write_text(t)
print("manifest mesh ok")

# --- MainActivity: register MeshPlugin ---
mains = list(Path("android").rglob("MainActivity.kt"))
if not mains:
    print("WARN: MainActivity.kt not found")
else:
    mp = mains[0]
    mt = mp.read_text()
    if "MeshPlugin" not in mt:
        if "import io.flutter.embedding.engine.FlutterEngine" not in mt:
            mt = mt.replace(
                "import io.flutter.embedding.android.FlutterActivity",
                "import io.flutter.embedding.android.FlutterActivity\n"
                "import io.flutter.embedding.engine.FlutterEngine\n"
                "import com.bachdathan.kinh.mesh.MeshPlugin",
            )
        else:
            if "com.bachdathan.kinh.mesh.MeshPlugin" not in mt:
                mt = "import com.bachdathan.kinh.mesh.MeshPlugin\n" + mt
        if "configureFlutterEngine" not in mt:
            # insert method into class
            mt = re.sub(
                r"(class MainActivity\s*:\s*FlutterActivity\(\)\s*\{)",
                r"""\1
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(MeshPlugin())
    }
""",
                mt,
                count=1,
            )
        else:
            mt = mt.replace(
                "super.configureFlutterEngine(flutterEngine)",
                "super.configureFlutterEngine(flutterEngine)\n"
                "        flutterEngine.plugins.add(MeshPlugin())",
            )
        mp.write_text(mt)
        print(f"MainActivity plugin registered: {mp}")
    else:
        print("MainActivity already has MeshPlugin")
PY

echo "MESH_INJECT=ok"
