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
