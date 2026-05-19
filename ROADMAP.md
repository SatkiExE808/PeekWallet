# PeekWallet Roadmap

Items larger than a single PR. Tracked here so the README + commit
log stay focused on what's actually shipping today.

## Soon

### iOS support
Status: scaffolded, not verified.

What's needed:
- `scripts/prepare_monero.sh` already fetches Android `.so` artifacts;
  add the iOS xcframework path (monero_c publishes prebuilts).
- Verify the iOS `flutter_secure_storage` Keychain accessibility
  setting (`first_unlock`) survives device reboots, and the biometric
  stash round-trips through Touch ID / Face ID.
- Update `ios/Runner/Info.plist` with NSCameraUsageDescription,
  NSFaceIDUsageDescription, NSPhotoLibraryUsageDescription strings.
- Sign + provisioning profile for the dev bundle id
  `com.vault.cryptowallet.dev`.
- Test FLAG_SECURE equivalent — iOS doesn't have one, so the
  `ScreenshotGuard` already implements a blur-on-inactive treatment
  via `WidgetsBindingObserver`. Needs device verification that the
  blur fires before the recents-thumbnail is captured.

### Internationalization
Status: not started. The codebase has zero externalized strings.

What's needed:
- Add `flutter_localizations` + `intl` to `pubspec.yaml`.
- Run `flutter gen-l10n` with an `l10n.yaml` config; `.arb` files
  under `lib/l10n/`.
- Bulk-extract user-visible strings (start with home, coin screens,
  send screens, lock screen).
- First-pass translations for the user base:
  - **zh-Hant** (Traditional Chinese — HK/TW users)
  - **ms** (Bahasa Malaysia — MY users)
  - **vi** (Vietnamese)
  - **id** (Bahasa Indonesia)
- Wire `MaterialApp.localizationsDelegates` + `supportedLocales`.

### Performance profiling
Status: anecdotal only. No measurements yet.

What's needed (requires a real device):
- Cold-start time measurements with `flutter run --profile`.
- Frame timing on the wallets list while balances are auto-loading.
- Memory profile during XMR sync (monero_c keeps the chain cache in
  memory; 4M+ blocks can be hefty on low-RAM devices).
- Network call count audit per refresh — currently the wallets list
  fans out one balance probe per wallet × per refresh.

## Later

### Hardware wallet integration
Ledger HID via USB OTG (Android) + Lightning (iOS). The BIP84
derivation paths already align with Ledger Live; what's needed is the
APDU transport layer + sign-tx confirmation UI.

### CoinJoin / privacy-preserving mixing
Whirlpool-style mixing for BTC. Significant work — needs a
coordinator, fee estimation, and UX around the mixing lifecycle.

### Lightning Network
LDK-node embedded; channel management UI. Out of scope for now.

### Atomic swaps
COMIT / Boltz for XMR ↔ BTC. Requires a coordinator and HTLC
plumbing.

## Tracked but not planned

- Web build — Flutter web works, but secure storage + monero_c don't.
- Desktop builds — would need a different threat model (no
  hardware-backed key storage).
- ENS / Unstoppable Domains resolution — privacy concern (DNS
  leakage); reconsider when the privacy story for HTTPS itself
  improves (Tor support).

## Won't do

- Account abstraction / smart-contract wallets — out of scope for
  a self-custodial wallet focused on EOAs + multi-chain coverage.
- DeFi swap aggregator — keep PeekWallet a wallet, not a DEX
  frontend. Users can paste an address into Uniswap/Jupiter/Ston.fi
  themselves.
- Cloud backup of seeds — opposite of self-custody. The recovery
  phrase IS the backup.
