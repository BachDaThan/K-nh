#!/usr/bin/env python3
"""Force compileSdk/targetSdk=36 for app + plugin subprojects (file_picker AAR)."""
from pathlib import Path
import re
import sys

SDK = 36


def main() -> None:
    android = Path("android")
    if not android.is_dir():
        print("No android/", file=sys.stderr)
        sys.exit(1)

    gp = android / "gradle.properties"
    lines = gp.read_text(encoding="utf-8").splitlines() if gp.exists() else []
    props = {
        "flutter.compileSdkVersion": str(SDK),
        "flutter.targetSdkVersion": str(SDK),
    }
    out, seen = [], set()
    for ln in lines:
        s = ln.strip()
        if s and not s.startswith("#") and "=" in s:
            k = s.split("=", 1)[0].strip()
            if k in props:
                out.append(f"{k}={props[k]}")
                seen.add(k)
                continue
        out.append(ln)
    for k, v in props.items():
        if k not in seen:
            out.append(f"{k}={v}")
    gp.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"gradle.properties flutter.compileSdkVersion={SDK}")

    for rel in ("app/build.gradle.kts", "app/build.gradle"):
        p = android / rel
        if not p.exists():
            continue
        t = p.read_text(encoding="utf-8")
        t = re.sub(r"compileSdk\s*=\s*[^\n]+", f"compileSdk = {SDK}", t)
        t = re.sub(r"targetSdk\s*=\s*[^\n]+", f"targetSdk = {SDK}", t)
        t = re.sub(r"compileSdkVersion\s+[^\n]+", f"compileSdkVersion {SDK}", t)
        t = re.sub(r"targetSdkVersion\s+[^\n]+", f"targetSdkVersion {SDK}", t)
        t = t.replace("compileSdk = flutter.compileSdkVersion", f"compileSdk = {SDK}")
        t = t.replace("targetSdk = flutter.targetSdkVersion", f"targetSdk = {SDK}")
        if f"compileSdk = {SDK}" not in t and "compileSdkVersion" not in t:
            t = t.replace("android {", f"android {{\n    compileSdk = {SDK}", 1)
        p.write_text(t, encoding="utf-8")
        print(f"patched {p}")
        for ln in t.splitlines():
            if "compileSdk" in ln or "targetSdk" in ln:
                print(" ", ln.strip())

    marker = "kinh-force-compile-sdk"
    root_kts = android / "build.gradle.kts"
    root_g = android / "build.gradle"
    force_kts = f"""
// {marker}
subprojects {{
    pluginManager.withPlugin("com.android.library") {{
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {{
            try {{
                val m = androidExt.javaClass.methods.firstOrNull {{
                    it.name in listOf("setCompileSdkVersion", "setCompileSdk") && it.parameterCount == 1
                }}
                m?.invoke(androidExt, {SDK})
                println("kinh: compileSdk={SDK} on $name")
            }} catch (e: Exception) {{
                println("kinh: skip $name ${{e.message}}")
            }}
        }}
    }}
}}
"""
    force_groovy = f"""
// {marker}
subprojects {{ project ->
    project.pluginManager.withPlugin("com.android.library") {{
        if (project.hasProperty("android")) {{
            project.android.compileSdkVersion = {SDK}
        }}
    }}
}}
"""
    if root_kts.exists():
        t = root_kts.read_text(encoding="utf-8")
        if "kinh-force" in t:
            for key in ("// kinh-force-compile-sdk", "// kinh-force"):
                i = t.find(key)
                if i >= 0:
                    t = t[:i].rstrip() + "\n"
                    break
        if marker not in t:
            t = t.rstrip() + "\n" + force_kts + "\n"
        root_kts.write_text(t, encoding="utf-8")
        print("patched android/build.gradle.kts")
    elif root_g.exists():
        t = root_g.read_text(encoding="utf-8")
        if marker not in t:
            root_g.write_text(t.rstrip() + "\n" + force_groovy + "\n", encoding="utf-8")
        print("patched android/build.gradle")

    print("FORCE_COMPILE_SDK=ok")


if __name__ == "__main__":
    main()
