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

  /// Tagline below the PeekWallet wordmark on the lock screen
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

  /// No description provided for @homeTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get homeTotalBalance;

  /// Shown in the portfolio hero chip — e.g. '3 / 5 synced'
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

  /// No description provided for @balanceCached.
  ///
  /// In en, this message translates to:
  /// **'Cached · {ago} ago'**
  String balanceCached(String ago);

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
