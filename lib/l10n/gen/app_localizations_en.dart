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
