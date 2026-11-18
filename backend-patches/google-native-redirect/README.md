# Google native sign-in redirect fix

## Correction for the Google PHP library

The earlier empty-string patch causes `Redirect URI must be absolute` in the
Google PHP auth library. Native requests must use **null**, not an empty string:

```php
$client->setRedirectUri($isNativeApp ? null : 'postmessage');
```

If the three earlier changes are already deployed, only update this line.
`google-native-null-redirect.patch` contains that one-line correction.
The complete controller and original-controller patch also use null now.

This is a deployment copy of the server controller supplied in the conversation.
Its target is the Laravel backend, not the Flutter app:

`/home/itrsp-shop/htdocs/shop.itrsp.com/app/Http/Controllers/API/SocialAuthController.php`

The original controller exchanges every Google authorization code using
`redirect_uri=postmessage`. Native Android and iOS server authorization codes
need no browser redirect URI. Use null in the Google PHP library. The app sends `device_type=android` or
`device_type=ios` in `POST /api/auth/google/token`.

The fix passes the current request into `googleTokenExchange` and selects the
redirect URI from this fixed set:

| Request device_type | Google token exchange redirect_uri |
| --- | --- |
| android, ios | null (no browser redirect) |
| web, missing, other values | postmessage (existing website behavior) |

## Apply on the Laravel server

Upload `google-native-redirect.patch` to the Laravel project root, then run:

```bash
cp app/Http/Controllers/API/SocialAuthController.php app/Http/Controllers/API/SocialAuthController.php.before-native-redirect
git apply --check google-native-redirect.patch
git apply google-native-redirect.patch
php -l app/Http/Controllers/API/SocialAuthController.php
php artisan optimize:clear
```

Run the apply command only after the check succeeds, and clear caches only
after the PHP syntax check succeeds. Alternatively, merge the three changed
parts from the included `SocialAuthController.php` into the server file.

Start a fresh Google sign-in in the installed app after applying the server fix.
An APK rebuild is unnecessary because the existing app sends the platform field.
This package has not been deployed to the server from this workspace.

## Validation

```bash
php -l backend-patches/google-native-redirect/SocialAuthController.php
php backend-patches/google-native-redirect/test.php
```

The standalone test uses fake Laravel and Google dependencies to check native
and web redirect selection, trusted Google profile data, backend session
creation, rejected authorization codes, and disabled providers. It does not
contact Google or prove a live account login. The original supplied controller
fails the Android redirect case; the corrected controller passes all seven cases.

The backend continues using its stored web OAuth client ID and secret. It still
exchanges the Google code and fetches the Google profile before creating a shop
session. No arbitrary redirect URL from the client is accepted.

## Apply on the server

Back up the existing controller, then copy the corrected file to the target
path, or apply `google-native-redirect.patch` from the backend project root.
Review the diff against any newer server edits before replacing the file.

From `/home/itrsp-shop/htdocs/shop.itrsp.com`:

```bash
php -l app/Http/Controllers/API/SocialAuthController.php
php artisan optimize:clear
```

Retry Continue with Google in the installed app to obtain a fresh authorization
code. Existing builds already send the platform field, so this change does not
require rebuilding the APK. Also check the website's Google login.

The server code must use the current secret for the same web OAuth client ID
as the app. Rotate the secret previously shared in chat and update the backend's
stored provider credentials. Keep OAuth client secrets on the server.

## Verification

```bash
php backend-patches/google-native-redirect/test.php
```

The standalone test uses fake Google and Laravel dependencies to exercise the
actual corrected controller. It checks Android, iOS, browser requests, ignored
client redirect values, disabled providers, and Google token rejection. It does
not authenticate a real Google user or deploy the controller.

References:

- https://developer.android.com/identity/legacy/gsi/offline-access
- https://developers.google.com/identity/sign-in/ios/offline-access
- https://github.com/googleapis/google-auth-library-php/blob/main/src/OAuth2.php

The standalone test optionally accepts a real Google Auth PHP autoloader as
its second argument. This additionally checks the library's redirect validation
without sending HTTP requests or using any real credentials.
