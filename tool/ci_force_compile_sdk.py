#!/usr/bin/env python3
"""Force compileSdk 36 on the app module (required by file_picker metadata)."""
from pathlib import Path
import re
import sys

SDK = 36
ROOT = Path("android")

def main() -> None:
    if not ROOT.is_dir():
        sys.exit("no android/")

    gp = ROOT / "gradle.properties"
    lines = gp.read_text().splitlines() if gp.exists() else []
    kv = {
        "flutter.compileSdkVersion": str(SDK),
        "flutter.targetSdkVersion": str(SDK),
        "android.useAndroidX": "true",
    }
    out, seen = [], set()
    for ln in lines:
        if "=" in ln and not ln.strip().startswith("#"):
            k = ln.split("=", 1)[0].strip()
            if k in kv:
                out.append(f"{k}={kv[k]}")
                seen.add(k)
                continue
        out.append(ln)
    for k, v in kv.items():
        if k not in seen:
            out.append(f"{k}={v}")
    gp.write_text("\n".join(out) + "\n")
    print("OK gradle.properties")

    for rel in ("app/build.gradle.kts", "app/build.gradle"):
        p = ROOT / rel
        if not p.exists():
            continue
        t = p.read_text()
        t = re.sub(r"compileSdk\s*=\s*\S+", f"compileSdk = {SDK}", t)
        t = re.sub(r"targetSdk\s*=\s*\S+", f"targetSdk = {SDK}", t)
        t = re.sub(r"compileSdkVersion\s+\S+", f"compileSdkVersion {SDK}", t)
        t = re.sub(r"targetSdkVersion\s+\S+", f"targetSdkVersion {SDK}", t)
        # Flutter 3.16+ often uses: compileSdk = flutter.compileSdkVersion
        t = t.replace(
            "compileSdk = flutter.compileSdkVersion",
            f"compileSdk = {SDK}",
        )
        t = t.replace(
            "targetSdk = flutter.targetSdkVersion",
            f"targetSdk = {SDK}",
        )
        p.write_text(t)
        print(f"OK {p}")
        for i, ln in enumerate(p.read_text().splitlines(), 1):
            if "compileSdk" in ln or "targetSdk" in ln:
                print(f"  {i}:{ln}")

    # Root: force all library projects (plugins) — pure Groovy closure without typed imports
    root = ROOT / "build.gradle.kts"
    if root.exists():
        t = root.read_text()
        marker = "kinh-force-plugin-compile-sdk"
        if marker not in t:
            t += f"""

// {marker}
subprojects {{
    val sub = this
    sub.afterEvaluate {{
        val ext = sub.extensions.findByName("android") ?: return@afterEvaluate
        try {{
            val m = ext.javaClass.methods.find {{ it.name == "setCompileSdkVersion" && it.parameterCount == 1 }}
            m?.invoke(ext, {SDK})
            println("kinh: forced compileSdkVersion={SDK} on ${{sub.name}}")
        }} catch (e: Exception) {{
            try {{
                val m2 = ext.javaClass.methods.find {{ it.name == "setCompileSdk" && it.parameterCount == 1 }}
                m2?.invoke(ext, {SDK})
                println("kinh: forced compileSdk={SDK} on ${{sub.name}}")
            }} catch (e2: Exception) {{
                println("kinh: skip ${{sub.name}}: $e2")
            }}
        }}
    }}
}}
"""
            root.write_text(t)
            print("OK root subprojects force")
    print("FORCE_COMPILE_SDK=ok")

if __name__ == "__main__":
    main()
