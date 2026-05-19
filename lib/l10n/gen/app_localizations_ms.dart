// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appName => 'PeekWallet';

  @override
  String get lockScreenSubtitle => 'Masukkan kata laluan untuk membuka kunci';

  @override
  String get lockPasswordHint => 'Kata laluan';

  @override
  String get lockUnlock => 'Buka';

  @override
  String get lockUseBiometric => 'Guna biometrik';

  @override
  String get lockTooManyAttempts => 'Terlalu banyak percubaan gagal';

  @override
  String get lockTimerWarning =>
      'Mengunci telefon atau memulakan semula aplikasi tidak akan menetapkan semula pemasa — ini disengajakan.';

  @override
  String get homeTotalBalance => 'Jumlah baki';

  @override
  String homeSyncedCount(int counted, int total) {
    return '$counted / $total disegerakkan';
  }

  @override
  String homeAcrossWallets(int count) {
    return 'merentas $count dompet';
  }

  @override
  String get homeEmptyTitle => 'Tiada dompet lagi';

  @override
  String get homeEmptyBody =>
      'Cipta dompet baharu atau pulihkan daripada frasa pemulihan untuk bermula.';

  @override
  String get homeAddWallet => 'Tambah dompet';

  @override
  String get actionReceive => 'Terima';

  @override
  String get actionSend => 'Hantar';

  @override
  String get actionBack => 'Kembali';

  @override
  String get actionCopy => 'Salin';

  @override
  String get actionShare => 'Kongsi';

  @override
  String get actionExplorer => 'Penjelajah';

  @override
  String get actionSending => 'Menghantar…';

  @override
  String receiveTitle(String coinId) {
    return 'Terima $coinId';
  }

  @override
  String get receiveAddressLabel => 'ALAMAT ANDA';

  @override
  String get receiveAddressCopied => 'Alamat disalin';

  @override
  String balanceCached(String ago) {
    return 'Cache · $ago lalu';
  }

  @override
  String get txDirectionIncoming => 'Masuk';

  @override
  String get txDirectionOutgoing => 'Keluar';

  @override
  String get txStatusConfirmed => 'Disahkan';

  @override
  String get txStatusPending => 'Belum selesai';

  @override
  String get txStatusFailed => 'Gagal';

  @override
  String get txStatusInMempool => 'Dalam mempool';

  @override
  String get txCopiedToClipboard => 'Disalin ke papan keratan';
}
