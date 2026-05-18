# PeekWallet — Security Model

This document is the authoritative statement of what PeekWallet
defends against, what it doesn't, and the choices behind the
defenses. Every future security-relevant decision should be traceable
to a line in here.

---

## 1. Threat model

PeekWallet is built to defend against the following adversaries.
Anything not listed here is **explicitly out of scope** and should be
addressed by the user's broader operational security (device PIN,
biometrics, physical security of the recovery phrase, etc.).

### In scope

| Adversary | Capability | Defense |
|---|---|---|
| **Lost-phone thief** | Has physical device, screen locked | Device PIN/biometric (OS) + app password (us) |
| **Lost-phone thief, screen unlocked** | Has unlocked device for N minutes | App password gate on every cold start; auto-lock after 2 min in background; biometric prompt on lock screen |
| **Shoulder-surfer** | Sees screen briefly while user uses app | Obscured password fields; `flutter_windowmanager` FLAG_SECURE on Reveal-Seed screen prevents recents-thumbnail capture |
| **Other app on device** | Reads clipboard or shared storage | Sensitive copy auto-clears clipboard after 30 s; seed lives only in OS-backed secure storage |
| **Network eavesdropper (passive)** | Sniffs WiFi between phone and daemon | TLS required for the daemon URL (`usesCleartextTraffic="false"` enforced); cleartext HTTP rejected |
| **Network MITM (active, no rogue cert)** | Intercepts TLS | Mitigated — TLS cert validation against system trust roots |
| **Backup theft (paper)** | Reads written-down recovery phrase | Optional BIP39 passphrase ("25th word") binds the phrase to a second secret the user remembers |
| **Compromised daemon (read-only)** | Sees user's RPC pattern; cannot decrypt anything | View key never leaves the device; output decryption is local. Daemon learns "this IP scans these block ranges" — privacy issue, not fund-loss |

### Out of scope

| Adversary | Why we don't defend |
|---|---|
| **Root / kernel-level malware** | Bypasses every userspace defense. Out of scope for any non-HSM-backed app. |
| **Hardware key extraction** | Side-channel attacks against the OS secure-storage HSM are an OS-level problem. |
| **State-level coercion** | $5-wrench-attack defense is planned (decoy wallet — roadmap §2.6) but not yet implemented. |
| **Compromised daemon (active)** | A malicious daemon could lie about chain state, but cannot move funds (signing is local). It could omit incoming TXes from history responses; the user would see this as "balance hasn't gone up". |
| **Compromised dependency upstream** | Mitigated by Dependabot + manual review of monero_c version bumps; not fully eliminated. |
| **Quantum computer breaking ed25519** | Monero core's problem to solve first; we follow. |

---

## 2. Cryptographic primitives

| Primitive | Library | Parameters | Rationale |
|---|---|---|---|
| Password → seed key | `cryptography` (Dart) | PBKDF2-HMAC-SHA256, 200 000 iterations, 16-byte random salt | Industry default for password-based key derivation; iteration count tuned to ~500 ms on modern phones. Drop to 100 000 if we ever support old hardware. |
| Seed encryption | `cryptography` (Dart) | AES-256-GCM, 12-byte random nonce, 16-byte tag | Authenticated encryption — tamper detection is built in. AES-256 over AES-128 because the GCM nonce reuse risk grows with key size; 256 gives us full margin. |
| Password → wallet-file key | `cryptography` (Dart) | PBKDF2-HMAC-SHA256, 10 000 iterations, same salt as seed key | Defense in depth — the monero_c wallet file on disk is itself encrypted. Lower iter count because this is a secondary boundary; the main boundary is the seed blob. Context label `\|peek.wallet-file.v1` appended to the password input to keep the two derivations independent. |
| BIP39 mnemonic → seed bytes | `bip39` (Dart) | PBKDF2-HMAC-SHA512, 2048 iter, salt = `"mnemonic" + passphrase` | BIP39 spec, identical to vault-wallet, Cake, every other wallet. |
| Monero key derivation | pure Dart (this repo) | `sc_reduce`, `keccak256`, ed25519 base-point scalar mul | Port of vault-wallet's algorithm; pinned test vectors in `test/monero_keys_test.dart`. Matches what Cake / Feather / Monero GUI produce. |
| Random bytes | `dart:math` `Random.secure()` | 16-byte salt, 12-byte nonce per save | Uses OS RNG (`/dev/urandom` on Linux/Android, `SecRandomCopyBytes` on iOS/macOS, `BCryptGenRandom` on Windows). |
| Secure storage | `flutter_secure_storage` | Android: `encryptedSharedPreferences`. iOS: Keychain with `first_unlock` accessibility | OS-backed encryption-at-rest. On Android 6+ the keystore is hardware-backed where available. |

