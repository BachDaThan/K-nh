# Fix FilePickerPlugin missing

file_picker 11.x: Android không compile Kotlin plugin → GeneratedPluginRegistrant không tìm thấy FilePickerPlugin.
Ghim **file_picker: 10.3.10** (được báo build OK).
Bookshelf dùng lại FilePicker.platform.pickFiles.
