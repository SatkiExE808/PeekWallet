// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PeekWallet';

  @override
  String get lockScreenSubtitle => 'Enter your password to unlock';

  @override
  String get lockPasswordHint => 'Password';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get lockUseBiometric => 'Use biometric';

  @override
  String get lockTooManyAttempts => 'Too many failed attempts';

  @override
  String get lockTimerWarning =>
      'Locking your phone or restarting the app won\'t reset the timer — this is intentional.';

  @override
  String get walletsTitle => 'My Wallets';

  @override
  String get walletsRefreshTooltip => 'Refresh balances';

  @override
  String get walletsAddTooltip => 'Add wallet';

  @override
  String get homeTotalBalance => 'Total balance';

  @override
  String homeSyncedCount(int counted, int total) {
    return '$counted / $total synced';
  }

  @override
  String homeAcrossWallets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'across $count wallets',
      one: 'across 1 wallet',
    );
    return '$_temp0';
  }

  @override
  String get homeEmptyTitle => 'No wallets yet';

  @override
  String get homeEmptyBody =>
      'Create a fresh wallet or restore from a recovery phrase to get started.';

  @override
  String get homeAddWallet => 'Add wallet';

  @override
  String get actionReceive => 'Receive';

  @override
  String get actionSend => 'Send';

  @override
  String get actionBack => 'Back';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionShare => 'Share';

  @override
  String get actionExplorer => 'Explorer';

  @override
  String get actionSending => 'Sending…';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String receiveTitle(String coinId) {
    return 'Receive $coinId';
  }

  @override
  String get receiveAddressLabel => 'YOUR ADDRESS';

  @override
  String get receiveAddressCopied => 'Address copied';

  @override
  String get receiveCopiedToClipboard => 'Copied to clipboard';

  @override
  String get receiveCouldNotOpenBrowser => 'Could not open browser';

  @override
  String coinScreenBalanceLabel(String symbol) {
    return '$symbol balance';
  }

  @override
  String get coinScreenActivityTitle => 'Activity';

  @override
  String get coinScreenTokensTitle => 'Tokens';

  @override
  String get coinScreenNoTxYet => 'No transactions yet';

  @override
  String coinScreenShareAddressHint(String symbol) {
    return 'Share your address to receive $symbol';
  }

  @override
  String get coinScreenLoading => 'Loading…';

  @override
  String get coinScreenRefreshTooltip => 'Refresh';

  @override
  String get coinScreenAddTokenLabel => 'Add token';

  @override
  String balanceCached(String ago) {
    return 'Cached · $ago ago';
  }

  @override
  String balanceCachedShort(String ago) {
    return 'Cached · $ago';
  }

  @override
  String balanceCouldNotOpen(String error) {
    return 'Could not open wallet: $error';
  }

  @override
  String get balanceVaultLocked => 'Vault is locked.';

  @override
  String get ageJustNow => 'just now';

  @override
  String ageMinutes(int n) {
    return '$n min';
  }

  @override
  String ageHours(int n) {
    return '$n hr';
  }

  @override
  String ageDays(int n) {
    return '$n d';
  }

  @override
  String get txDirectionIncoming => 'Incoming';

  @override
  String get txDirectionOutgoing => 'Outgoing';

  @override
  String get txStatusConfirmed => 'Confirmed';

  @override
  String get txStatusPending => 'Pending';

  @override
  String get txStatusFailed => 'Failed';

  @override
  String get txStatusInMempool => 'In mempool';

  @override
  String get txCopiedToClipboard => 'Copied to clipboard';

  @override
  String get txIdLabel => 'TX ID';

  @override
  String get txHashLabel => 'Hash';

  @override
  String get txSignatureLabel => 'Signature';

  @override
  String get txAmountLabel => 'Net amount';

  @override
  String get txFeeLabel => 'Fee';

  @override
  String get txGasFeeLabel => 'Gas fee';

  @override
  String get txNetworkFeeLabel => 'Network fee';

  @override
  String get txBlockHeightLabel => 'Block height';

  @override
  String get txSlotLabel => 'Slot';

  @override
  String get txDateLabel => 'Date';

  @override
  String get txTokenLabel => 'Token';

  @override
  String get txCounterpartyLabel => 'Counterparty';

  @override
  String get sendFormRecipientLabel => 'Recipient address';

  @override
  String get sendFormAmountLabel => 'Amount';

  @override
  String get sendFormMaxButton => 'Max';

  @override
  String get sendFormBookTooltip => 'From address book';

  @override
  String get sendFormScanTooltip => 'Scan QR';

  @override
  String get sendFormPasteTooltip => 'Paste from clipboard';

  @override
  String get sendFormFeePriorityLabel => 'FEE PRIORITY';

  @override
  String get sendFormAvailableLabel => 'available';

  @override
  String get sendFormConfirmHint => 'Type SEND to confirm';

  @override
  String get sendFormConfirmPlaceholder => 'SEND';

  @override
  String get sendFormErrorInvalidAmount => 'Enter a valid amount';

  @override
  String get sendFormErrorAmountExceedsBalance =>
      'Amount + fee exceeds balance';

  @override
  String get sendFormErrorRecipientRequired => 'Recipient address is required';

  @override
  String get sendFormWillBeSentTo => 'will be sent to';

  @override
  String get sendFormToLabel => 'To';

  @override
  String get tronTokensTitle => 'Tokens (TRC-20)';

  @override
  String get splTokensTitle => 'Tokens (SPL)';

  @override
  String get erc20TokensTitle => 'Tokens';

  @override
  String experimentalSendWarning(String symbol) {
    return 'Send is experimental — test with small amounts before moving meaningful $symbol.';
  }

  @override
  String sendScreenTitle(String coinName) {
    return 'Send $coinName';
  }

  @override
  String sendScanTitle(String symbol) {
    return 'Scan $symbol address';
  }

  @override
  String sendBtcAmountLabel(String symbol) {
    return 'Amount ($symbol or sat)';
  }

  @override
  String sendBroadcastSuccess(String prefix) {
    return 'Broadcast! txid: $prefix…';
  }

  @override
  String get sendBtcLoadingUtxos => 'Loading UTXOs…';

  @override
  String sendBtcUtxoError(String error) {
    return 'UTXO error: $error';
  }

  @override
  String get sendBtcAvailableHint => 'available · confirmed UTXOs only';

  @override
  String sendBtcFeeRatesError(String error) {
    return 'Fee rates unavailable: $error';
  }

  @override
  String get sendBtcLoadingFeeRates => 'Loading fee rates…';

  @override
  String get sendBtcFinalFeeHint =>
      'Final fee + change will be shown after broadcast. Once submitted to the network it CANNOT be reversed.';

  @override
  String get sendBtcExperimentalBody =>
      'send is BIP-0143 spec-vector tested but has not been audited end-to-end.';

  @override
  String sendBtcOnlyBech32(String prefix) {
    return 'Only bech32 P2WPKH ($prefix…) addresses are supported';
  }

  @override
  String sendBtcExceedsBalance(int available) {
    return 'Amount exceeds confirmed balance ($available sat)';
  }

  @override
  String get sendBtcFeeRateLabel => 'Fee rate';

  @override
  String get sendBtcFeeTierFastest => 'Fastest';

  @override
  String get sendBtcFeeTierHalfHour => 'Half hour';

  @override
  String get sendBtcFeeTierHour => 'Hour';

  @override
  String get sendBtcFeeTierEconomy => 'Economy';

  @override
  String get sendBtcFeeEtaFastest => '~10 min';

  @override
  String get sendBtcFeeEtaHalfHour => '~30 min';

  @override
  String get sendBtcFeeEtaHour => '~1 hour';

  @override
  String get sendBtcFeeEtaEconomy => 'When the mempool allows';

  @override
  String get sendBchRecipientLabel => 'Recipient address (CashAddr)';

  @override
  String get sendBchExperimentalBody =>
      'legacy P2PKH with SIGHASH_FORKID. The BIP143 sighash is spec-vector tested via BTC SegWit; the BCH-specific 0x41 sighash byte + legacy tx envelope are unit-tested but unaudited.';

  @override
  String get sendBchErrorMustBeCashAddr =>
      'Recipient must be a CashAddr (bitcoincash:q…/p… or just q…/p…)';

  @override
  String get sendBchErrorP2shNotSupported =>
      'P2SH BCH addresses (p…) aren\'t supported yet — only P2KH (q…) is in this build.';

  @override
  String get sendBchFinalFeeHint =>
      'BCH legacy P2PKH with SIGHASH_FORKID. Once submitted this CANNOT be reversed (BCH does not honor RBF).';

  @override
  String get sendBchAvailableShort => 'available';

  @override
  String get sendBchNetworkFeeLabel => 'Network fee';

  @override
  String sendBchFeeRateDescription(int rate, int typical) {
    return '$rate sat/byte — typical 1-input tx ≈ $typical sat. BCH fees are extremely low.';
  }

  @override
  String get sendBchAmountLabel => 'Amount (BCH or sat)';

  @override
  String get sendEthExperimentalBody =>
      'RLP + EIP-1559 sighash + ECDSA-recovery are unit-tested but the end-to-end send path has not been audited.';

  @override
  String get sendEthErrorBadAddress =>
      'Recipient must be a 0x-prefixed 40-hex-character address';

  @override
  String sendEthErrorExceedsToken(String symbol) {
    return 'Amount exceeds $symbol balance';
  }

  @override
  String sendEthErrorNoGas(String symbol) {
    return 'No $symbol for gas — fund this wallet first';
  }

  @override
  String sendEthAmountLabelToken(String symbol) {
    return 'Amount ($symbol or base units)';
  }

  @override
  String sendEthAmountLabelNative(String symbol) {
    return 'Amount ($symbol or wei)';
  }

  @override
  String get sendEthMaxFeeLabel => 'Max fee per gas';

  @override
  String get sendEthPriorityFeeLabel => 'Priority fee';

  @override
  String get sendEthLoadingBalance => 'Loading balance…';

  @override
  String sendEthBalanceError(String error) {
    return 'Balance error: $error';
  }

  @override
  String sendEthAvailableForGas(String amount, String symbol) {
    return 'available · $amount $symbol for gas';
  }

  @override
  String sendEthFeeError(String error) {
    return 'Fee data unavailable: $error';
  }

  @override
  String get sendEthLoadingFee => 'Loading fee rates…';

  @override
  String get sendEthNetworkFeeHeader => 'NETWORK FEE';

  @override
  String get sendEthAutoBadge => 'AUTO';

  @override
  String get sendEthBaseLabel => 'Base';

  @override
  String get sendEthTipLabel => 'Tip';

  @override
  String get sendEthMaxLabel => 'Max';

  @override
  String get sendEthFinalFeeHint =>
      'Final fee depends on the network base fee at inclusion time. Anything below max is refunded — overpaying doesn\'t actually cost. Once submitted this CANNOT be reversed.';

  @override
  String get sendSolExperimentalBody =>
      'Solana transaction encoding is unit-tested but the end-to-end send path has not been audited.';

  @override
  String get sendSolErrorBadAddress =>
      'Address should be 32-44 base58 characters';

  @override
  String get sendSolErrorNoSol =>
      'No SOL for fees — fund this wallet with a small amount of SOL first';

  @override
  String sendSolErrorNeedsAtaSol(String symbol) {
    return 'Recipient has no $symbol account — sending creates one (needs extra ~0.00204 SOL rent + fee).';
  }

  @override
  String get sendSolErrorNotEnoughSol => 'Not enough SOL for the network fee.';

  @override
  String get sendSolErrorAmountFeeExceeds => 'Amount + fee exceeds balance';

  @override
  String sendSolAmountLabelToken(String symbol) {
    return 'Amount ($symbol or base units)';
  }

  @override
  String get sendSolAmountLabelNative => 'Amount (SOL or lamports)';

  @override
  String get sendSolAddressHint => 'Solana address';

  @override
  String get sendSolNetworkFeeLabel => 'Network fee';

  @override
  String get sendSolAtaRentLabel => 'ATA rent';

  @override
  String get sendSolTotalOutLabel => 'Total SOL out';

  @override
  String get sendSolFinalFeeHintNative =>
      'Solana fees are fixed at 5000 lamports per signature. Once submitted this CANNOT be reversed.';

  @override
  String sendSolFinalFeeHintNewAta(String symbol) {
    return 'Recipient has no $symbol account yet. Sending creates one for them (~0.00204 SOL rent, paid by you). Once submitted this CANNOT be reversed.';
  }

  @override
  String get sendTrxExperimentalBody =>
      'Tron tx is built by the RPC and signed locally. The txid hash is verified before signing, but we don\'t decode the protobuf body.';

  @override
  String get sendTrxErrorBadAddress =>
      'Recipient must be a base58 Tron address (starts with T, 34 chars)';

  @override
  String get sendTrxErrorNoTrx =>
      'No TRX for bandwidth/energy — fund this wallet with TRX first';

  @override
  String get sendTrxRecipientLabel => 'Recipient (Tron base58)';

  @override
  String sendTrxAmountLabelToken(String symbol) {
    return 'Amount ($symbol or base units)';
  }

  @override
  String get sendTrxAmountLabelNative => 'Amount (TRX or sun)';

  @override
  String get sendTrxBandwidthLabel => 'Bandwidth/energy';

  @override
  String get sendTrxBandwidthToken => 'Up to ~30 TRX-equiv (TRC-20)';

  @override
  String get sendTrxBandwidthNative => 'Free quota or ~0.27 TRX';

  @override
  String get sendTrxFinalFeeHint =>
      'Tron transactions are built by the RPC node; we re-verify the txid hash before signing locally. Once submitted this CANNOT be reversed.';

  @override
  String get sendXmrTitle => 'Send XMR';

  @override
  String get sendXmrScanTitle => 'Scan recipient address';

  @override
  String sendXmrAvailable(String amount) {
    return 'Available: $amount XMR';
  }

  @override
  String get sendXmrAddRecipient => 'Add recipient';

  @override
  String get sendXmrSendAllTitle => 'Send all';

  @override
  String get sendXmrSendAllBody =>
      'Sweep every spendable output to the first recipient — fee will be subtracted automatically.';

  @override
  String get sendXmrFeePriorityLabel => 'Fee priority';

  @override
  String get sendXmrTierSlow => 'Slow';

  @override
  String get sendXmrTierNormal => 'Normal';

  @override
  String get sendXmrTierFast => 'Fast';

  @override
  String get sendXmrReviewAction => 'Review send';

  @override
  String get sendXmrToLabel => 'To';

  @override
  String sendXmrToNumbered(int index) {
    return 'To #$index';
  }

  @override
  String get sendXmrSubtotalLabel => 'Subtotal';

  @override
  String get sendXmrSweepLabel => 'Sending (sweep)';

  @override
  String get sendXmrNetworkFee => 'Network fee';

  @override
  String sendXmrSplitWarning(int count) {
    return 'This send will be relayed as $count sub-transactions.';
  }

  @override
  String get sendXmrBroadcastTitle => 'Transaction broadcast';

  @override
  String get sendXmrBroadcastBody =>
      'It will appear in your transaction history once the network confirms it.';

  @override
  String get sendXmrTxIdLabel => 'TX ID';

  @override
  String get sendXmrTxIdCopied => 'TX ID copied';

  @override
  String get sendXmrCopyTxIdAction => 'Copy TX ID';

  @override
  String get sendXmrDoneAction => 'Done';

  @override
  String get sendXmrRecipientHeader => 'Recipient';

  @override
  String get sendXmrRemoveTooltip => 'Remove';

  @override
  String get sendXmrAddressLabel => 'Recipient address';

  @override
  String get sendXmrAddressBookTooltip => 'Address book';

  @override
  String get sendXmrPasteTooltip => 'Paste';

  @override
  String get sendXmrAmountLabel => 'Amount (XMR)';

  @override
  String get sendXmrAmountHintSweep => 'Sweep — amount set automatically';

  @override
  String sendXmrErrorBadAddress(String tag) {
    return 'Address doesn\'t look like Monero$tag.';
  }

  @override
  String sendXmrErrorAmountZero(String tag) {
    return 'Amount must be greater than 0$tag.';
  }

  @override
  String get sendXmrErrorExceedsBalance => 'Total exceeds your balance.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsMoneroNode => 'Monero node';

  @override
  String get settingsMoneroNodeBody =>
      'The Monero daemon PeekWallet connects to for sync. Default is Cake Wallet\'s public node. For full privacy, run your own monerod and point this at it.';

  @override
  String get settingsDaemonUrlLabel => 'Daemon URL';

  @override
  String get settingsPasteTooltip => 'Paste';

  @override
  String settingsConnectsToPreview(String hostPort, String ssl) {
    return 'Connects to $hostPort (ssl=$ssl)';
  }

  @override
  String get settingsMessageBadUrl =>
      'Could not parse that URL. Try e.g. https://node.example.com:18081';

  @override
  String get settingsMessageSaved =>
      'Saved. Lock + unlock the app to switch your wallet to the new node.';

  @override
  String settingsMessageReset(String url) {
    return 'Reset. The app will use $url on next unlock.';
  }

  @override
  String get settingsResetToDefault => 'Reset to default';

  @override
  String get settingsSectionPublicNodes => 'Public nodes';

  @override
  String get settingsSectionSecurity => 'Security';

  @override
  String get settingsSectionDisplay => 'Display';

  @override
  String get settingsBiometricUnlock => 'Biometric unlock';

  @override
  String get settingsBiometricUnlockOn => 'Use fingerprint / face to unlock';

  @override
  String get settingsBiometricUnlockOff =>
      'Not available — no enrolled biometric';

  @override
  String get settingsBiometricEnableTitle => 'Enable biometric unlock';

  @override
  String get settingsBiometricEnableHint =>
      'Enter your app password to confirm';

  @override
  String settingsBiometricEnableFailed(String error) {
    return 'Could not enable: $error';
  }

  @override
  String get settingsPasswordLabel => 'Password';

  @override
  String get settingsRevealSeedTitle => 'Reveal recovery phrase';

  @override
  String get settingsRevealSeedBody =>
      'View your BIP39 seed + Monero spend/view keys';

  @override
  String get settingsAddressBookTitle => 'Address book';

  @override
  String get settingsAddressBookBody =>
      'Saved labels for recipients you send to';

  @override
  String get settingsAutoLockTitle => 'Auto-lock';

  @override
  String get settingsAutoLockSheetTitle => 'Auto-lock after backgrounding';

  @override
  String get settingsAutoLockSheetBody =>
      'How long PeekWallet can stay unlocked while you\'re using other apps. Returning within this window keeps you logged in; longer and the password is required again.';

  @override
  String get settingsAutoLockImmediately => 'Immediately';

  @override
  String get settingsAutoLockNever => 'Never';

  @override
  String settingsAutoLockSeconds(int n) {
    return '$n s';
  }

  @override
  String get settingsAutoLock30Seconds => '30 seconds';

  @override
  String get settingsAutoLock1Minute => '1 minute';

  @override
  String get settingsAutoLock2MinutesDefault => '2 minutes (default)';

  @override
  String get settingsAutoLock5Minutes => '5 minutes';

  @override
  String get settingsAutoLock15Minutes => '15 minutes';

  @override
  String get settingsAutoLock1Hour => '1 hour';

  @override
  String get settingsLockAppTitle => 'Lock app';

  @override
  String get settingsLockAppBody =>
      'Clear the in-memory seed and require the password again';

  @override
  String get settingsLockConfirmTitle => 'Lock app?';

  @override
  String get settingsLockConfirmBody =>
      'You will need to enter your password to unlock. Any in-progress Monero sync will pick up where it left off.';

  @override
  String get settingsLockConfirmAction => 'Lock';

  @override
  String get settingsDisplayCurrencyTitle => 'Display currency';

  @override
  String get settingsDisplayCurrencyDisabled => 'Disabled';

  @override
  String get settingsShowFiatValues => 'Show fiat values';

  @override
  String get settingsShowFiatValuesBody =>
      'Polls CoinGecko every 5 min. No PII sent.';

  @override
  String get settingsExportLogsTitle => 'Export logs';

  @override
  String get settingsExportLogsBody =>
      'Last 7 days. Addresses and keys are auto-redacted.';

  @override
  String get settingsExportLogsEmpty => 'No logs to export yet.';

  @override
  String get settingsExportLogsDialogTitle => 'Logs (last 7 days)';

  @override
  String get settingsExportLogsCopied => 'Logs copied to clipboard';

  @override
  String get settingsCloseAction => 'Close';

  @override
  String get settingsRestoreAllTitle => 'Restore all coins from vault seed';

  @override
  String get settingsRestoreAllBody =>
      'One-tap derive a wallet for every coin from your existing 12/24-word seed.';

  @override
  String get settingsCustomRpcTitle => 'Custom RPC endpoints';

  @override
  String get settingsCustomRpcBody =>
      'Point BTC/LTC/BCH/ETH/POL/SOL/TRX at your own nodes.';

  @override
  String get settingsUpdateTitle => 'Check for updates';

  @override
  String get settingsUpdateChecking => 'Checking GitHub…';

  @override
  String get settingsUpdateTapToCheck => 'Tap to check';

  @override
  String get settingsUpdateFailedFallback => 'Check failed';

  @override
  String settingsUpdateAvailable(String ago) {
    return 'Update available — released $ago. Tap to download.';
  }

  @override
  String get settingsUpdateDebugBuild =>
      'Debug build — version check disabled. Tap to retry.';

  @override
  String get settingsUpdateUpToDate => 'Up to date · checked just now';

  @override
  String get settingsAboutTitle => 'About PeekWallet';

  @override
  String get settingsAboutBody => 'Version, license, source code';

  @override
  String get addWalletChooseCoin => 'Choose coin';

  @override
  String addWalletTitle(String coin) {
    return 'Add $coin wallet';
  }

  @override
  String get addWalletCreateTitle => 'Create new wallet';

  @override
  String get addWalletCreateBody =>
      'Generate a fresh seed phrase. Anyone with the phrase can spend the wallet — write it down on paper.';

  @override
  String get addWalletRestoreSeedTitle => 'Restore from seed';

  @override
  String get addWalletRestoreSeedBody =>
      'Use a recovery phrase you already have (BIP39 12/24 words, Monero 25-word seed, or Polyseed 14 words).';

  @override
  String get addWalletRestoreKeysTitle => 'Restore from keys';

  @override
  String get addWalletRestoreKeysBody =>
      'Address + private spend key + private view key. Use this when you have the keys but not a seed phrase.';

  @override
  String get addWalletFormatNew => 'New seed format';

  @override
  String get addWalletFormatRestore => 'Restore format';

  @override
  String get addWalletFormatBip39Hint =>
      'BIP39 mnemonic — the standard 12/24 word format used by every modern wallet. Trezor, Ledger. Universal across many coins.';

  @override
  String get addWalletFormatMoneroLegacyHint =>
      'Native Monero electrum-style seed. Direct interop with Cake, Feather, and Monero GUI.';

  @override
  String get addWalletFormatPolyseedHint =>
      'Newer Monero standard — 14 words. Restore height baked in.';

  @override
  String get addWalletFormatKeysOnlyHint =>
      'Spend key + view key + address. No words.';

  @override
  String get addWalletVaultLocked =>
      'Vault is locked — re-unlock and try again.';

  @override
  String addWalletGenerateHeader(String format) {
    return 'Generate a $format';
  }

  @override
  String get addWalletGenerateBody =>
      'When you tap Generate, the words will appear once. Write them down on paper before continuing. Anyone with these words can drain this wallet.';

  @override
  String get addWalletGenerateAction => 'Generate seed';

  @override
  String get addWalletWriteThisDown => 'Write this down';

  @override
  String get addWalletWordsWarning =>
      'These words ARE the wallet. Anyone with them can spend it.';

  @override
  String get addWalletCopyClipboardClears =>
      'Copied — clipboard auto-clears in 30 s';

  @override
  String get addWalletCopyPhraseAction => 'Copy phrase';

  @override
  String get addWalletNameLabel => 'Wallet name (only you can see this)';

  @override
  String get addWalletNameHint => 'e.g. \"Main Monero\"';

  @override
  String get addWalletSavedConfirm => 'I have saved the words — add wallet';

  @override
  String addWalletRestoreTitle(String format) {
    return 'Restore $format';
  }

  @override
  String get addWalletRestoreNameLabel => 'Wallet name';

  @override
  String get addWalletRestoreNameHint => 'e.g. \"Imported from Cake\"';

  @override
  String get addWalletRecoveryPhraseLabel => 'Recovery phrase';

  @override
  String get addWalletSeedWordsLabel => 'Seed words';

  @override
  String get addWalletPassphraseLabel =>
      'BIP39 passphrase (25th word) — optional';

  @override
  String get addWalletPassphraseHint => 'Leave blank if not used';

  @override
  String get addWalletPassphraseWarning =>
      'If the source wallet had a passphrase, you MUST enter it — otherwise you\'ll get a different wallet entirely.';

  @override
  String get addWalletSeedOffsetLabel => 'Seed offset — optional';

  @override
  String get addWalletSeedOffsetHint =>
      'Leave blank if the seed isn\'t encrypted';

  @override
  String get addWalletRestoreHeightLabel => 'Restore height — optional';

  @override
  String get addWalletRestoreHeightHint =>
      'Block number to start scanning from';

  @override
  String get addWalletRestoreHeightBody =>
      'Lower = more thorough but slower sync; higher = faster but might miss old receipts.';

  @override
  String get addWalletRestoreAction => 'Restore wallet';

  @override
  String get addWalletKeysRestoreTitle => 'Restore from keys';

  @override
  String get addWalletPrimaryAddressLabel => 'Primary address';

  @override
  String get addWalletSpendKeyLabel => 'Private spend key (hex)';

  @override
  String get addWalletViewKeyLabel => 'Private view key (hex)';

  @override
  String get addWalletKeysRestoreHeightLabel => 'Restore height';

  @override
  String get addWalletKeysRestoreHeightHint =>
      'Block number — earlier covers older receipts';

  @override
  String get addWalletScanAddressTitle => 'Scan address';

  @override
  String get addWalletConfirmPasswordTitle => 'Confirm password';

  @override
  String get addWalletAppPasswordLabel => 'App password';

  @override
  String lockTryAgainIn(String duration) {
    return 'Try again in $duration.';
  }

  @override
  String get welcomeTagline =>
      'Self-custodial wallet for BTC, ETH, XMR, and more.';

  @override
  String get welcomeCreateAction => 'Create new wallet';

  @override
  String get welcomeImportAction => 'I already have a recovery phrase';

  @override
  String get welcomeBackupWarning =>
      'Your 12-word recovery phrase is the only backup. Anyone with it can take your funds.';

  @override
  String get welcomeDisclaimerAction => 'Read the no-warranty disclaimer';

  @override
  String get welcomeDisclaimerTitle => 'Disclaimer';

  @override
  String get welcomeCopiedToast => 'Copied';

  @override
  String get welcomeCopyTextAction => 'Copy text';

  @override
  String get welcomeIUnderstandAction => 'I understand';

  @override
  String get revealSeedTitle => 'Reveal recovery phrase';

  @override
  String get revealSeedWarning =>
      'You are about to reveal your seed phrase and Monero keys. Anyone who sees them can take your funds — make sure no one is looking at your screen and you\'re not screen-sharing.';

  @override
  String get revealSeedPasswordPrompt => 'Enter your app password to continue.';

  @override
  String get revealSeedRevealAction => 'Reveal';

  @override
  String get revealSeedBip39Section => 'BIP39 recovery phrase';

  @override
  String get revealSeedPassphraseSection => 'BIP39 passphrase (25th word)';

  @override
  String get revealSeedXmrAddressSection => 'Monero primary address';

  @override
  String get revealSeedXmrSpendSection => 'Monero private spend key';

  @override
  String get revealSeedXmrViewSection => 'Monero private view key';

  @override
  String get revealSeedCopyPhrase => 'Copy phrase';

  @override
  String get revealSeedCopyPassphrase => 'Copy passphrase';

  @override
  String get revealSeedCopyAddress => 'Copy address';

  @override
  String get revealSeedCopySpendKey => 'Copy spend key';

  @override
  String get revealSeedCopyViewKey => 'Copy view key';

  @override
  String get revealSeedRestoreHint =>
      'You can restore this wallet in Cake / Feather / Monero GUI using \"Restore from keys\" with the address + view key + spend key above (or \"Restore from seed\" with the BIP39 phrase in any BIP39-compatible wallet).';

  @override
  String get revealSeedCopiedSensitive =>
      'Copied — clipboard auto-clears in 30 s';

  @override
  String get revealSeedCopiedPlain => 'Copied';

  @override
  String get aboutScreenTitle => 'About';

  @override
  String aboutVersionLine(String version, String build) {
    return 'v$version (build $build)';
  }

  @override
  String get aboutAppVersion => 'App version';

  @override
  String get aboutBuildNumber => 'Build number';

  @override
  String get aboutPackage => 'Package';

  @override
  String get aboutBuildSignature => 'Build signature';

  @override
  String get aboutSourceSection => 'Source code';

  @override
  String get aboutLegalSection => 'Legal';

  @override
  String get aboutGithubRepo => 'GitHub repository';

  @override
  String get aboutLicenseLink => 'License (GPL-3.0-or-later)';

  @override
  String get aboutDisclaimerLink => 'Disclaimer (no warranty)';

  @override
  String get aboutSecurityModelLink => 'Security model';

  @override
  String get aboutFreeSoftwareBody =>
      'PeekWallet is free, open-source software. Anyone can read the source, build it themselves, and verify the binary on /releases matches the public code (reproducibility tracked in the roadmap).';

  @override
  String get aboutUrlCopiedToast => 'URL copied — open in your browser';

  @override
  String get addressBookTitle => 'Address book';

  @override
  String get addressBookPickerTitle => 'Pick recipient';

  @override
  String get addressBookAddTooltip => 'Add entry';

  @override
  String get addressBookEmptyTitle => 'No saved addresses yet';

  @override
  String get addressBookEmptyBodyPicker =>
      'Save the recipient you\'re about to send to.';

  @override
  String get addressBookEmptyBody =>
      'Save the addresses of people you send to often so you don\'t have to paste each time.';

  @override
  String get addressBookAddAction => 'Add entry';

  @override
  String get addressBookErrorLabelEmpty => 'Label cannot be empty.';

  @override
  String get addressBookErrorAddressEmpty => 'Address cannot be empty.';

  @override
  String get addressBookDeleteTitle => 'Delete entry?';

  @override
  String get addressBookDeleteBody =>
      'The address is not affected — only this saved label / note is removed.';

  @override
  String get addressBookDeleteAction => 'Delete';

  @override
  String get addressBookEditTitle => 'Edit address';

  @override
  String get addressBookAddTitle => 'Add address';

  @override
  String get addressBookDeleteTooltip => 'Delete';

  @override
  String get addressBookLabelField => 'Label';

  @override
  String get addressBookAddressField => 'Address';

  @override
  String get addressBookAddressLocked =>
      'Addresses can\'t be edited — delete and re-add to change.';

  @override
  String get addressBookScanTooltip => 'Scan';

  @override
  String get addressBookPasteTooltip => 'Paste';

  @override
  String get addressBookNotesField => 'Notes (optional)';

  @override
  String get addressBookNotesHint => 'Free-text — only stored locally.';

  @override
  String get addressBookSaveChanges => 'Save changes';

  @override
  String get addressBookAddToBook => 'Add to book';

  @override
  String get qrScanTitle => 'Scan QR';

  @override
  String get qrScanTorchTooltip => 'Torch';

  @override
  String qrScanCameraError(String code) {
    return 'Camera error: $code';
  }

  @override
  String get qrScanPermissionDenied => 'Camera permission denied';

  @override
  String get qrScanPermissionBody =>
      'PeekWallet needs camera access to scan QR codes. The camera is only used while this screen is open and only reads the QR payload.';

  @override
  String get qrScanTryAgain => 'Try again';

  @override
  String get qrScanOpenSettings => 'Open app settings';

  @override
  String get qrScanCenterHint => 'Center the QR code in the frame';

  @override
  String get rpcResetTitle => 'Reset all overrides?';

  @override
  String get rpcResetBody =>
      'Every chain will go back to its public default endpoint. You can re-add overrides at any time.';

  @override
  String get rpcResetAction => 'Reset';

  @override
  String get rpcScreenTitle => 'Custom RPC endpoints';

  @override
  String get rpcResetAllTooltip => 'Reset all';

  @override
  String get rpcIntroBody =>
      'Point each chain at your own node instead of the public default. Leaving a field blank keeps the current default.';

  @override
  String rpcDefaultHint(String hint) {
    return 'Default: $hint';
  }

  @override
  String get rpcSaveAction => 'Save';

  @override
  String get rpcPrivacyNotesBody =>
      'Privacy notes:\n• Public defaults see your IP address and which addresses you query. Run your own node or proxy through a VPN / LAN over Tailscale.\n• Custom RPC endpoints sent here go straight to whatever URL you enter — your network sees the destination. Pick providers you trust.';

  @override
  String get restoreAllTitle => 'Restore all coins from vault';

  @override
  String get restoreAllIntro =>
      'Adds a wallet for every supported coin, derived from your existing 12/24-word vault seed.';

  @override
  String get restoreAllNote =>
      'Existing wallets are skipped (no duplicates). Monero is excluded — it has a separate seed format and is restored from its own setup.';

  @override
  String get restoreAllAction => 'Restore all from vault seed';

  @override
  String get restoreAllVaultLocked => 'Vault is locked. Unlock and try again.';

  @override
  String restoreAllHasWallet(String symbol) {
    return 'Already have a $symbol wallet — skip';
  }

  @override
  String get restoreAllWillDerive => 'Will derive from BIP39 vault seed';

  @override
  String showSeedTitle(String name) {
    return 'Recovery phrase · $name';
  }

  @override
  String get showSeedPasswordPrompt =>
      'Enter your app password to see this wallet\'s recovery phrase.';

  @override
  String get showSeedPasswordLabel => 'App password';

  @override
  String get showSeedRevealAction => 'Reveal';

  @override
  String get showSeedRecoveryPhrase => 'Recovery phrase';

  @override
  String get showSeedCopyPhrase => 'Copy phrase';

  @override
  String get showSeedCopyClipboardClears =>
      'Copied — clipboard auto-clears in 30s';

  @override
  String get showSeedPassphraseSection => 'Passphrase (25th word)';

  @override
  String get showSeedSeedOffsetSection => 'Seed offset';

  @override
  String get showSeedAddressLabel => 'Address';

  @override
  String get showSeedViewKeyLabel => 'View key';

  @override
  String get showSeedSpendKeyLabel => 'Spend key';

  @override
  String get showSeedCopySpendKey => 'Copy spend key';

  @override
  String showSeedStorageFooter(String format, String coin) {
    return 'Storage: $format. Coin: $coin.';
  }

  @override
  String get showSeedWriteDownWarning =>
      'Write this down on paper and store it somewhere safe. Anyone with this phrase has full control of the wallet. Don\'t take a screenshot — FLAG_SECURE blocks it anyway.';

  @override
  String get showSeedKeysOnlyDisplay => 'Keys only';

  @override
  String get walletMenuShowSeed => 'Show recovery phrase';

  @override
  String get walletMenuShowSeedBody =>
      'Back this up separately from the vault seed.';

  @override
  String get walletMenuRename => 'Rename';

  @override
  String get walletMenuRenameTitle => 'Rename wallet';

  @override
  String walletMenuDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get walletMenuDeleteBody =>
      'The on-chain wallet is not affected — anyone with the seed can still restore it later. Only this device\'s record is removed.';

  @override
  String get cwSeedTitle => 'Recovery phrase';

  @override
  String get cwConfirmTitle => 'Confirm phrase';

  @override
  String get cwPasswordTitle => 'Set password';

  @override
  String get cwSeedWarning =>
      'Write these 12 words down on paper and store them safely. Anyone with the phrase can take your funds. Never type it on a website.';

  @override
  String get cwIveWrittenItDown => 'I have written it down';

  @override
  String get cwConfirmBody =>
      'Type the requested words to confirm you saved the phrase.';

  @override
  String get cwWordPlaceholderHint => 'Lowercase, no spaces';

  @override
  String cwWordNumberLabel(int n) {
    return 'Word #$n';
  }

  @override
  String get cwPasswordBody =>
      'This password encrypts your wallet on this device. You will need it every time you unlock.';

  @override
  String get cwPasswordMinLabel => 'Password (min 8 characters)';

  @override
  String get cwConfirmPasswordLabel => 'Confirm password';

  @override
  String get cwPasswordTooShort => 'Password must be at least 8 characters.';

  @override
  String get cwPasswordsDontMatch => 'Passwords don\'t match.';

  @override
  String get cwCreateWalletAction => 'Create wallet';

  @override
  String get cwCopyPhrase => 'Copy phrase';

  @override
  String get cwCopiedClipboardAutoClear =>
      'Copied — clipboard auto-clears in 30 s';

  @override
  String get iwScreenTitle => 'Import wallet';

  @override
  String get iwIntro =>
      'Paste your existing BIP39 recovery phrase (12 or 24 words). Same format as vault-wallet.';

  @override
  String get iwRecoveryPhraseLabel => 'Recovery phrase';

  @override
  String get iwPhraseHint => 'word1 word2 word3 ...';

  @override
  String get iwPassphraseOptionalLabel =>
      'BIP39 passphrase (25th word) — optional';

  @override
  String get iwPassphraseHintBlank => 'Leave blank if you did not set one';

  @override
  String get iwPassphraseWarning =>
      'If you used a BIP39 passphrase in vault-wallet (or another wallet) you MUST enter it here — without it the imported addresses won\'t match and balances appear as zero.';

  @override
  String get iwAppPasswordMinLabel => 'App password (min 8 characters)';

  @override
  String get iwConfirmAppPasswordLabel => 'Confirm app password';

  @override
  String get iwErrorBadWordCount => 'Enter your 12 or 24-word recovery phrase.';

  @override
  String get iwErrorBip39Checksum =>
      'Invalid recovery phrase (BIP39 checksum failed).';

  @override
  String get iwErrorAppPasswordTooShort =>
      'App password must be at least 8 characters.';

  @override
  String get iwImportAction => 'Import wallet';

  @override
  String get xmrScreenUnlockTitle => 'Unlock wallet';

  @override
  String get xmrScreenUnlockAction => 'Open';

  @override
  String get xmrScreenErrLocked => 'Wallet is locked';

  @override
  String xmrScreenErrAddressDerivation(String error) {
    return 'Address derivation failed: $error';
  }

  @override
  String get xmrScreenErrVaultLocked =>
      'Vault locked — wallet password unavailable';

  @override
  String get xmrScreenErrPasswordRequired =>
      'Password required to open this wallet';

  @override
  String xmrScreenErrCouldNotOpen(String error) {
    return 'Could not open wallet: $error';
  }

  @override
  String xmrScreenErrUnknownCoin(String coin) {
    return 'Unknown coin: $coin';
  }

  @override
  String xmrScreenBootStage(String stage) {
    return 'Boot: $stage';
  }

  @override
  String get xmrScreenConnectingDaemon => 'Connecting to daemon…';

  @override
  String xmrScreenSyncingPct(int pct) {
    return 'Syncing $pct%';
  }

  @override
  String xmrScreenSyncedAtHeight(String h) {
    return 'Synced · height $h';
  }

  @override
  String get xmrScreenSynced => 'Synced';

  @override
  String xmrScreenDaemonError(String error) {
    return 'Daemon: $error';
  }

  @override
  String xmrScreenEngineError(String error) {
    return 'Engine: $error';
  }

  @override
  String get xmrScreenBootingWallet => 'Booting wallet…';

  @override
  String get xmrScreenResetTitle => 'Reset wallet file?';

  @override
  String get xmrScreenResetBody =>
      'This deletes the on-disk wallet file and recreates it from your stored seed. The chain-sync cache is lost so the wallet will need to rescan from your restore height (could take a while). Your seed is NOT touched — funds are safe.\n\nUse this if you\'re stuck with a persistent \"invalid password\" error.';

  @override
  String get xmrScreenResetAction => 'Reset & rescan';

  @override
  String get xmrScreenResetAndRescanFromSeed => 'Reset & rescan from seed';

  @override
  String get xmrScreenActivity => 'Activity';

  @override
  String get xmrScreenWalletStillSyncing =>
      'Wallet is still syncing — newer activity will appear once we catch up to the chain tip.';

  @override
  String get xmrScreenAddressCopied => 'Address copied';

  @override
  String get xmrScreenCopyAddress => 'Copy address';

  @override
  String get xmrScreenTxStatusFailed => 'Failed';

  @override
  String get xmrScreenTxStatusPending => 'Pending';

  @override
  String get xmrScreenTxStatusConfirmed => 'Confirmed';

  @override
  String get xmrScreenDirIncoming => 'Incoming';

  @override
  String get xmrScreenDirOutgoing => 'Outgoing';

  @override
  String get xmrScreenTxAmount => 'Amount';

  @override
  String get xmrScreenTxFee => 'Fee';

  @override
  String get xmrScreenTxDate => 'Date';

  @override
  String get xmrScreenTxBlockHeight => 'Block height';

  @override
  String get xmrScreenTxConfirmations => 'Confirmations';

  @override
  String get xmrScreenTxStatus => 'Status';

  @override
  String get xmrScreenTxPaymentId => 'Payment ID';

  @override
  String get xmrScreenTxNote => 'Note';

  @override
  String get xmrScreenTxAdd => 'Add';

  @override
  String get xmrScreenTxEdit => 'Edit';

  @override
  String get xmrScreenTxId => 'TX ID';

  @override
  String get xmrScreenTxIdCopied => 'TX ID copied';

  @override
  String get xmrScreenCopy => 'Copy';

  @override
  String get xmrScreenExplorer => 'Explorer';

  @override
  String get xmrScreenCouldNotOpenBrowser => 'Could not open browser';

  @override
  String get xmrScreenTxNoteTitle => 'Transaction note';

  @override
  String get xmrScreenTxNoteHint => 'Free-text — only you can read this.';

  @override
  String get xmrScreenClear => 'Clear';

  @override
  String get xmrScreenNoteSaved => 'Note saved';

  @override
  String get xmrScreenNoteCleared => 'Note cleared';

  @override
  String xmrScreenCouldNotSaveNote(String error) {
    return 'Could not save note: $error';
  }

  @override
  String get xmrScreenLabelPrimary => 'Primary';

  @override
  String xmrScreenLabelSubaddress(int index) {
    return 'Label subaddress #$index';
  }

  @override
  String xmrScreenCouldNotSaveLabel(String error) {
    return 'Could not save label: $error';
  }

  @override
  String get xmrScreenReceiveTitle => 'Receive XMR';

  @override
  String get xmrScreenSubaddrUnavailable =>
      'Subaddresses unavailable until the wallet finishes booting.';

  @override
  String get xmrScreenSubaddrSectionTitle => 'Subaddresses';

  @override
  String get xmrScreenSubaddrNew => 'New';

  @override
  String get xmrScreenSubaddrBody =>
      'Generate a fresh address per payer so observers can\'t link two payments to the same wallet. All point to the same balance.';

  @override
  String get xmrScreenEditLabelTooltip => 'Edit label';

  @override
  String get xmrScreenAppPasswordLabel => 'App password';

  @override
  String xmrScreenSyncingPctBehind(int pct, int behind) {
    return 'Syncing $pct% · $behind blocks behind';
  }

  @override
  String xmrScreenConfirmationsShort(int n) {
    return '$n conf';
  }

  @override
  String get xmrScreenNoNote => '— No note —';

  @override
  String get xmrScreenSubaddrLabelHint =>
      'e.g. \"Customer payments\", \"Side gig\"';

  @override
  String get xmrScreenEngineLoaded => '✓ Native monero_c engine loaded';

  @override
  String xmrScreenEngineNotLoaded(String error) {
    return '✗ Engine not loaded: $error';
  }

  @override
  String get erc20EmptyHint =>
      'No tokens yet — receive USDT/USDC/DAI to this address or tap \"Add token\" to track another ERC-20 by contract address.';

  @override
  String get ercAddCustomTitle => 'Add custom ERC-20 token';

  @override
  String get ercAddCustomBody =>
      'Paste the token\'s contract address. We\'ll fetch its symbol and decimals from the chain.';

  @override
  String get ercContractLabel => 'Contract address';

  @override
  String get ercProbeAction => 'Probe';

  @override
  String get ercContractError => 'Contract must be 0x + 40 hex chars';

  @override
  String ercProbingMsg(String prefix) {
    return 'Probing $prefix…';
  }

  @override
  String get ercProbeFailedMsg =>
      'Could not read token metadata — wrong chain or not an ERC-20?';

  @override
  String ercAddedMsg(String symbol, int decimals) {
    return 'Added $symbol ($decimals decimals)';
  }
}