---

## 3. Defenses in depth

The user's recovery phrase is protected by **two independent boundaries**:

1. **OS-backed secure storage** — the encrypted seed blob lives in
   Android's Keystore-backed SharedPreferences or iOS Keychain. An
   attacker who reads the phone's filesystem without OS-level
   compromise sees only an opaque blob.

2. **Password-derived AES-GCM** — even with the blob in hand, the
   attacker needs the user's password to decrypt. PBKDF2 with 200k
   iterations makes online brute-force infeasible and offline brute-
   force expensive enough to deter low-effort attacks.

Both must fail before funds are at risk.

The on-disk monero_c wallet file (under `app docs/peek_xmr/<hash>/`)
is **separately encrypted** with a key derived from the same password
but a different PBKDF2 context — so even an attacker with both the
phone filesystem AND the encrypted-seed-blob from secure storage
can't trivially read the spend key out of the wallet file without
also brute-forcing the password.

---

## 4. Per-screen security stance

| Screen | Sensitive material visible | Defenses |
|---|---|---|
| **Welcome** | None | — |
| **Create wallet → show phrase** | 12 BIP39 words | FLAG_SECURE applied; warning banner; copy auto-clears in 30 s |
| **Create wallet → confirm quiz** | None (user types from memory) | — |
| **Create wallet → set password** | Password input (obscured) | Standard obscured TextField |
| **Lock screen** | Password input (obscured) | Rate-limit (planned, roadmap §2.5) |
| **Reveal seed** | 12 BIP39 words + Monero spend/view keys (hex) + primary address | Password re-prompt regardless of unlock state; FLAG_SECURE applied; copy auto-clears in 30 s |
| **Coin screen** | Public address (not sensitive); balance | FLAG_SECURE NOT applied — balance visibility is intentional |
| **Receive sheet** | Public addresses + QR | Public — no extra defense |
| **Send screen → confirm** | Recipient + amount + fee | FLAG_SECURE applied so the confirm step doesn't leak via recents thumbnail |
| **Settings → Monero node** | Node URL (user-entered) | — |
| **Settings → Reveal seed** | (see "Reveal seed" above) | (see "Reveal seed" above) |

---

## 5. Persistence boundaries

| What | Where | Encrypted? |
|---|---|---|
| Encrypted seed blob | OS secure storage (Keystore/Keychain) | Yes — AES-GCM with PBKDF2-derived key |
| Biometric password stash | OS secure storage (Keystore/Keychain), separate key | OS-encrypted (no second app-layer encryption — the biometric IS the gate) |
| Monero wallet file (cache + spend key) | `app docs/peek_xmr/<addr-hash>/wallet.*` | Yes — monero_c encrypts with our derived wallet-file password |
| User preferences (daemon URL) | OS secure storage | Just because we already use it; not security-sensitive |
| Subaddress labels | Inside the monero_c wallet file | Yes — same encryption as the wallet file |
| Transaction notes (planned) | Inside the monero_c wallet file | Yes — same |
| Address book (planned) | Encrypted vault entry | Yes — separate AES-GCM blob keyed off the same password |

