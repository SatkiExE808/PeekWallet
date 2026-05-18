# PeekWallet — No-Warranty Disclaimer

**Last updated:** 2026-05-18

PeekWallet is **free, open-source, self-custodial software**, released
under the GNU General Public License v3.0 (see [LICENSE](LICENSE)).

By installing or using PeekWallet you acknowledge each of the following.

## 1. No warranty

The software is provided **"AS IS", without warranty of any kind**,
express or implied, including but not limited to the warranties of
merchantability, fitness for a particular purpose and noninfringement.

No author, contributor or maintainer of PeekWallet shall be liable for
any claim, damages or other liability, whether in an action of contract,
tort or otherwise, arising from, out of or in connection with the
software or the use or other dealings in the software.

## 2. Self-custody — you are the bank

PeekWallet generates and stores the cryptographic keys that control
your funds. **There is no central authority that can recover them.**

- **If you lose your 12-word recovery phrase** (or the 25-word Monero
  seed, polyseed, or private spend key, depending on how the wallet was
  created), your funds are unrecoverable. We cannot help you. Nobody
  can.
- **If you forget your app password** but still have your recovery
  phrase, you can re-import the wallet and pick a new password.
- **If someone else gets your recovery phrase**, they can drain the
  wallet. Treat the phrase like an unlimited bearer cheque.

## 3. No customer support, no recovery service

PeekWallet has **no central support channel** with the ability to access
your funds. Anyone offering "wallet recovery" or "PeekWallet support" in
exchange for your recovery phrase is attempting to steal your funds. We
will never ask for your recovery phrase, password, or private keys.

The closest thing to support is the GitHub issue tracker, which is
limited to bug reports and feature requests.

## 4. Cryptocurrency risk

Cryptocurrency values are volatile and may decline rapidly. Regulatory
treatment of cryptocurrency varies by jurisdiction and may change.
Sending to the wrong address, or to an address on the wrong network, is
**irreversible**. PeekWallet performs basic address-format validation
but cannot detect typos in valid-looking addresses.

## 5. Software risk

PeekWallet is under active development. It may contain bugs that result
in **loss of funds**. Audits to date are:

- 1-hour internal audit (2026-05-18): 13 issues identified, 13 fixed
- 24-hour internal scoping review (2026-05-18): roadmap published
- **No external security audit yet**

The cryptographic primitives PeekWallet relies on are well-established
(BIP39, PBKDF2-HMAC-SHA256, AES-GCM-256, ed25519, Keccak-256) and used
by every major cryptocurrency wallet. The **integration of those
primitives** is custom code in this repository and has not been
externally reviewed.

Do not store more cryptocurrency in PeekWallet than you can afford to
lose to a software bug.

## 6. Privacy

PeekWallet is privacy-focused but not anonymity-providing.

- **Daemon connection**: by default PeekWallet talks to a public Monero
  node. That node's operator sees your IP address. They cannot decrypt
  your transactions, but timing correlation with on-chain activity is
  possible. For better privacy, run your own monerod and configure
  PeekWallet to use it, or route via Tor (planned, see roadmap).
- **App permissions**: PeekWallet requests `INTERNET`,
  `ACCESS_NETWORK_STATE`, and `USE_BIOMETRIC` on Android. No
  location, no contacts, no SMS, no analytics, no crash reporting.
- **Clipboard**: when you tap "Copy address" or "Copy seed", that data
  enters the system clipboard. Other apps with clipboard access can
  read it. PeekWallet auto-clears the clipboard 30 seconds after
  copying sensitive material.

## 7. Compliance is your responsibility

Tax reporting, KYC, sanctions, and other legal obligations in your
jurisdiction are **your responsibility**. PeekWallet does not produce
tax-export files, does not perform KYC, and cannot tell you whether
cryptocurrency is legal in your country.

## 8. License

PeekWallet is licensed under GPL-3.0-or-later. You may:

- Use it for any purpose
- Study how it works (read the source)
- Modify it
- Redistribute it
- Distribute your modifications

You **must** provide source code (or a written offer to do so) to anyone
you give a binary to. See [LICENSE](LICENSE) for the full text.

---

Questions? Open an issue at https://github.com/SatkiExE808/PeekWallet
