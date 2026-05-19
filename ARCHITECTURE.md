# PeekWallet Architecture

How the codebase is laid out. Read this once before making non-trivial
changes so you know which layer a given concern belongs in.

## Layer overview

```
┌──────────────────────────────────────────────────────────────┐
│  Flutter UI (lib/screens/, lib/widgets/, lib/theme.dart)     │
│  • Material 3 + custom PeekDesign tokens                     │
│  • One screen per coin + shared sheets (receive, tx detail)  │
├──────────────────────────────────────────────────────────────┤
│  Coin modules (lib/coins/<chain>/)                           │
│  • CoinModule interface — generateNew / restoreFrom / open   │
│  • Per-chain wallet runtime (BitcoinWallet, EthereumWallet…) │
├──────────────────────────────────────────────────────────────┤
│  Network clients (per chain)                                 │
│  • MempoolClient, BlockchairExplorer, EthRpcClient,          │
│    EtherscanClient, SolanaRpcClient, TronGridClient, …       │
│  • Each accepts a list of URLs; tries them in order on 5xx   │
├──────────────────────────────────────────────────────────────┤
│  Vault + WalletStore (lib/vault/, lib/wallets/)              │
│  • AES-GCM + PBKDF2-encrypted seed material                  │
│  • flutter_secure_storage backing (Keychain/Keystore)        │
│  • Biometric stash for fingerprint unlock                    │
├──────────────────────────────────────────────────────────────┤
│  Platform integrations                                       │
│  • monero_c FFI (Android jniLibs/, iOS WIP)                  │
│  • mobile_scanner for QR scanning                            │
│  • local_auth for biometric                                  │
│  • share_plus for native share intent                        │
└──────────────────────────────────────────────────────────────┘
```

## Vault + WalletStore

`lib/vault/` and `lib/wallets/` together hold every key the app ever sees.

- **`VaultStorage`** wraps `flutter_secure_storage`. Stores the
  AES-GCM ciphertext of the seed material. The master password is
  PBKDF2-stretched (200k iterations) to derive the AES key.
- **`VaultState`** is the in-memory singleton that holds the
  *decrypted* mnemonic after unlock. Cleared on lock + on inactivity
  timeout.
- **`WalletStore`** is a multi-wallet store: each wallet has its own
  encrypted blob plus a `WalletMeta` (id, name, coinId, format,
  primary address, restore height). Walletfile-level password is
  derived from `(masterPassword, walletId)` so the same master
  password decrypts every wallet without collision.
- **`BiometricAuth` + biometric stash**: if the user opts in, the
  master password is also stored encrypted under the OS biometric
  key, so fingerprint unlock can retrieve it without re-prompting.

## Coin modules

Each chain implements `CoinModule` in `lib/coins/<chain>/<chain>_module.dart`.

```dart
abstract class CoinModule {
  String get id;         // 'BTC', 'XMR', 'POL', …
  String get name;       // 'Bitcoin', 'Monero', 'Polygon', …
  String get symbol;     // 'BTC', 'XMR', 'POL', …
  Color get color;
  IconData get icon;
  List<SeedFormat> get supportedCreateFormats;
  List<SeedFormat> get supportedRestoreFormats;
  Future<NewWalletMaterial> generateNew(...);
  Future<RestoredWalletMaterial> restoreFrom(...);
  Future<dynamic> open(...);   // returns the chain's wallet handle
}
```

Modules are registered in `lib/coins/module_registry.dart`. The
wallets list maps `meta.coinId` → module via `coinModuleFor()`.

Concrete wallet runtimes:

| Chain | Module | Wallet handle |
|-------|--------|---------------|
| XMR | `MoneroModule` | `MoneroWallet` (FFI) |
| BTC, LTC | `BitcoinModule`, `LitecoinModule` (share `BitcoinChainParams`) | `BitcoinWallet` |
| ETH, POL | `EthereumModule`, `PolygonModule` (share `EvmCoinModule`) | `EthereumWallet` |
| SOL | `SolanaModule` | `SolanaWallet` |
| TRX | `TronModule` | `TronWallet` |
| BCH | `BitcoinCashModule` | `BitcoinCashWallet` |

## Network clients (multi-provider resilience)

Every chain's HTTP client accepts a **list** of base URLs and tries
them in order on transient failure (HTTP 5xx, 429, timeout, socket,
TLS). A user-pinned Custom RPC stays first; the chain's public
mirrors follow as the safety net.

- **BTC / LTC**: `MempoolClient` (mempool.space-API-compatible URLs)
  composed via `CompositeExplorer` with `BlockchairExplorer` as a
  different-API fallback. LTC has only one Esplora mirror so the
  Blockchair adapter is the real cross-provider resilience.
- **ETH / POL**: `EthRpcClient` (JSON-RPC) + `EtherscanClient`
  (Blockscout/Etherscan-compat read API), each with 3-4 fallback
  endpoints.