The plaintext mnemonic and passphrase exist **only in memory** after
unlock, never on disk. Lock event clears them and tears down the
monero_c wallet.

---

## 6. Network exposure

PeekWallet makes outbound HTTPS connections to exactly one class of
endpoint: a user-configured Monero daemon. The daemon URL is shown
in Settings → Monero Node. Default is Cake's public node; user can
override with their own monerod or a known-CORS-friendly proxy.

PeekWallet does **NOT** make connections to:

- Analytics services (none integrated)
- Crash reporters (none integrated)
- Auto-update servers (we don't auto-update; user downloads new APK manually)
- App-developer telemetry (none)
- Price oracles (planned for fiat conversion — roadmap §5.8; will be opt-in)

`AndroidManifest.xml` explicitly sets `usesCleartextTraffic="false"` —
an attacker tricking the user into setting `http://...` as the daemon
URL will see Wallet_init fail at the network layer.

---

## 7. Build & supply-chain security

- Source is on GitHub at `SatkiExE808/PeekWallet`. Every commit
  signed via the GitHub web UI (HTTPS-authenticated).
- CI runs `flutter analyze` (zero issues required), `flutter test`
  (all green required), and `flutter build apk --release`.
- Release APK signed with a persistent keystore stashed in GitHub
  repo secrets. The keystore itself is held offline by the maintainer.
- Reproducible builds: **not yet** — tracked in the roadmap. Until
  reproducibility lands, the binary on /releases is technically
  unverifiable. Build from source for full assurance.
- Dependencies pinned in `pubspec.lock`. Monero_c pinned to commit
  `bc8d1a0b75b97156d71579581b4cdfe58c777ed2`.
- Dependabot: TODO.

---

## 8. Auditing

| Audit | Date | Findings |
|---|---|---|
| Internal 1-hour audit | 2026-05-18 | 13 issues identified, 13 fixed (see `docs/audit-2026-05-18.md` — TODO) |
| Internal 24-hour scoping audit | 2026-05-18 | 85 items roadmapped across 15 domains (see `docs/roadmap.md` — TODO) |
| External security audit | — | **Not yet performed.** A real audit (Cure53, Trail of Bits, NCC) is on the roadmap once the codebase stabilizes after Phase 2. |

---

## 9. Reporting a vulnerability

Open a private security advisory at
https://github.com/SatkiExE808/PeekWallet/security/advisories/new

Do **not** file a public issue for security bugs — give us time to
patch before disclosure.

If GitHub's security advisories aren't available to you, email a
maintainer directly (contact in the repo profile). Use the GPG key
published there if you want the report encrypted in transit.

---

## 10. Open security questions

These are known unknowns we're still working through. Listing them
here so contributors can challenge them:

- **TLS pinning for the daemon**: the community-node model makes
  pinning incompatible with user choice. Accepting the privacy loss
  for now; revisit if a "trusted node mode" emerges.
- **Side-channel resistance of pure-Dart ed25519**: our BigInt-based
  scalar multiplication is not constant-time. Mitigated by the fact
  that the private key never participates in user-observable timing
  (signing happens behind monero_c's native code, which has its own
  constant-time implementation). The Dart code only derives the
  address — leaking timing of address-derivation reveals nothing
  useful.
- **Biometric password stash threat model**: stashing the master
  password in Keystore-backed storage exposes it to anyone who
  defeats the device's biometric layer (e.g., spoofed fingerprint).
  This is the same tradeoff every wallet-with-biometric-unlock makes.
  Users who want maximum security should leave biometric off.
- **Memory disclosure on dispose**: Dart's GC may leak references to
  the decrypted mnemonic past `VaultState.lock()`. We set `_mnemonic
  = null` but the underlying String object may persist in the heap
  until the next GC pass. Mitigated by the OS killing the app
  process on background; not eliminated.
