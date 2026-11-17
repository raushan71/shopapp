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

## Build signed Android releases on GitHub

The app uses `https://shop.itrsp.com/api` as its production API. Android builds
run on GitHub Actions; Flutter does not need to be installed locally.

The runner also restores the generated Gradle wrapper files because this
repository intentionally does not track them.

1. Configure the four signing secrets described below, then push this repository to GitHub.
2. Open **Actions** and select **Build Android Release APKs and App Bundle**.
3. Select **Run workflow**.
4. When the job finishes, download the artifact matching your device or the
   App Bundle for Google Play. Each artifact contains one release file and
   its `SHA256SUMS.txt`.

| Artifact name (followed by the run number) | File | Use |
| --- | --- | --- |
| `itrsp_shop-android-arm64-v8a-release-` | `app-arm64-v8a-release.apk` | 64-bit ARM Android phones |
| `itrsp_shop-android-armeabi-v7a-release-` | `app-armeabi-v7a-release.apk` | 32-bit ARM Android phones |
| `itrsp_shop-android-x86_64-release-` | `app-x86_64-release.apk` | x86-64 Android devices and emulators |
| `itrsp_shop-android-appbundle-release-` | `app-release.aab` | Google Play upload |

APKs use `flutter build apk --release --split-per-abi`, so each contains only
one architecture's native libraries. This reduces APK size compared with an APK
containing every architecture. Release code and resource shrinking are already
enabled in `android/app/build.gradle`. The workflow summary reports file sizes.
See [Flutter's Android release guide](https://docs.flutter.dev/deployment/android).

The workflow automatically runs for pushes to `main` or `master` and for tags
whose names start with `v`.

### Production release signing

The workflow builds signed release files only and fails before installing build
tools if any signing secret is missing. Add these repository secrets under
**Settings > Secrets and variables > Actions**:

- `KEYSTORE_BASE64`: the Android keystore encoded as one base64 string
- `KEY_ALIAS`: the key alias (`upload` for the existing release keystore)
- `KEY_PASSWORD`: the existing key password
- `KEYSTORE_PASSWORD`: the existing keystore password

Use the existing release keystore at `D:\shopapp\android\app\keystore.jks`.
To copy its Base64 value to the Windows clipboard for `KEYSTORE_BASE64`,
run this in PowerShell and paste the clipboard contents into that GitHub secret:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('D:\shopapp\android\app\keystore.jks')) | Set-Clipboard
```

Reuse the same release keystore for every workflow run. For Firebase features
that verify signing certificates, register this release certificate's SHA-1 and
SHA-256 with the `com.itrsp.shop` Firebase Android app as well.

The workflow reconstructs the keystore inside the temporary GitHub runner and
removes the generated signing files when the job finishes.
Never commit the keystore or `android/key.properties`.

