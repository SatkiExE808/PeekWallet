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
