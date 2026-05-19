// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'PeekWallet';

  @override
  String get lockScreenSubtitle => 'Masukkan kata sandi untuk membuka';

  @override
  String get lockPasswordHint => 'Kata sandi';

  @override
  String get lockUnlock => 'Buka';

  @override
  String get lockUseBiometric => 'Gunakan biometrik';

  @override
  String get lockTooManyAttempts => 'Terlalu banyak percobaan gagal';

  @override
  String get lockTimerWarning =>
      'Mengunci ponsel atau memulai ulang aplikasi tidak akan mengatur ulang pengatur waktu — ini disengaja.';

  @override
  String get homeTotalBalance => 'Total saldo';

  @override
  String homeSyncedCount(int counted, int total) {
    return '$counted / $total tersinkron';
  }

  @override
  String homeAcrossWallets(int count) {
    return 'di $count dompet';
  }

  @override
  String get homeEmptyTitle => 'Belum ada dompet';

  @override
  String get homeEmptyBody =>
      'Buat dompet baru atau pulihkan dari frasa pemulihan untuk memulai.';

  @override
  String get homeAddWallet => 'Tambah dompet';

  @override
  String get actionReceive => 'Terima';

  @override
  String get actionSend => 'Kirim';

  @override
  String get actionBack => 'Kembali';

  @override
  String get actionCopy => 'Salin';

  @override
  String get actionShare => 'Bagikan';

  @override
  String get actionExplorer => 'Jelajahi';

  @override
  String get actionSending => 'Mengirim…';

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
  String get txStatusConfirmed => 'Terkonfirmasi';

  @override
  String get txStatusPending => 'Tertunda';

  @override
  String get txStatusFailed => 'Gagal';

  @override
  String get txStatusInMempool => 'Di mempool';

  @override
  String get txCopiedToClipboard => 'Disalin ke papan klip';
}
