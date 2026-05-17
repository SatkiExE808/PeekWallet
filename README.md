# PeekWallet

A self-custodial, multi-coin mobile wallet. **Flutter rewrite** of [vault-wallet](https://github.com/SatkiExE808/vault-wallet) — same 12-word BIP39 seed, same on-chain wallets, but a native UI built directly on each platform instead of running in a WebView.

The original `vault-wallet` is built on Capacitor + JavaScript. That works well for BTC/ETH/SOL/etc. but the Monero engine (`monero-javascript` WASM) hangs in mobile WebViews — symptom: `…XMR` balance that never resolves. PeekWallet uses the native [`monero_c`](https://github.com/MrCyjaneK/monero_c) bindings via Dart FFI — the same library Cake Wallet uses — so Monero behaves like every other coin.

## Goals

- Cake-parity coin list: XMR, BTC, LTC, ETH, BCH, SOL, TRX, MATIC, plus a few exotics (XNO, DCR, WOW)
- Native Monero sync (no WebAssembly)
- Hardware-backed key storage (Keychain on iOS, Keystore on Android)
- Biometric unlock
- BIP39 12-word seed shared with vault-wallet (import via seed phrase)

## Status

Under active development. **Not ready for daily use.**

## Bundle ID

`com.vault.cryptowallet.dev` during development — coexists with vault-wallet on the same phone. Switches to the original `com.vault.cryptowallet` at release.

## Build

```bash
flutter pub get
flutter run                 # debug build on connected device
flutter build apk --release # signed APK for Android
flutter build ios --release # iOS (requires Xcode + signing)
```
