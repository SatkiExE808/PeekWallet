# Building PeekWallet

## Prerequisites

- **Flutter** 3.41.9 (pinned in CI; newer should work but isn't verified)
- **JDK 21** — Android Studio bundles one at
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`. Tell
  Flutter about it:
  `flutter config --jdk-dir "<path-from-above>"`
- **Android SDK** with cmdline-tools. Easiest:
  `brew install --cask android-commandlinetools`, then symlink
  `/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest`
  into `$ANDROID_HOME/cmdline-tools/latest`.
- **Xcode 26+** if you're building for iOS.

Run `flutter doctor` and resolve any reported issues before continuing.

## One-time setup

```bash
git clone https://github.com/SatkiExE808/PeekWallet
cd PeekWallet
flutter pub get
./scripts/prepare_monero.sh   # downloads ~211 MB monero_c bundle, extracts native libs
```

The prepare script is idempotent — re-running skips the download if
the bundle is already cached at `.cache/monero_c/`. It writes
`libmonero_wallet2_api_c.so` to `android/app/src/main/jniLibs/<abi>/`
for the three ABIs (arm64-v8a, armeabi-v7a, x86_64).

## Running

```bash
# Debug build on a connected device (USB or wireless ADB)
flutter run

# Release APK to test sideload
flutter build apk --release

# iOS (requires a Mac + Apple developer cert)
flutter build ios --release
```

## Code signing

CI signs with a persistent release keystore stashed in GitHub Secrets.
For local release builds, drop your own keystore in
`android/app/release.keystore` and create `android/key.properties`:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=release.keystore
```

`key.properties` and `*.keystore` are gitignored.

## One-time release-keystore setup (maintainers only)

Generate the keystore offline (once, ever):

```bash
keytool -genkey -v \
  -keystore peek-release.jks \
  -keyalg RSA -keysize 4096 -validity 25550 \
  -alias peek-release \
  -dname "CN=PeekWallet, O=PeekWallet, C=US"
```

Stash a base64 copy in GitHub secrets:

```bash
base64 -i peek-release.jks | pbcopy
```

Then in **GitHub → Settings → Secrets and variables → Actions** create:

| Name | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | the clipboard contents from above |
| `ANDROID_KEYSTORE_PASSWORD` | the keystore password you set |
| `ANDROID_KEY_ALIAS` | `peek-release` |
| `ANDROID_KEY_PASSWORD` | the key password you set |

The .jks file itself **must** be stored offline (encrypted backup,
hardware token, paper). Losing it means the next release won't be
installable as an upgrade over the previous one — every user has to
uninstall + reinstall. Treat it like the wallet seed.

## Tests

```bash
flutter analyze            # static analysis (zero issues required to pass)
flutter test               # all unit / widget tests
flutter test integration_test  # planned, not implemented yet
```

CI runs the first two on every push; merge gates on both passing.

## Reproducible builds (planned)

We aim to publish reproducible APKs so independent auditors can verify
the binary on /releases matches the public source. Current status:
**not yet reproducible**. Tracked in the roadmap under §9.2.
