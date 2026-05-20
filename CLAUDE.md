# PeekWallet — conventions

Read `ARCHITECTURE.md` for the layer map. This file is the short list
of **patterns to follow** when changing code so future sessions don't
have to re-derive them.

## Workflow

- **Commit + push after each meaningful change**, not at the end of a
  large batch. The CI workflow at `.github/workflows/build-apk.yml`
  publishes a fresh APK on every push to `main`; commits are how
  Hong reviews + tests on-device.
- **Pre-commit:** `flutter analyze --no-fatal-warnings` clean +
  `flutter test` clean. CI uses `flutter analyze` with `--fatal-infos`
  on by default — even info-level lints break the build. Don't ship
  a commit with deprecated-API warnings.
- Use `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`
  trailer.
- **Never probe external hosts from the Mac mini.** No `curl` /
  `ping` / `nc`. Use `gh` (auth'd), `flutter` (no net at analyze
  time), or `WebFetch` (routes via Anthropic). Memory entry:
  `[[feedback-no-outbound-network-from-local]]`.

## Design tokens — use `PeekDesign` and `PeekColors`, no literals

Every visible surface consumes `lib/theme.dart` tokens.

- **Radii:** `PeekDesign.brHero (24)`, `brCard (18)`, `brButton (14)`,
  `brInput (14)`, `brSmall (10)`, `brPill (999)`. Never write
  `BorderRadius.circular(8)` etc.
- **Spacing scale:** `PeekDesign.sp1..sp10` (4-pixel multiples). Use
  `sp3` (12), `sp4` (16), `sp5` (20), `sp6` (24) most often.
- **Motion:** `PeekDesign.tFast (140ms)`, `tMed (220ms)`, with
  `PeekDesign.easeOut`.
- **Colors:** `PeekColors.{bg, bg2, surface, surface2, accent,
  accentMuted, text, text2, text3, red, green, hairline}`. Never
  `Color(0x...)` literals. Errors → `red` with `.withAlpha(28)` for
  background + `.withAlpha(96)` for border.

## Shared widgets — reuse, don't reimplement

`lib/widgets/`:

| Widget | Use it for |
|---|---|
| `StatusPill` | Cache / sync / error indicators below balance |
| `ActionButton` | Receive/Send + any other pill-shaped CTA |
| `EmptyActivity` | "No transactions yet" empty state on coin screens |
| `SectionHeader` | "Activity" / "Tokens" headers |
| `SettingsRow` / `SettingsSwitchRow` | Every row in Settings + sub-screens |
| `ExperimentalBanner` / `SendErrorTile` | Send-screen warning + error tile |
| `showReceiveSheet()` | Receive sheet (every coin) |
| `showTxDetailSheet()` | Tx detail bottom sheet (every coin) |

If you need a variant, **extend the shared widget** with a flag —
don't fork it inline. Per-screen forks drift over time.

## Network clients — multi-provider fallback pattern

Every chain's network client accepts a **list** of base URLs and
tries each in turn on transient failure (5xx, 429, timeout, socket,
TLS handshake). 4xx propagates immediately — same client-side error
would just repeat on the next mirror.

```dart
Future<T> _tryAll<T>({required String path, ...}) async {
  Object? lastErr;
  for (final base in _bases) {
    try {
      final r = await _http.get(Uri.parse('$base$path')).timeout(...);
      if (r.statusCode >= 500) { lastErr = ...; continue; }
      if (r.statusCode != 200) throw _ApiError(r.statusCode, base);
      return parse(r.body);
    } on SocketException { ... }
    on TimeoutException { ... }
  }
  throw lastErr ?? Exception('All endpoints failed');
}
```

User-pinned overrides (via `RpcOverrides.I.get(coinId, kind)`) go
**first** in the URL list, then the chain's public defaults. So a
user with a working pin always uses it; if the pin fails they get
the public fallback transparently.

When adding a new chain or endpoint, follow the same shape — don't
hand-roll single-URL HTTP in a user-facing path.

## Seed material extraction

Every BIP39-based module's `open()` extracts the mnemonic via
`extractBip39Mnemonic(seedMaterial, coinSymbol: 'XYZ')` from
`lib/wallets/seed_format.dart`. Throws a clear FormatException when
the wallet record is wrong-shape (e.g. a Monero 25-word wallet got
routed to an EVM module). **Never** blind-cast
`seedMaterial['mnemonic'] as String`.

## Logging — `PeekLogger.I.log(tag, msg)`, never `print()`

Errors and lifecycle events route through `lib/util/peek_logger.dart`,
which redacts mnemonics + XMR addresses + hex keys before writing to
the rolling log. `print()` bypasses redaction → leaks to logcat /
`flutter logs` → screenshot ends up on a support ticket. Don't do it.

Tags are lowercase chain ids: `'btc'`, `'xmr'`, `'wallet_store'`,
`'update'`, `'vault'`.

## Cache fallback pattern

Every coin screen pre-fills the balance from `BalanceCache` on
`_open()`. The cached value stays visible while the live RPC call
is in flight; if the call fails, the cached value stays AND an error
is surfaced via `StatusPill`. Cache freshness threshold is **5
minutes** — newer than that, the "Cached" pill is suppressed (the
spinner alone signals "loading"). See `bitcoin_coin_screen.dart`
`_open()` for the reference implementation.

## Receive-address rotation (BTC/LTC)

`BitcoinWallet.nextReceiveAddress` walks the gap-limit window and
returns the lowest-index address with zero received funds. Used by
the receive sheet so each session shows a fresh address. Falls back
to `primaryAddress` on first open (before `_refresh()` populates
the per-address cache) and when the gap-limit window is exhausted.

Other coins (ETH, SOL, TRX, BCH, XMR) use account-based or
subaddress-based models — they don't need this pattern.

## i18n

Strings flow through `AppLocalizations.of(context)`. Source-of-truth
catalog is `lib/l10n/app_en.arb`; sibling files for `zh-Hant`, `ms`,
`vi`, `id`. `flutter pub get` triggers code generation into
`lib/l10n/gen/`. Wire new screens through the generated class —
don't inline English literals on user-visible surfaces.

Adding a new key: edit `app_en.arb`, run `flutter gen-l10n`, then
add the translation to each sibling `.arb`. Untranslated keys fall
back to English at runtime.

## Audit fixes that established invariants

Don't undo these without thinking — they each closed a real bug:

- `MempoolClient.broadcast` propagates 4xx immediately (real
  rejection); retries 5xx across mirrors.
- BTC/LTC send change address uses the **internal** chain
  (`m/84'/coin'/0'/1/idx`) with a per-tx-derived index — never the
  receive chain.
- `BitcoinWallet.sendBitcoin` throws on txid mismatch between local
  computation and explorer response — sign of malleation or RPC
  mishandling, do not swallow.
- ETH cached-balance restore uses string→wei math (not `coins * 1e18`).
- `PriceFeed` iterates the forward CoinGecko ID map (one ID → many
  symbols possible, e.g. POL + WMATIC both map to
  `polygon-ecosystem-token`); never invert.

## Coin id is **POL**, not MATIC

Polygon migrated 2024-09. Legacy `coinId: 'MATIC'` in stored
`WalletMeta` records is rewritten to `'POL'` on load by
`WalletMeta.fromJson._renameLegacy`. Same for `RpcOverrides` keys.
Don't add new code paths that special-case `'MATIC'`.
