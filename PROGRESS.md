# Fix compileSdk 36 (lần 2)

Sed chỉ sửa app module không đủ / bị Flutter ghi đè.
`tool/ci_force_compile_sdk.py`:
- `gradle.properties` → flutter.compileSdkVersion=36
- patch app build.gradle(.kts)
- subprojects afterEvaluate ép compileSdk 36 cho mọi plugin (file_picker…)
