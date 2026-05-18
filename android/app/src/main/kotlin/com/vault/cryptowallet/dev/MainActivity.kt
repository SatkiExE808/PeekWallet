package com.vault.cryptowallet.dev

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity instead of FlutterActivity — required by
// local_auth so its BiometricPrompt can attach to a FragmentActivity
// host. Drop-in replacement; no behavior change beyond that.
class MainActivity : FlutterFragmentActivity()
