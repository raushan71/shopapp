# eShop

eShop shopping application.

The installed app display name is `eShop`. The Flutter package is `itrsp_shop`,
and the Android application ID and iOS bundle ID are `com.itrsp.shop`.

## Google login

The login screen's **Continue with Google** button opens the native account
picker on Android and iOS. Its one-time server authorization code is sent to
`POST /api/auth/google/token`. Only the shop backend's returned user and access
token establish the app session; the app does not create a Firebase Auth session.

Google login must be enabled in the shop admin settings. The Google web OAuth
client ID returned by `/api/master` must belong to the same Google project as
the native apps. Keep the OAuth client secret on the backend.

The Firebase Android app `com.itrsp.shop` in `shop-f9ed5` now has the existing
debug and release certificates registered. `android/app/google-services.json`
includes both Android OAuth clients. Reuse the current release keystore in
GitHub Actions. If the signing key changes, register its fingerprints and
download the configuration again. For a future Play Store installation, also
register the Google Play app signing certificate (which can differ from the
upload certificate).

The iOS callback scheme in `ios/Runner/Info.plist` matches the reversed OAuth
client ID in `ios/Runner/GoogleService-Info.plist`.

The Google sign-in dependencies require Dart 3.9 or later; the GitHub workflow's
Flutter 3.35.5 satisfies this. The Android implementation is pinned to 7.2.2 to
retain Android 21 support with that toolchain. Login regression tests run with
`flutter test test/google_login_test.dart` and also run in the release workflow.

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

The workflow verifies the keystore, alias, and private-key password before
setting up Flutter or compiling the app. A successful signing report only
checks the certificate; this verification also checks that the private key can
be unlocked for signing.

If packaging fails with `Get Key failed` or `Given final block not properly
padded`, update `KEY_PASSWORD` to the password for the private key inside the
uploaded keystore. For this repository's existing PKCS12 release keystore,
`KEY_PASSWORD` and `KEYSTORE_PASSWORD` have been verified to use the same value.
The alias is `upload`. Use the passwords from your local `android/key.properties`
and keep their values in GitHub Actions secrets.

To verify the existing local signing credentials without building an APK or
displaying passwords, run this from the repository root:

```powershell
java .github/scripts/VerifyAndroidSigning.java android/app/keystore.jks android/key.properties
```

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

