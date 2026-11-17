# itrsp_shop

itrsp_shop shopping application.

## Getting Started

Generate image code

- dart run build_runner build
  Generate language code
- flutter pub run intl_utils:generate

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Build Android files on GitHub

The app uses `https://shop.itrsp.com/api` as its production API. Android builds
run on GitHub Actions; Flutter does not need to be installed locally.

The runner also restores the generated Gradle wrapper files because this
repository intentionally does not track them.

1. Push this repository to GitHub.
2. Open **Actions** and select **Build Android APK and App Bundle**.
3. Select **Run workflow**.
4. When the job finishes, download the artifact from the workflow run. It
   contains the APK, AAB, and `SHA256SUMS.txt`.

The workflow automatically runs for pushes to `main` or `master` and for tags
whose names start with `v`.

### Production release signing

Without signing secrets, the workflow creates debug APK and AAB files. For
signed production release files, add these repository secrets under
**Settings > Secrets and variables > Actions**:

- `ANDROID_KEYSTORE_BASE64`: the Android keystore encoded as one base64 string
- `ANDROID_KEY_ALIAS`: the key alias
- `ANDROID_KEY_PASSWORD`: the key password
- `ANDROID_STORE_PASSWORD`: the keystore password

The workflow reconstructs the keystore only inside the temporary GitHub runner.
Never commit the keystore or `android/key.properties`.

