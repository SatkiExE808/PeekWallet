import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
    Locale('ms'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// App display name shown in lock screen / app bar
  ///
  /// In en, this message translates to:
  /// **'PeekWallet'**
  String get appName;

  /// No description provided for @lockScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to unlock'**
  String get lockScreenSubtitle;

  /// No description provided for @lockPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get lockPasswordHint;

  /// No description provided for @lockUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockUnlock;

  /// No description provided for @lockUseBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use biometric'**
  String get lockUseBiometric;

  /// No description provided for @lockTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts'**
  String get lockTooManyAttempts;

  /// No description provided for @lockTimerWarning.
  ///
  /// In en, this message translates to:
  /// **'Locking your phone or restarting the app won\'t reset the timer — this is intentional.'**
  String get lockTimerWarning;

  /// No description provided for @walletsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Wallets'**
  String get walletsTitle;

  /// No description provided for @walletsRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh balances'**
  String get walletsRefreshTooltip;

  /// No description provided for @walletsAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add wallet'**
  String get walletsAddTooltip;

  /// No description provided for @homeTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get homeTotalBalance;

  /// No description provided for @homeSyncedCount.
  ///
  /// In en, this message translates to:
  /// **'{counted} / {total} synced'**
  String homeSyncedCount(int counted, int total);

  /// No description provided for @homeAcrossWallets.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{across 1 wallet} other{across {count} wallets}}'**
  String homeAcrossWallets(int count);

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No wallets yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a fresh wallet or restore from a recovery phrase to get started.'**
  String get homeEmptyBody;

  /// No description provided for @homeAddWallet.
  ///
  /// In en, this message translates to:
  /// **'Add wallet'**
  String get homeAddWallet;

  /// No description provided for @actionReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get actionReceive;

  /// No description provided for @actionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get actionSend;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @actionExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get actionExplorer;

  /// No description provided for @actionSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get actionSending;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @receiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive {coinId}'**
  String receiveTitle(String coinId);

  /// No description provided for @receiveAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'YOUR ADDRESS'**
  String get receiveAddressLabel;

  /// No description provided for @receiveAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get receiveAddressCopied;

  /// No description provided for @receiveCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get receiveCopiedToClipboard;

  /// No description provided for @receiveCouldNotOpenBrowser.
  ///
  /// In en, this message translates to:
  /// **'Could not open browser'**
  String get receiveCouldNotOpenBrowser;

  /// No description provided for @coinScreenBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'{symbol} balance'**
  String coinScreenBalanceLabel(String symbol);

  /// No description provided for @coinScreenActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get coinScreenActivityTitle;

  /// No description provided for @coinScreenTokensTitle.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get coinScreenTokensTitle;

  /// No description provided for @coinScreenNoTxYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get coinScreenNoTxYet;

  /// No description provided for @coinScreenShareAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Share your address to receive {symbol}'**
  String coinScreenShareAddressHint(String symbol);

  /// No description provided for @coinScreenLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get coinScreenLoading;

  /// No description provided for @coinScreenRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get coinScreenRefreshTooltip;

  /// No description provided for @coinScreenAddTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Add token'**
  String get coinScreenAddTokenLabel;

  /// No description provided for @balanceCached.
  ///
  /// In en, this message translates to:
  /// **'Cached · {ago} ago'**
  String balanceCached(String ago);

  /// No description provided for @balanceCachedShort.
  ///
  /// In en, this message translates to:
  /// **'Cached · {ago}'**
  String balanceCachedShort(String ago);

  /// No description provided for @balanceCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open wallet: {error}'**
  String balanceCouldNotOpen(String error);

  /// No description provided for @balanceVaultLocked.
  ///
  /// In en, this message translates to:
  /// **'Vault is locked.'**
  String get balanceVaultLocked;

  /// No description provided for @ageJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get ageJustNow;

  /// No description provided for @ageMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String ageMinutes(int n);

  /// No description provided for @ageHours.
  ///
  /// In en, this message translates to:
  /// **'{n} hr'**
  String ageHours(int n);

  /// No description provided for @ageDays.
  ///
  /// In en, this message translates to:
  /// **'{n} d'**
  String ageDays(int n);

  /// No description provided for @txDirectionIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get txDirectionIncoming;

  /// No description provided for @txDirectionOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Outgoing'**
  String get txDirectionOutgoing;

  /// No description provided for @txStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get txStatusConfirmed;

  /// No description provided for @txStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get txStatusPending;

  /// No description provided for @txStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get txStatusFailed;

  /// No description provided for @txStatusInMempool.
  ///
  /// In en, this message translates to:
  /// **'In mempool'**
  String get txStatusInMempool;

  /// No description provided for @txCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get txCopiedToClipboard;

  /// No description provided for @txIdLabel.
  ///
  /// In en, this message translates to:
  /// **'TX ID'**
  String get txIdLabel;

  /// No description provided for @txHashLabel.
  ///
  /// In en, this message translates to:
  /// **'Hash'**
  String get txHashLabel;

  /// No description provided for @txSignatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get txSignatureLabel;

  /// No description provided for @txAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Net amount'**
  String get txAmountLabel;

  /// No description provided for @txFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get txFeeLabel;

  /// No description provided for @txGasFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Gas fee'**
  String get txGasFeeLabel;

  /// No description provided for @txNetworkFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Network fee'**
  String get txNetworkFeeLabel;

  /// No description provided for @txBlockHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Block height'**
  String get txBlockHeightLabel;

  /// No description provided for @txSlotLabel.
  ///
  /// In en, this message translates to:
  /// **'Slot'**
  String get txSlotLabel;

  /// No description provided for @txDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get txDateLabel;

  /// No description provided for @txTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get txTokenLabel;

  /// No description provided for @txCounterpartyLabel.
  ///
  /// In en, this message translates to:
  /// **'Counterparty'**
  String get txCounterpartyLabel;

  /// No description provided for @sendFormRecipientLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipient address'**
  String get sendFormRecipientLabel;

  /// No description provided for @sendFormAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get sendFormAmountLabel;

  /// No description provided for @sendFormMaxButton.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get sendFormMaxButton;

  /// No description provided for @sendFormBookTooltip.
  ///
  /// In en, this message translates to:
  /// **'From address book'**
  String get sendFormBookTooltip;

  /// No description provided for @sendFormScanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get sendFormScanTooltip;

  /// No description provided for @sendFormPasteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get sendFormPasteTooltip;

  /// No description provided for @sendFormFeePriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'FEE PRIORITY'**
  String get sendFormFeePriorityLabel;

  /// No description provided for @sendFormAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'available'**
  String get sendFormAvailableLabel;

  /// No description provided for @sendFormConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Type SEND to confirm'**
  String get sendFormConfirmHint;

  /// No description provided for @sendFormConfirmPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'SEND'**
  String get sendFormConfirmPlaceholder;

  /// No description provided for @sendFormErrorInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get sendFormErrorInvalidAmount;

  /// No description provided for @sendFormErrorAmountExceedsBalance.
  ///
  /// In en, this message translates to:
  /// **'Amount + fee exceeds balance'**
  String get sendFormErrorAmountExceedsBalance;

  /// No description provided for @sendFormErrorRecipientRequired.
  ///
  /// In en, this message translates to:
  /// **'Recipient address is required'**
  String get sendFormErrorRecipientRequired;

  /// No description provided for @sendFormWillBeSentTo.
  ///
  /// In en, this message translates to:
  /// **'will be sent to'**
  String get sendFormWillBeSentTo;

  /// No description provided for @sendFormToLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get sendFormToLabel;

  /// No description provided for @tronTokensTitle.
  ///
  /// In en, this message translates to:
  /// **'Tokens (TRC-20)'**
  String get tronTokensTitle;

  /// No description provided for @splTokensTitle.
  ///
  /// In en, this message translates to:
  /// **'Tokens (SPL)'**
  String get splTokensTitle;

  /// No description provided for @erc20TokensTitle.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get erc20TokensTitle;

  /// No description provided for @experimentalSendWarning.
  ///
  /// In en, this message translates to:
  /// **'Send is experimental — test with small amounts before moving meaningful {symbol}.'**
  String experimentalSendWarning(String symbol);

  /// No description provided for @sendScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Send {coinName}'**
  String sendScreenTitle(String coinName);

  /// No description provided for @sendScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan {symbol} address'**
  String sendScanTitle(String symbol);

  /// No description provided for @sendBtcAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount ({symbol} or sat)'**
  String sendBtcAmountLabel(String symbol);

  /// No description provided for @sendBroadcastSuccess.
  ///
  /// In en, this message translates to:
  /// **'Broadcast! txid: {prefix}…'**
  String sendBroadcastSuccess(String prefix);

  /// No description provided for @sendBtcLoadingUtxos.
  ///
  /// In en, this message translates to:
  /// **'Loading UTXOs…'**
  String get sendBtcLoadingUtxos;

  /// No description provided for @sendBtcUtxoError.
  ///
  /// In en, this message translates to:
  /// **'UTXO error: {error}'**
  String sendBtcUtxoError(String error);

  /// No description provided for @sendBtcAvailableHint.
  ///
  /// In en, this message translates to:
  /// **'available · confirmed UTXOs only'**
  String get sendBtcAvailableHint;

  /// No description provided for @sendBtcFeeRatesError.
  ///
  /// In en, this message translates to:
  /// **'Fee rates unavailable: {error}'**
  String sendBtcFeeRatesError(String error);

  /// No description provided for @sendBtcLoadingFeeRates.
  ///
  /// In en, this message translates to:
  /// **'Loading fee rates…'**
  String get sendBtcLoadingFeeRates;

  /// No description provided for @sendBtcFinalFeeHint.
  ///
  /// In en, this message translates to:
  /// **'Final fee + change will be shown after broadcast. Once submitted to the network it CANNOT be reversed.'**
  String get sendBtcFinalFeeHint;

  /// No description provided for @sendBtcExperimentalBody.
  ///
  /// In en, this message translates to:
  /// **'send is BIP-0143 spec-vector tested but has not been audited end-to-end.'**
  String get sendBtcExperimentalBody;

  /// No description provided for @sendBtcOnlyBech32.
  ///
  /// In en, this message translates to:
  /// **'Only bech32 P2WPKH ({prefix}…) addresses are supported'**
  String sendBtcOnlyBech32(String prefix);

  /// No description provided for @sendBtcExceedsBalance.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds confirmed balance ({available} sat)'**
  String sendBtcExceedsBalance(int available);

  /// No description provided for @sendBtcFeeRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Fee rate'**
  String get sendBtcFeeRateLabel;

  /// No description provided for @sendBtcFeeTierFastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get sendBtcFeeTierFastest;

  /// No description provided for @sendBtcFeeTierHalfHour.
  ///
  /// In en, this message translates to:
  /// **'Half hour'**
  String get sendBtcFeeTierHalfHour;

  /// No description provided for @sendBtcFeeTierHour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get sendBtcFeeTierHour;

  /// No description provided for @sendBtcFeeTierEconomy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get sendBtcFeeTierEconomy;

  /// No description provided for @sendBtcFeeEtaFastest.
  ///
  /// In en, this message translates to:
  /// **'~10 min'**
  String get sendBtcFeeEtaFastest;

  /// No description provided for @sendBtcFeeEtaHalfHour.
  ///
  /// In en, this message translates to:
  /// **'~30 min'**
  String get sendBtcFeeEtaHalfHour;

  /// No description provided for @sendBtcFeeEtaHour.
  ///
  /// In en, this message translates to:
  /// **'~1 hour'**
  String get sendBtcFeeEtaHour;

  /// No description provided for @sendBtcFeeEtaEconomy.
  ///
  /// In en, this message translates to:
  /// **'When the mempool allows'**
  String get sendBtcFeeEtaEconomy;

  /// No description provided for @sendBchRecipientLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipient address (CashAddr)'**
  String get sendBchRecipientLabel;

  /// No description provided for @sendBchExperimentalBody.
  ///
  /// In en, this message translates to:
  /// **'legacy P2PKH with SIGHASH_FORKID. The BIP143 sighash is spec-vector tested via BTC SegWit; the BCH-specific 0x41 sighash byte + legacy tx envelope are unit-tested but unaudited.'**
  String get sendBchExperimentalBody;

  /// No description provided for @sendBchErrorMustBeCashAddr.
  ///
  /// In en, this message translates to:
  /// **'Recipient must be a CashAddr (bitcoincash:q…/p… or just q…/p…)'**
  String get sendBchErrorMustBeCashAddr;

  /// No description provided for @sendBchErrorP2shNotSupported.
  ///
  /// In en, this message translates to:
  /// **'P2SH BCH addresses (p…) aren\'t supported yet — only P2KH (q…) is in this build.'**
  String get sendBchErrorP2shNotSupported;

  /// No description provided for @sendBchFinalFeeHint.
  ///
  /// In en, this message translates to:
  /// **'BCH legacy P2PKH with SIGHASH_FORKID. Once submitted this CANNOT be reversed (BCH does not honor RBF).'**
  String get sendBchFinalFeeHint;

  /// No description provided for @sendBchAvailableShort.
  ///
  /// In en, this message translates to:
  /// **'available'**
  String get sendBchAvailableShort;

  /// No description provided for @sendBchNetworkFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Network fee'**
  String get sendBchNetworkFeeLabel;

  /// No description provided for @sendBchFeeRateDescription.
  ///
  /// In en, this message translates to:
  /// **'{rate} sat/byte — typical 1-input tx ≈ {typical} sat. BCH fees are extremely low.'**
  String sendBchFeeRateDescription(int rate, int typical);

  /// No description provided for @sendBchAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (BCH or sat)'**
  String get sendBchAmountLabel;

  /// No description provided for @sendEthExperimentalBody.
  ///
  /// In en, this message translates to:
  /// **'RLP + EIP-1559 sighash + ECDSA-recovery are unit-tested but the end-to-end send path has not been audited.'**
  String get sendEthExperimentalBody;

  /// No description provided for @sendEthErrorBadAddress.
  ///
  /// In en, this message translates to:
  /// **'Recipient must be a 0x-prefixed 40-hex-character address'**
  String get sendEthErrorBadAddress;

  /// No description provided for @sendEthErrorExceedsToken.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds {symbol} balance'**
  String sendEthErrorExceedsToken(String symbol);

  /// No description provided for @sendEthErrorNoGas.
  ///
  /// In en, this message translates to:
  /// **'No {symbol} for gas — fund this wallet first'**
  String sendEthErrorNoGas(String symbol);

  /// No description provided for @sendEthAmountLabelToken.
  ///
  /// In en, this message translates to:
  /// **'Amount ({symbol} or base units)'**
  String sendEthAmountLabelToken(String symbol);

  /// No description provided for @sendEthAmountLabelNative.
  ///
  /// In en, this message translates to:
  /// **'Amount ({symbol} or wei)'**
  String sendEthAmountLabelNative(String symbol);

  /// No description provided for @sendEthMaxFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Max fee per gas'**
  String get sendEthMaxFeeLabel;

  /// No description provided for @sendEthPriorityFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority fee'**
  String get sendEthPriorityFeeLabel;

  /// No description provided for @sendEthLoadingBalance.
  ///
  /// In en, this message translates to:
  /// **'Loading balance…'**
  String get sendEthLoadingBalance;

  /// No description provided for @sendEthBalanceError.
  ///
  /// In en, this message translates to:
  /// **'Balance error: {error}'**
  String sendEthBalanceError(String error);

  /// No description provided for @sendEthAvailableForGas.
  ///
  /// In en, this message translates to:
  /// **'available · {amount} {symbol} for gas'**
  String sendEthAvailableForGas(String amount, String symbol);

  /// No description provided for @sendEthFeeError.
  ///
  /// In en, this message translates to:
  /// **'Fee data unavailable: {error}'**
  String sendEthFeeError(String error);

  /// No description provided for @sendEthLoadingFee.
  ///
  /// In en, this message translates to:
  /// **'Loading fee rates…'**
  String get sendEthLoadingFee;

  /// No description provided for @sendEthNetworkFeeHeader.
  ///
  /// In en, this message translates to:
  /// **'NETWORK FEE'**
  String get sendEthNetworkFeeHeader;

  /// No description provided for @sendEthAutoBadge.
  ///
  /// In en, this message translates to:
  /// **'AUTO'**
  String get sendEthAutoBadge;

  /// No description provided for @sendEthBaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get sendEthBaseLabel;

  /// No description provided for @sendEthTipLabel.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get sendEthTipLabel;

  /// No description provided for @sendEthMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get sendEthMaxLabel;

  /// No description provided for @sendEthFinalFeeHint.
  ///
  /// In en, this message translates to:
  /// **'Final fee depends on the network base fee at inclusion time. Anything below max is refunded — overpaying doesn\'t actually cost. Once submitted this CANNOT be reversed.'**
  String get sendEthFinalFeeHint;

  /// No description provided for @sendSolExperimentalBody.
  ///
  /// In en, this message translates to:
  /// **'Solana transaction encoding is unit-tested but the end-to-end send path has not been audited.'**
  String get sendSolExperimentalBody;

  /// No description provided for @sendSolErrorBadAddress.
  ///
  /// In en, this message translates to:
  /// **'Address should be 32-44 base58 characters'**
  String get sendSolErrorBadAddress;

  /// No description provided for @sendSolErrorNoSol.
  ///
  /// In en, this message translates to:
  /// **'No SOL for fees — fund this wallet with a small amount of SOL first'**
  String get sendSolErrorNoSol;

  /// No description provided for @sendSolErrorNeedsAtaSol.
  ///
  /// In en, this message translates to:
  /// **'Recipient has no {symbol} account — sending creates one (needs extra ~0.00204 SOL rent + fee).'**
  String sendSolErrorNeedsAtaSol(String symbol);

  /// No description provided for @sendSolErrorNotEnoughSol.
  ///
  /// In en, this message translates to:
  /// **'Not enough SOL for the network fee.'**
  String get sendSolErrorNotEnoughSol;

  /// No description provided for @sendSolErrorAmountFeeExceeds.
  ///
  /// In en, this message translates to:
  /// **'Amount + fee exceeds balance'**
  String get sendSolErrorAmountFeeExceeds;

  /// No description provided for @sendSolAmountLabelToken.
  ///
  /// In en, this message translates to:
  /// **'Amount ({symbol} or base units)'**
  String sendSolAmountLabelToken(String symbol);

  /// No description provided for @sendSolAmountLabelNative.
  ///
  /// In en, this message translates to:
  /// **'Amount (SOL or lamports)'**
  String get sendSolAmountLabelNative;

  /// No description provided for @sendSolAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Solana address'**
  String get sendSolAddressHint;

  /// No description provided for @sendSolNetworkFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Network fee'**
  String get sendSolNetworkFeeLabel;

  /// No description provided for @sendSolAtaRentLabel.
  ///
  /// In en, this message translates to:
  /// **'ATA rent'**
  String get sendSolAtaRentLabel;

  /// No description provided for @sendSolTotalOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Total SOL out'**
  String get sendSolTotalOutLabel;

  /// No description provided for @sendSolFinalFeeHintNative.
  ///
  /// In en, this message translates to:
  /// **'Solana fees are fixed at 5000 lamports per signature. Once submitted this CANNOT be reversed.'**
  String get sendSolFinalFeeHintNative;

  /// No description provided for @sendSolFinalFeeHintNewAta.
  ///
  /// In en, this message translates to:
  /// **'Recipient has no {symbol} account yet. Sending creates one for them (~0.00204 SOL rent, paid by you). Once submitted this CANNOT be reversed.'**
  String sendSolFinalFeeHintNewAta(String symbol);

  /// No description provided for @sendTrxExperimentalBody.
  ///
  /// In en, this message translates to:
  /// **'Tron tx is built by the RPC and signed locally. The txid hash is verified before signing, but we don\'t decode the protobuf body.'**
  String get sendTrxExperimentalBody;

  /// No description provided for @sendTrxErrorBadAddress.
  ///
  /// In en, this message translates to:
  /// **'Recipient must be a base58 Tron address (starts with T, 34 chars)'**
  String get sendTrxErrorBadAddress;

  /// No description provided for @sendTrxErrorNoTrx.
  ///
  /// In en, this message translates to:
  /// **'No TRX for bandwidth/energy — fund this wallet with TRX first'**
  String get sendTrxErrorNoTrx;

  /// No description provided for @sendTrxRecipientLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipient (Tron base58)'**
  String get sendTrxRecipientLabel;

  /// No description provided for @sendTrxAmountLabelToken.
  ///
  /// In en, this message translates to:
  /// **'Amount ({symbol} or base units)'**
  String sendTrxAmountLabelToken(String symbol);

  /// No description provided for @sendTrxAmountLabelNative.
  ///
  /// In en, this message translates to:
  /// **'Amount (TRX or sun)'**
  String get sendTrxAmountLabelNative;

  /// No description provided for @sendTrxBandwidthLabel.
  ///
  /// In en, this message translates to:
  /// **'Bandwidth/energy'**
  String get sendTrxBandwidthLabel;

  /// No description provided for @sendTrxBandwidthToken.
  ///
  /// In en, this message translates to:
  /// **'Up to ~30 TRX-equiv (TRC-20)'**
  String get sendTrxBandwidthToken;

  /// No description provided for @sendTrxBandwidthNative.
  ///
  /// In en, this message translates to:
  /// **'Free quota or ~0.27 TRX'**
  String get sendTrxBandwidthNative;

  /// No description provided for @sendTrxFinalFeeHint.
  ///
  /// In en, this message translates to:
  /// **'Tron transactions are built by the RPC node; we re-verify the txid hash before signing locally. Once submitted this CANNOT be reversed.'**
  String get sendTrxFinalFeeHint;

  /// No description provided for @sendXmrTitle.
  ///
  /// In en, this message translates to:
  /// **'Send XMR'**
  String get sendXmrTitle;

  /// No description provided for @sendXmrScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan recipient address'**
  String get sendXmrScanTitle;

  /// No description provided for @sendXmrAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available: {amount} XMR'**
  String sendXmrAvailable(String amount);

  /// No description provided for @sendXmrAddRecipient.
  ///
  /// In en, this message translates to:
  /// **'Add recipient'**
  String get sendXmrAddRecipient;

  /// No description provided for @sendXmrSendAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Send all'**
  String get sendXmrSendAllTitle;

  /// No description provided for @sendXmrSendAllBody.
  ///
  /// In en, this message translates to:
  /// **'Sweep every spendable output to the first recipient — fee will be subtracted automatically.'**
  String get sendXmrSendAllBody;

  /// No description provided for @sendXmrFeePriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Fee priority'**
  String get sendXmrFeePriorityLabel;

  /// No description provided for @sendXmrTierSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get sendXmrTierSlow;

  /// No description provided for @sendXmrTierNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get sendXmrTierNormal;

  /// No description provided for @sendXmrTierFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get sendXmrTierFast;

  /// No description provided for @sendXmrReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review send'**
  String get sendXmrReviewAction;

  /// No description provided for @sendXmrToLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get sendXmrToLabel;

  /// No description provided for @sendXmrToNumbered.
  ///
  /// In en, this message translates to:
  /// **'To #{index}'**
  String sendXmrToNumbered(int index);

  /// No description provided for @sendXmrSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get sendXmrSubtotalLabel;

  /// No description provided for @sendXmrSweepLabel.
  ///
  /// In en, this message translates to:
  /// **'Sending (sweep)'**
  String get sendXmrSweepLabel;

  /// No description provided for @sendXmrNetworkFee.
  ///
  /// In en, this message translates to:
  /// **'Network fee'**
  String get sendXmrNetworkFee;

  /// No description provided for @sendXmrSplitWarning.
  ///
  /// In en, this message translates to:
  /// **'This send will be relayed as {count} sub-transactions.'**
  String sendXmrSplitWarning(int count);

  /// No description provided for @sendXmrBroadcastTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction broadcast'**
  String get sendXmrBroadcastTitle;

  /// No description provided for @sendXmrBroadcastBody.
  ///
  /// In en, this message translates to:
  /// **'It will appear in your transaction history once the network confirms it.'**
  String get sendXmrBroadcastBody;

  /// No description provided for @sendXmrTxIdLabel.
  ///
  /// In en, this message translates to:
  /// **'TX ID'**
  String get sendXmrTxIdLabel;

  /// No description provided for @sendXmrTxIdCopied.
  ///
  /// In en, this message translates to:
  /// **'TX ID copied'**
  String get sendXmrTxIdCopied;

  /// No description provided for @sendXmrCopyTxIdAction.
  ///
  /// In en, this message translates to:
  /// **'Copy TX ID'**
  String get sendXmrCopyTxIdAction;

  /// No description provided for @sendXmrDoneAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get sendXmrDoneAction;

  /// No description provided for @sendXmrRecipientHeader.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get sendXmrRecipientHeader;

  /// No description provided for @sendXmrRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get sendXmrRemoveTooltip;

  /// No description provided for @sendXmrAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipient address'**
  String get sendXmrAddressLabel;

  /// No description provided for @sendXmrAddressBookTooltip.
  ///
  /// In en, this message translates to:
  /// **'Address book'**
  String get sendXmrAddressBookTooltip;

  /// No description provided for @sendXmrPasteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get sendXmrPasteTooltip;

  /// No description provided for @sendXmrAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (XMR)'**
  String get sendXmrAmountLabel;

  /// No description provided for @sendXmrAmountHintSweep.
  ///
  /// In en, this message translates to:
  /// **'Sweep — amount set automatically'**
  String get sendXmrAmountHintSweep;

  /// No description provided for @sendXmrErrorBadAddress.
  ///
  /// In en, this message translates to:
  /// **'Address doesn\'t look like Monero{tag}.'**
  String sendXmrErrorBadAddress(String tag);

  /// No description provided for @sendXmrErrorAmountZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0{tag}.'**
  String sendXmrErrorAmountZero(String tag);

  /// No description provided for @sendXmrErrorExceedsBalance.
  ///
  /// In en, this message translates to:
  /// **'Total exceeds your balance.'**
  String get sendXmrErrorExceedsBalance;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsMoneroNode.
  ///
  /// In en, this message translates to:
  /// **'Monero node'**
  String get settingsMoneroNode;

  /// No description provided for @settingsMoneroNodeBody.
  ///
  /// In en, this message translates to:
  /// **'The Monero daemon PeekWallet connects to for sync. Default is Cake Wallet\'s public node. For full privacy, run your own monerod and point this at it.'**
  String get settingsMoneroNodeBody;

  /// No description provided for @settingsDaemonUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Daemon URL'**
  String get settingsDaemonUrlLabel;

  /// No description provided for @settingsPasteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get settingsPasteTooltip;

  /// No description provided for @settingsConnectsToPreview.
  ///
  /// In en, this message translates to:
  /// **'Connects to {hostPort} (ssl={ssl})'**
  String settingsConnectsToPreview(String hostPort, String ssl);

  /// No description provided for @settingsMessageBadUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not parse that URL. Try e.g. https://node.example.com:18081'**
  String get settingsMessageBadUrl;

  /// No description provided for @settingsMessageSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. Lock + unlock the app to switch your wallet to the new node.'**
  String get settingsMessageSaved;

  /// No description provided for @settingsMessageReset.
  ///
  /// In en, this message translates to:
  /// **'Reset. The app will use {url} on next unlock.'**
  String settingsMessageReset(String url);

  /// No description provided for @settingsResetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get settingsResetToDefault;

  /// No description provided for @settingsSectionPublicNodes.
  ///
  /// In en, this message translates to:
  /// **'Public nodes'**
  String get settingsSectionPublicNodes;

  /// No description provided for @settingsSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSectionSecurity;

  /// No description provided for @settingsSectionDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get settingsSectionDisplay;

  /// No description provided for @settingsBiometricUnlock.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get settingsBiometricUnlock;

  /// No description provided for @settingsBiometricUnlockOn.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint / face to unlock'**
  String get settingsBiometricUnlockOn;

  /// No description provided for @settingsBiometricUnlockOff.
  ///
  /// In en, this message translates to:
  /// **'Not available — no enrolled biometric'**
  String get settingsBiometricUnlockOff;

  /// No description provided for @settingsBiometricEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable biometric unlock'**
  String get settingsBiometricEnableTitle;

  /// No description provided for @settingsBiometricEnableHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your app password to confirm'**
  String get settingsBiometricEnableHint;

  /// No description provided for @settingsBiometricEnableFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not enable: {error}'**
  String settingsBiometricEnableFailed(String error);

  /// No description provided for @settingsPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingsPasswordLabel;

  /// No description provided for @settingsRevealSeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reveal recovery phrase'**
  String get settingsRevealSeedTitle;

  /// No description provided for @settingsRevealSeedBody.
  ///
  /// In en, this message translates to:
  /// **'View your BIP39 seed + Monero spend/view keys'**
  String get settingsRevealSeedBody;

  /// No description provided for @settingsAddressBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Address book'**
  String get settingsAddressBookTitle;

  /// No description provided for @settingsAddressBookBody.
  ///
  /// In en, this message translates to:
  /// **'Saved labels for recipients you send to'**
  String get settingsAddressBookBody;

  /// No description provided for @settingsAutoLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock'**
  String get settingsAutoLockTitle;

  /// No description provided for @settingsAutoLockSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock after backgrounding'**
  String get settingsAutoLockSheetTitle;

  /// No description provided for @settingsAutoLockSheetBody.
  ///
  /// In en, this message translates to:
  /// **'How long PeekWallet can stay unlocked while you\'re using other apps. Returning within this window keeps you logged in; longer and the password is required again.'**
  String get settingsAutoLockSheetBody;

  /// No description provided for @settingsAutoLockImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get settingsAutoLockImmediately;

  /// No description provided for @settingsAutoLockNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get settingsAutoLockNever;

  /// No description provided for @settingsAutoLockSeconds.
  ///
  /// In en, this message translates to:
  /// **'{n} s'**
  String settingsAutoLockSeconds(int n);

  /// No description provided for @settingsAutoLock30Seconds.
  ///
  /// In en, this message translates to:
  /// **'30 seconds'**
  String get settingsAutoLock30Seconds;

  /// No description provided for @settingsAutoLock1Minute.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get settingsAutoLock1Minute;

  /// No description provided for @settingsAutoLock2MinutesDefault.
  ///
  /// In en, this message translates to:
  /// **'2 minutes (default)'**
  String get settingsAutoLock2MinutesDefault;

  /// No description provided for @settingsAutoLock5Minutes.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get settingsAutoLock5Minutes;

  /// No description provided for @settingsAutoLock15Minutes.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get settingsAutoLock15Minutes;

  /// No description provided for @settingsAutoLock1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get settingsAutoLock1Hour;

  /// No description provided for @settingsLockAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock app'**
  String get settingsLockAppTitle;

  /// No description provided for @settingsLockAppBody.
  ///
  /// In en, this message translates to:
  /// **'Clear the in-memory seed and require the password again'**
  String get settingsLockAppBody;

  /// No description provided for @settingsLockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock app?'**
  String get settingsLockConfirmTitle;

  /// No description provided for @settingsLockConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to enter your password to unlock. Any in-progress Monero sync will pick up where it left off.'**
  String get settingsLockConfirmBody;

  /// No description provided for @settingsLockConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get settingsLockConfirmAction;

  /// No description provided for @settingsDisplayCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Display currency'**
  String get settingsDisplayCurrencyTitle;

  /// No description provided for @settingsDisplayCurrencyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settingsDisplayCurrencyDisabled;

  /// No description provided for @settingsShowFiatValues.
  ///
  /// In en, this message translates to:
  /// **'Show fiat values'**
  String get settingsShowFiatValues;

  /// No description provided for @settingsShowFiatValuesBody.
  ///
  /// In en, this message translates to:
  /// **'Polls CoinGecko every 5 min. No PII sent.'**
  String get settingsShowFiatValuesBody;

  /// No description provided for @settingsExportLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Export logs'**
  String get settingsExportLogsTitle;

  /// No description provided for @settingsExportLogsBody.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days. Addresses and keys are auto-redacted.'**
  String get settingsExportLogsBody;

  /// No description provided for @settingsExportLogsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No logs to export yet.'**
  String get settingsExportLogsEmpty;

  /// No description provided for @settingsExportLogsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Logs (last 7 days)'**
  String get settingsExportLogsDialogTitle;

  /// No description provided for @settingsExportLogsCopied.
  ///
  /// In en, this message translates to:
  /// **'Logs copied to clipboard'**
  String get settingsExportLogsCopied;

  /// No description provided for @settingsCloseAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settingsCloseAction;

  /// No description provided for @settingsRestoreAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore all coins from vault seed'**
  String get settingsRestoreAllTitle;

  /// No description provided for @settingsRestoreAllBody.
  ///
  /// In en, this message translates to:
  /// **'One-tap derive a wallet for every coin from your existing 12/24-word seed.'**
  String get settingsRestoreAllBody;

  /// No description provided for @settingsCustomRpcTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom RPC endpoints'**
  String get settingsCustomRpcTitle;

  /// No description provided for @settingsCustomRpcBody.
  ///
  /// In en, this message translates to:
  /// **'Point BTC/LTC/BCH/ETH/POL/SOL/TRX at your own nodes.'**
  String get settingsCustomRpcBody;

  /// No description provided for @settingsUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsUpdateTitle;

  /// No description provided for @settingsUpdateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking GitHub…'**
  String get settingsUpdateChecking;

  /// No description provided for @settingsUpdateTapToCheck.
  ///
  /// In en, this message translates to:
  /// **'Tap to check'**
  String get settingsUpdateTapToCheck;

  /// No description provided for @settingsUpdateFailedFallback.
  ///
  /// In en, this message translates to:
  /// **'Check failed'**
  String get settingsUpdateFailedFallback;

  /// No description provided for @settingsUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available — released {ago}. Tap to download.'**
  String settingsUpdateAvailable(String ago);

  /// No description provided for @settingsUpdateDebugBuild.
  ///
  /// In en, this message translates to:
  /// **'Debug build — version check disabled. Tap to retry.'**
  String get settingsUpdateDebugBuild;

  /// No description provided for @settingsUpdateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date · checked just now'**
  String get settingsUpdateUpToDate;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About PeekWallet'**
  String get settingsAboutTitle;

  /// No description provided for @settingsAboutBody.
  ///
  /// In en, this message translates to:
  /// **'Version, license, source code'**
  String get settingsAboutBody;

  /// No description provided for @addWalletChooseCoin.
  ///
  /// In en, this message translates to:
  /// **'Choose coin'**
  String get addWalletChooseCoin;

  /// No description provided for @addWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {coin} wallet'**
  String addWalletTitle(String coin);

  /// No description provided for @addWalletCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create new wallet'**
  String get addWalletCreateTitle;

  /// No description provided for @addWalletCreateBody.
  ///
  /// In en, this message translates to:
  /// **'Generate a fresh seed phrase. Anyone with the phrase can spend the wallet — write it down on paper.'**
  String get addWalletCreateBody;

  /// No description provided for @addWalletRestoreSeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from seed'**
  String get addWalletRestoreSeedTitle;

  /// No description provided for @addWalletRestoreSeedBody.
  ///
  /// In en, this message translates to:
  /// **'Use a recovery phrase you already have (BIP39 12/24 words, Monero 25-word seed, or Polyseed 14 words).'**
  String get addWalletRestoreSeedBody;

  /// No description provided for @addWalletRestoreKeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from keys'**
  String get addWalletRestoreKeysTitle;

  /// No description provided for @addWalletRestoreKeysBody.
  ///
  /// In en, this message translates to:
  /// **'Address + private spend key + private view key. Use this when you have the keys but not a seed phrase.'**
  String get addWalletRestoreKeysBody;

  /// No description provided for @addWalletFormatNew.
  ///
  /// In en, this message translates to:
  /// **'New seed format'**
  String get addWalletFormatNew;

  /// No description provided for @addWalletFormatRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore format'**
  String get addWalletFormatRestore;

  /// No description provided for @addWalletFormatBip39Hint.
  ///
  /// In en, this message translates to:
  /// **'BIP39 mnemonic — the standard 12/24 word format used by every modern wallet. Trezor, Ledger. Universal across many coins.'**
  String get addWalletFormatBip39Hint;

  /// No description provided for @addWalletFormatMoneroLegacyHint.
  ///
  /// In en, this message translates to:
  /// **'Native Monero electrum-style seed. Direct interop with Cake, Feather, and Monero GUI.'**
  String get addWalletFormatMoneroLegacyHint;

  /// No description provided for @addWalletFormatPolyseedHint.
  ///
  /// In en, this message translates to:
  /// **'Newer Monero standard — 14 words. Restore height baked in.'**
  String get addWalletFormatPolyseedHint;

  /// No description provided for @addWalletFormatKeysOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Spend key + view key + address. No words.'**
  String get addWalletFormatKeysOnlyHint;

  /// No description provided for @addWalletVaultLocked.
  ///
  /// In en, this message translates to:
  /// **'Vault is locked — re-unlock and try again.'**
  String get addWalletVaultLocked;

  /// No description provided for @addWalletGenerateHeader.
  ///
  /// In en, this message translates to:
  /// **'Generate a {format}'**
  String addWalletGenerateHeader(String format);

  /// No description provided for @addWalletGenerateBody.
  ///
  /// In en, this message translates to:
  /// **'When you tap Generate, the words will appear once. Write them down on paper before continuing. Anyone with these words can drain this wallet.'**
  String get addWalletGenerateBody;

  /// No description provided for @addWalletGenerateAction.
  ///
  /// In en, this message translates to:
  /// **'Generate seed'**
  String get addWalletGenerateAction;

  /// No description provided for @addWalletWriteThisDown.
  ///
  /// In en, this message translates to:
  /// **'Write this down'**
  String get addWalletWriteThisDown;

  /// No description provided for @addWalletWordsWarning.
  ///
  /// In en, this message translates to:
  /// **'These words ARE the wallet. Anyone with them can spend it.'**
  String get addWalletWordsWarning;

  /// No description provided for @addWalletCopyClipboardClears.
  ///
  /// In en, this message translates to:
  /// **'Copied — clipboard auto-clears in 30 s'**
  String get addWalletCopyClipboardClears;

  /// No description provided for @addWalletCopyPhraseAction.
  ///
  /// In en, this message translates to:
  /// **'Copy phrase'**
  String get addWalletCopyPhraseAction;

  /// No description provided for @addWalletNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet name (only you can see this)'**
  String get addWalletNameLabel;

  /// No description provided for @addWalletNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. \"Main Monero\"'**
  String get addWalletNameHint;

  /// No description provided for @addWalletSavedConfirm.
  ///
  /// In en, this message translates to:
  /// **'I have saved the words — add wallet'**
  String get addWalletSavedConfirm;

  /// No description provided for @addWalletRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore {format}'**
  String addWalletRestoreTitle(String format);

  /// No description provided for @addWalletRestoreNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet name'**
  String get addWalletRestoreNameLabel;

  /// No description provided for @addWalletRestoreNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. \"Imported from Cake\"'**
  String get addWalletRestoreNameHint;

  /// No description provided for @addWalletRecoveryPhraseLabel.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase'**
  String get addWalletRecoveryPhraseLabel;

  /// No description provided for @addWalletSeedWordsLabel.
  ///
  /// In en, this message translates to:
  /// **'Seed words'**
  String get addWalletSeedWordsLabel;

  /// No description provided for @addWalletPassphraseLabel.
  ///
  /// In en, this message translates to:
  /// **'BIP39 passphrase (25th word) — optional'**
  String get addWalletPassphraseLabel;

  /// No description provided for @addWalletPassphraseHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank if not used'**
  String get addWalletPassphraseHint;

  /// No description provided for @addWalletPassphraseWarning.
  ///
  /// In en, this message translates to:
  /// **'If the source wallet had a passphrase, you MUST enter it — otherwise you\'ll get a different wallet entirely.'**
  String get addWalletPassphraseWarning;

  /// No description provided for @addWalletSeedOffsetLabel.
  ///
  /// In en, this message translates to:
  /// **'Seed offset — optional'**
  String get addWalletSeedOffsetLabel;

  /// No description provided for @addWalletSeedOffsetHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank if the seed isn\'t encrypted'**
  String get addWalletSeedOffsetHint;

  /// No description provided for @addWalletRestoreHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Restore height — optional'**
  String get addWalletRestoreHeightLabel;

  /// No description provided for @addWalletRestoreHeightHint.
  ///
  /// In en, this message translates to:
  /// **'Block number to start scanning from'**
  String get addWalletRestoreHeightHint;

  /// No description provided for @addWalletRestoreHeightBody.
  ///
  /// In en, this message translates to:
  /// **'Lower = more thorough but slower sync; higher = faster but might miss old receipts.'**
  String get addWalletRestoreHeightBody;

  /// No description provided for @addWalletRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore wallet'**
  String get addWalletRestoreAction;

  /// No description provided for @addWalletKeysRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from keys'**
  String get addWalletKeysRestoreTitle;

  /// No description provided for @addWalletPrimaryAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary address'**
  String get addWalletPrimaryAddressLabel;

  /// No description provided for @addWalletSpendKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Private spend key (hex)'**
  String get addWalletSpendKeyLabel;

  /// No description provided for @addWalletViewKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Private view key (hex)'**
  String get addWalletViewKeyLabel;

  /// No description provided for @addWalletKeysRestoreHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Restore height'**
  String get addWalletKeysRestoreHeightLabel;

  /// No description provided for @addWalletKeysRestoreHeightHint.
  ///
  /// In en, this message translates to:
  /// **'Block number — earlier covers older receipts'**
  String get addWalletKeysRestoreHeightHint;

  /// No description provided for @addWalletScanAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan address'**
  String get addWalletScanAddressTitle;

  /// No description provided for @addWalletConfirmPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get addWalletConfirmPasswordTitle;

  /// No description provided for @addWalletAppPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'App password'**
  String get addWalletAppPasswordLabel;

  /// No description provided for @lockTryAgainIn.
  ///
  /// In en, this message translates to:
  /// **'Try again in {duration}.'**
  String lockTryAgainIn(String duration);

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Self-custodial wallet for BTC, ETH, XMR, and more.'**
  String get welcomeTagline;

  /// No description provided for @welcomeCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create new wallet'**
  String get welcomeCreateAction;

  /// No description provided for @welcomeImportAction.
  ///
  /// In en, this message translates to:
  /// **'I already have a recovery phrase'**
  String get welcomeImportAction;

  /// No description provided for @welcomeBackupWarning.
  ///
  /// In en, this message translates to:
  /// **'Your 12-word recovery phrase is the only backup. Anyone with it can take your funds.'**
  String get welcomeBackupWarning;

  /// No description provided for @welcomeDisclaimerAction.
  ///
  /// In en, this message translates to:
  /// **'Read the no-warranty disclaimer'**
  String get welcomeDisclaimerAction;

  /// No description provided for @welcomeDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get welcomeDisclaimerTitle;

  /// No description provided for @welcomeCopiedToast.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get welcomeCopiedToast;

  /// No description provided for @welcomeCopyTextAction.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get welcomeCopyTextAction;

  /// No description provided for @welcomeIUnderstandAction.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get welcomeIUnderstandAction;

  /// No description provided for @revealSeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reveal recovery phrase'**
  String get revealSeedTitle;

  /// No description provided for @revealSeedWarning.
  ///
  /// In en, this message translates to:
  /// **'You are about to reveal your seed phrase and Monero keys. Anyone who sees them can take your funds — make sure no one is looking at your screen and you\'re not screen-sharing.'**
  String get revealSeedWarning;

  /// No description provided for @revealSeedPasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your app password to continue.'**
  String get revealSeedPasswordPrompt;

  /// No description provided for @revealSeedRevealAction.
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get revealSeedRevealAction;

  /// No description provided for @revealSeedBip39Section.
  ///
  /// In en, this message translates to:
  /// **'BIP39 recovery phrase'**
  String get revealSeedBip39Section;

  /// No description provided for @revealSeedPassphraseSection.
  ///
  /// In en, this message translates to:
  /// **'BIP39 passphrase (25th word)'**
  String get revealSeedPassphraseSection;

  /// No description provided for @revealSeedXmrAddressSection.
  ///
  /// In en, this message translates to:
  /// **'Monero primary address'**
  String get revealSeedXmrAddressSection;

  /// No description provided for @revealSeedXmrSpendSection.
  ///
  /// In en, this message translates to:
  /// **'Monero private spend key'**
  String get revealSeedXmrSpendSection;

  /// No description provided for @revealSeedXmrViewSection.
  ///
  /// In en, this message translates to:
  /// **'Monero private view key'**
  String get revealSeedXmrViewSection;

  /// No description provided for @revealSeedCopyPhrase.
  ///
  /// In en, this message translates to:
  /// **'Copy phrase'**
  String get revealSeedCopyPhrase;

  /// No description provided for @revealSeedCopyPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Copy passphrase'**
  String get revealSeedCopyPassphrase;

  /// No description provided for @revealSeedCopyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get revealSeedCopyAddress;

  /// No description provided for @revealSeedCopySpendKey.
  ///
  /// In en, this message translates to:
  /// **'Copy spend key'**
  String get revealSeedCopySpendKey;

  /// No description provided for @revealSeedCopyViewKey.
  ///
  /// In en, this message translates to:
  /// **'Copy view key'**
  String get revealSeedCopyViewKey;

  /// No description provided for @revealSeedRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'You can restore this wallet in Cake / Feather / Monero GUI using \"Restore from keys\" with the address + view key + spend key above (or \"Restore from seed\" with the BIP39 phrase in any BIP39-compatible wallet).'**
  String get revealSeedRestoreHint;

  /// No description provided for @revealSeedCopiedSensitive.
  ///
  /// In en, this message translates to:
  /// **'Copied — clipboard auto-clears in 30 s'**
  String get revealSeedCopiedSensitive;

  /// No description provided for @revealSeedCopiedPlain.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get revealSeedCopiedPlain;

  /// No description provided for @aboutScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutScreenTitle;

  /// No description provided for @aboutVersionLine.
  ///
  /// In en, this message translates to:
  /// **'v{version} (build {build})'**
  String aboutVersionLine(String version, String build);

  /// No description provided for @aboutAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get aboutAppVersion;

  /// No description provided for @aboutBuildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build number'**
  String get aboutBuildNumber;

  /// No description provided for @aboutPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get aboutPackage;

  /// No description provided for @aboutBuildSignature.
  ///
  /// In en, this message translates to:
  /// **'Build signature'**
  String get aboutBuildSignature;

  /// No description provided for @aboutSourceSection.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get aboutSourceSection;

  /// No description provided for @aboutLegalSection.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get aboutLegalSection;

  /// No description provided for @aboutGithubRepo.
  ///
  /// In en, this message translates to:
  /// **'GitHub repository'**
  String get aboutGithubRepo;

  /// No description provided for @aboutLicenseLink.
  ///
  /// In en, this message translates to:
  /// **'License (GPL-3.0-or-later)'**
  String get aboutLicenseLink;

  /// No description provided for @aboutDisclaimerLink.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer (no warranty)'**
  String get aboutDisclaimerLink;

  /// No description provided for @aboutSecurityModelLink.
  ///
  /// In en, this message translates to:
  /// **'Security model'**
  String get aboutSecurityModelLink;

  /// No description provided for @aboutFreeSoftwareBody.
  ///
  /// In en, this message translates to:
  /// **'PeekWallet is free, open-source software. Anyone can read the source, build it themselves, and verify the binary on /releases matches the public code (reproducibility tracked in the roadmap).'**
  String get aboutFreeSoftwareBody;

  /// No description provided for @aboutUrlCopiedToast.
  ///
  /// In en, this message translates to:
  /// **'URL copied — open in your browser'**
  String get aboutUrlCopiedToast;

  /// No description provided for @addressBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Address book'**
  String get addressBookTitle;

  /// No description provided for @addressBookPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick recipient'**
  String get addressBookPickerTitle;

  /// No description provided for @addressBookAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get addressBookAddTooltip;

  /// No description provided for @addressBookEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses yet'**
  String get addressBookEmptyTitle;

  /// No description provided for @addressBookEmptyBodyPicker.
  ///
  /// In en, this message translates to:
  /// **'Save the recipient you\'re about to send to.'**
  String get addressBookEmptyBodyPicker;

  /// No description provided for @addressBookEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Save the addresses of people you send to often so you don\'t have to paste each time.'**
  String get addressBookEmptyBody;

  /// No description provided for @addressBookAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get addressBookAddAction;

  /// No description provided for @addressBookErrorLabelEmpty.
  ///
  /// In en, this message translates to:
  /// **'Label cannot be empty.'**
  String get addressBookErrorLabelEmpty;

  /// No description provided for @addressBookErrorAddressEmpty.
  ///
  /// In en, this message translates to:
  /// **'Address cannot be empty.'**
  String get addressBookErrorAddressEmpty;

  /// No description provided for @addressBookDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete entry?'**
  String get addressBookDeleteTitle;

  /// No description provided for @addressBookDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The address is not affected — only this saved label / note is removed.'**
  String get addressBookDeleteBody;

  /// No description provided for @addressBookDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get addressBookDeleteAction;

  /// No description provided for @addressBookEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit address'**
  String get addressBookEditTitle;

  /// No description provided for @addressBookAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addressBookAddTitle;

  /// No description provided for @addressBookDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get addressBookDeleteTooltip;

  /// No description provided for @addressBookLabelField.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get addressBookLabelField;

  /// No description provided for @addressBookAddressField.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressBookAddressField;

  /// No description provided for @addressBookAddressLocked.
  ///
  /// In en, this message translates to:
  /// **'Addresses can\'t be edited — delete and re-add to change.'**
  String get addressBookAddressLocked;

  /// No description provided for @addressBookScanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get addressBookScanTooltip;

  /// No description provided for @addressBookPasteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get addressBookPasteTooltip;

  /// No description provided for @addressBookNotesField.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get addressBookNotesField;

  /// No description provided for @addressBookNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Free-text — only stored locally.'**
  String get addressBookNotesHint;

  /// No description provided for @addressBookSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get addressBookSaveChanges;

  /// No description provided for @addressBookAddToBook.
  ///
  /// In en, this message translates to:
  /// **'Add to book'**
  String get addressBookAddToBook;

  /// No description provided for @qrScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get qrScanTitle;

  /// No description provided for @qrScanTorchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Torch'**
  String get qrScanTorchTooltip;

  /// No description provided for @qrScanCameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera error: {code}'**
  String qrScanCameraError(String code);

  /// No description provided for @qrScanPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied'**
  String get qrScanPermissionDenied;

  /// No description provided for @qrScanPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'PeekWallet needs camera access to scan QR codes. The camera is only used while this screen is open and only reads the QR payload.'**
  String get qrScanPermissionBody;

  /// No description provided for @qrScanTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get qrScanTryAgain;

  /// No description provided for @qrScanOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get qrScanOpenSettings;

  /// No description provided for @qrScanCenterHint.
  ///
  /// In en, this message translates to:
  /// **'Center the QR code in the frame'**
  String get qrScanCenterHint;

  /// No description provided for @rpcResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all overrides?'**
  String get rpcResetTitle;

  /// No description provided for @rpcResetBody.
  ///
  /// In en, this message translates to:
  /// **'Every chain will go back to its public default endpoint. You can re-add overrides at any time.'**
  String get rpcResetBody;

  /// No description provided for @rpcResetAction.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get rpcResetAction;

  /// No description provided for @rpcScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom RPC endpoints'**
  String get rpcScreenTitle;

  /// No description provided for @rpcResetAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset all'**
  String get rpcResetAllTooltip;

  /// No description provided for @rpcIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Point each chain at your own node instead of the public default. Leaving a field blank keeps the current default.'**
  String get rpcIntroBody;

  /// No description provided for @rpcDefaultHint.
  ///
  /// In en, this message translates to:
  /// **'Default: {hint}'**
  String rpcDefaultHint(String hint);

  /// No description provided for @rpcSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get rpcSaveAction;

  /// No description provided for @rpcPrivacyNotesBody.
  ///
  /// In en, this message translates to:
  /// **'Privacy notes:\n• Public defaults see your IP address and which addresses you query. Run your own node or proxy through a VPN / LAN over Tailscale.\n• Custom RPC endpoints sent here go straight to whatever URL you enter — your network sees the destination. Pick providers you trust.'**
  String get rpcPrivacyNotesBody;

  /// No description provided for @restoreAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore all coins from vault'**
  String get restoreAllTitle;

  /// No description provided for @restoreAllIntro.
  ///
  /// In en, this message translates to:
  /// **'Adds a wallet for every supported coin, derived from your existing 12/24-word vault seed.'**
  String get restoreAllIntro;

  /// No description provided for @restoreAllNote.
  ///
  /// In en, this message translates to:
  /// **'Existing wallets are skipped (no duplicates). Monero is excluded — it has a separate seed format and is restored from its own setup.'**
  String get restoreAllNote;

  /// No description provided for @restoreAllAction.
  ///
  /// In en, this message translates to:
  /// **'Restore all from vault seed'**
  String get restoreAllAction;

  /// No description provided for @restoreAllVaultLocked.
  ///
  /// In en, this message translates to:
  /// **'Vault is locked. Unlock and try again.'**
  String get restoreAllVaultLocked;

  /// No description provided for @restoreAllHasWallet.
  ///
  /// In en, this message translates to:
  /// **'Already have a {symbol} wallet — skip'**
  String restoreAllHasWallet(String symbol);

  /// No description provided for @restoreAllWillDerive.
  ///
  /// In en, this message translates to:
  /// **'Will derive from BIP39 vault seed'**
  String get restoreAllWillDerive;

  /// No description provided for @showSeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase · {name}'**
  String showSeedTitle(String name);

  /// No description provided for @showSeedPasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your app password to see this wallet\'s recovery phrase.'**
  String get showSeedPasswordPrompt;

  /// No description provided for @showSeedPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'App password'**
  String get showSeedPasswordLabel;

  /// No description provided for @showSeedRevealAction.
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get showSeedRevealAction;

  /// No description provided for @showSeedRecoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase'**
  String get showSeedRecoveryPhrase;

  /// No description provided for @showSeedCopyPhrase.
  ///
  /// In en, this message translates to:
  /// **'Copy phrase'**
  String get showSeedCopyPhrase;

  /// No description provided for @showSeedCopyClipboardClears.
  ///
  /// In en, this message translates to:
  /// **'Copied — clipboard auto-clears in 30s'**
  String get showSeedCopyClipboardClears;

  /// No description provided for @showSeedPassphraseSection.
  ///
  /// In en, this message translates to:
  /// **'Passphrase (25th word)'**
  String get showSeedPassphraseSection;

  /// No description provided for @showSeedSeedOffsetSection.
  ///
  /// In en, this message translates to:
  /// **'Seed offset'**
  String get showSeedSeedOffsetSection;

  /// No description provided for @showSeedAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get showSeedAddressLabel;

  /// No description provided for @showSeedViewKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'View key'**
  String get showSeedViewKeyLabel;

  /// No description provided for @showSeedSpendKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Spend key'**
  String get showSeedSpendKeyLabel;

  /// No description provided for @showSeedCopySpendKey.
  ///
  /// In en, this message translates to:
  /// **'Copy spend key'**
  String get showSeedCopySpendKey;

  /// No description provided for @showSeedStorageFooter.
  ///
  /// In en, this message translates to:
  /// **'Storage: {format}. Coin: {coin}.'**
  String showSeedStorageFooter(String format, String coin);

  /// No description provided for @showSeedWriteDownWarning.
  ///
  /// In en, this message translates to:
  /// **'Write this down on paper and store it somewhere safe. Anyone with this phrase has full control of the wallet. Don\'t take a screenshot — FLAG_SECURE blocks it anyway.'**
  String get showSeedWriteDownWarning;

  /// No description provided for @showSeedKeysOnlyDisplay.
  ///
  /// In en, this message translates to:
  /// **'Keys only'**
  String get showSeedKeysOnlyDisplay;

  /// No description provided for @erc20EmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No tokens yet — receive USDT/USDC/DAI to this address or tap \"Add token\" to track another ERC-20 by contract address.'**
  String get erc20EmptyHint;

  /// No description provided for @ercAddCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Add custom ERC-20 token'**
  String get ercAddCustomTitle;

  /// No description provided for @ercAddCustomBody.
  ///
  /// In en, this message translates to:
  /// **'Paste the token\'s contract address. We\'ll fetch its symbol and decimals from the chain.'**
  String get ercAddCustomBody;

  /// No description provided for @ercContractLabel.
  ///
  /// In en, this message translates to:
  /// **'Contract address'**
  String get ercContractLabel;

  /// No description provided for @ercProbeAction.
  ///
  /// In en, this message translates to:
  /// **'Probe'**
  String get ercProbeAction;

  /// No description provided for @ercContractError.
  ///
  /// In en, this message translates to:
  /// **'Contract must be 0x + 40 hex chars'**
  String get ercContractError;

  /// No description provided for @ercProbingMsg.
  ///
  /// In en, this message translates to:
  /// **'Probing {prefix}…'**
  String ercProbingMsg(String prefix);

  /// No description provided for @ercProbeFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Could not read token metadata — wrong chain or not an ERC-20?'**
  String get ercProbeFailedMsg;

  /// No description provided for @ercAddedMsg.
  ///
  /// In en, this message translates to:
  /// **'Added {symbol} ({decimals} decimals)'**
  String ercAddedMsg(String symbol, int decimals);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id', 'ms', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
    case 'ms':
      return AppLocalizationsMs();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