- **SOL**: `SolanaRpcClient` (mainnet-beta + PublicNode + Blast + Ankr).
- **TRX**: `TronGridClient` (REST). Only TronGrid is a viable public
  endpoint; retry-with-fallback architecture is in place for when more
  mirrors emerge.
- **BCH**: `BlockchairBchClient`.

The pattern is the same everywhere: a private `_tryAll(...)` or
`_try(...)` helper iterates the URL list, retries on infra failures,
propagates 4xx immediately (the next mirror would just return the
same client-side error).

## UI layer

`lib/theme.dart` exposes two singletons:

- **`PeekColors`** — color palette (dark surfaces + orange accent).
- **`PeekDesign`** — radii (`brCard 18`, `brHero 24`, `brSmall 10`,
  `brPill`), spacing scale (`sp1..sp10` in 4-pixel multiples), motion
  (`tFast 140ms`, `tMed 220ms`), shadows, gradients.

Every screen, modal, and tile consumes these tokens — no hardcoded
`Color(0x...)` or `BorderRadius.circular(8)` literals in `lib/screens/`.

### Shared widgets (`lib/widgets/`)

| Widget | Used by |
|--------|---------|
| `coin_screen_widgets.dart` (StatusPill, ActionButton, EmptyActivity, SectionHeader) | every coin screen, send screens |
| `receive_sheet.dart` (showReceiveSheet) | every coin screen's Receive button |
| `tx_detail_sheet.dart` (showTxDetailSheet) | every coin screen's tx tap |
| `settings_row.dart` (SettingsRow, SettingsSwitchRow) | Settings + sub-screens |
| `send_widgets.dart` (ExperimentalBanner, SendErrorTile) | every send screen |

### Screen inventory

| Screen | File | Notes |
|--------|------|-------|
| Wallets list | `wallets_screen.dart` | hero portfolio card, refined rows |
| Coin screens | `bitcoin_coin_screen.dart`, `ethereum_coin_screen.dart`, `solana_coin_screen.dart`, `tron_coin_screen.dart`, `bch_coin_screen.dart`, `coin_screen.dart` (XMR) | hero card + pill actions + status pill + activity list |
| Send screens | `send_bitcoin_screen.dart`, `send_bch_screen.dart`, `send_ethereum_screen.dart`, `send_solana_screen.dart`, `send_tron_screen.dart`, `send_xmr_screen.dart` | form → preview hero → broadcast |
| Add wallet | `add_wallet/add_wallet_flow.dart` | coin picker → format picker → create / restore / keys-restore |
| Settings | `settings_screen.dart`, `rpc_overrides_screen.dart`, `about_screen.dart`, `address_book_screen.dart` | |
| Auth | `lock_screen.dart`, `welcome_screen.dart` | |
| Sensitive | `reveal_seed_screen.dart`, `show_wallet_seed_screen.dart` | FLAG_SECURE applied |

## Resilience patterns

Two patterns recur across coins:

1. **Multi-provider fallback** — every network client accepts a URL
   list, tries each on transient failure. See the Network clients
   section above.
2. **Cache fallback** — every coin screen pre-fills its balance from
   `BalanceCache` on `_open()`, keeps the cached value visible if the
   live fetch fails, surfaces a "⚠ Cached value (3 min ago)" pill.
   The cache lives in `flutter_secure_storage` keyed by walletId.

The combination means: a single explorer outage shows the user a
slightly-stale balance with a clear indicator, instead of an empty
"… BTC" placeholder.

## Testing

`test/` covers crypto primitives (BIP39 derivation, BIP143 sighashes,
ed25519 SLIP-0010), Monero key derivation against spec vectors, vault
storage round-trips, and wallet store mutations.

UI widget tests are limited — the visual surface is verified
manually on Android during development.

## What's NOT here yet

- **iOS support** — Android `jniLibs/` ships the monero_c .so; iOS
  needs the xcframework path through `prepare_monero.sh`. Keychain
  + iOS biometric plumbing is partially in place but unverified.
- **Hardware wallet integration** — Ledger HID is on the roadmap;
  the BIP84 derivation paths already align with Ledger Live.
- **Internationalization** — strings are inline English. The
  user base skews HK/MY/SG/TW so zh-Hant/ms/vi are next.

## Conventions

- New chains: add a `lib/coins/<chain>/` directory matching the
  shape of `lib/coins/solana/` (module, keys, wallet, rpc client,
  tx builder). Wire into `lib/coins/module_registry.dart`.
- New UI surfaces: consume `PeekDesign` tokens. Don't add
  hardcoded radius/color/spacing literals.
- New errors: surface via `PeekLogger.I.log(coinId, msg)` so they
  appear in the redacted log export. Don't `print()` raw.
- New network calls: route through a `_tryAll`-style helper if the
  client doesn't already have one. Don't hand-roll single-URL HTTP
  in user-facing paths.
