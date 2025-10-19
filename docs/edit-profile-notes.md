Edit Profile - Image Picker Notes

1) Dependencies
- image_picker: added to `pubspec.yaml` (version ^0.8.7+5).

2) Android
- Add the following permissions to `android/app/src/main/AndroidManifest.xml` inside <manifest>:
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

- For Android 13+ use the new photo permission instead of READ_EXTERNAL_STORAGE where necessary.
- Ensure `android:requestLegacyExternalStorage="true"` only if targeting legacy behavior (not recommended).

3) iOS
- Add to `ios/Runner/Info.plist`:
  <key>NSPhotoLibraryUsageDescription</key>
  <string>Used to pick profile photos from your library.</string>

4) Behavior
- The picker returns a platform file path (e.g., /storage/emulated/0/...), which is stored in the in-memory `AuthService` profile store and rendered with `BookImage` via `Image.file`.
- If you want to persist uploads to a server or save to app documents directory, implement file copy/upload logic in `_pickFromGallery`.

5) Testing
- Run on a real device or emulator with photos available.
- After picking, press Save; profile image and phone are stored in-memory for the current session.

6) Next Steps (optional)
- Implement image cropping/resizing before saving.
- Add permission request UI for graceful permission denial handling.
