# Fix compileSdk 36

`file_picker` → `flutter_plugin_android_lifecycle` đòi compileSdk ≥ 36.
CI sau `flutter create` ép `compileSdk = 36` trong `android/app/build.gradle.kts`.
