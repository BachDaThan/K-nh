#!/usr/bin/env bash
# Chạy SAU `flutter create --platforms=android` trong CI.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG_DIR="android/app/src/main/kotlin/com/bachdathan/kinh/mesh"
mkdir -p "$PKG_DIR"
cp -r "$ROOT/tool/android_mesh/src/main/kotlin/com/bachdathan/kinh/mesh/"*.kt "$PKG_DIR/"
MANIFEST="android/app/src/main/AndroidManifest.xml"
if ! grep -q 'MeshForegroundService' "$MANIFEST" 2>/dev/null; then
  # Insert service + permissions before </manifest>
  python3 - <<'PY'
from pathlib import Path
p = Path("android/app/src/main/AndroidManifest.xml")
t = p.read_text()
perms = """
    <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30"/>
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30"/>
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
    <uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES"/>
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
    <uses-permission android:name="android.permission.CHANGE_WIFI_STATE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
"""
svc = """
        <service
            android:name=".mesh.MeshForegroundService"
            android:exported="false"
            android:foregroundServiceType="connectedDevice"/>
"""
if "BLUETOOTH_SCAN" not in t:
    t = t.replace("<application", perms + "\n    <application", 1)
if "MeshForegroundService" not in t:
    t = t.replace("</application>", svc + "\n    </application>", 1)
p.write_text(t)
print("manifest mesh ok")
PY
fi
echo "MESH_INJECT=ok"
