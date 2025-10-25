# estighfar_ready - ready to upload to GitHub

This Flutter project is prepared for you. To build APK automatically via GitHub Actions:

1. Create a new repo on GitHub (for example: estighfar-app).
2. Upload the entire contents of this project (use 'Upload files' on the repository page).
3. After uploading and committing, go to the 'Actions' tab in your repo. The workflow 'Build Debug APK' will run.
4. When it finishes, open the workflow run and download the artifact 'app-debug' (contains app-debug.apk).

If you prefer CLI git steps, you can also push the project using git commands.

Note: To build locally you need Flutter installed. Run `flutter pub get` then `flutter build apk --debug`.
