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
  String receiveTitle(String coinId) {
    return 'Receive $coinId';
  }

  @override
  String get receiveAddressLabel => 'YOUR ADDRESS';

  @override
  String get receiveAddressCopied => 'Address copied';

  @override
  String balanceCached(String ago) {
    return 'Cached · $ago ago';
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
}
