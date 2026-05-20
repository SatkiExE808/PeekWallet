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
  String get walletsTitle => 'Dompet Saya';

  @override
  String get walletsRefreshTooltip => 'Segarkan saldo';

  @override
  String get walletsAddTooltip => 'Tambah dompet';

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
  String get actionContinue => 'Lanjutkan';

  @override
  String get actionCancel => 'Batal';

  @override
  String get actionSave => 'Simpan';

  @override
  String get actionDelete => 'Hapus';

  @override
  String get actionRefresh => 'Segarkan';

  @override
  String receiveTitle(String coinId) {
    return 'Terima $coinId';
  }

  @override
  String get receiveAddressLabel => 'ALAMAT ANDA';

  @override
  String get receiveAddressCopied => 'Alamat disalin';

  @override
  String get receiveCopiedToClipboard => 'Disalin ke papan klip';

  @override
  String get receiveCouldNotOpenBrowser => 'Tidak bisa membuka peramban';

  @override
  String coinScreenBalanceLabel(String symbol) {
    return 'Saldo $symbol';
  }

  @override
  String get coinScreenActivityTitle => 'Aktivitas';

  @override
  String get coinScreenTokensTitle => 'Token';

  @override
  String get coinScreenNoTxYet => 'Belum ada transaksi';

  @override
  String coinScreenShareAddressHint(String symbol) {
    return 'Bagikan alamat untuk menerima $symbol';
  }

  @override
  String get coinScreenLoading => 'Memuat…';

  @override
  String get coinScreenRefreshTooltip => 'Segarkan';

  @override
  String get coinScreenAddTokenLabel => 'Tambah token';

  @override
  String balanceCached(String ago) {
    return 'Cache · $ago lalu';
  }

  @override
  String balanceCachedShort(String ago) {
    return 'Cache · $ago';
  }

  @override
  String balanceCouldNotOpen(String error) {
    return 'Tidak bisa membuka dompet: $error';
  }

  @override
  String get balanceVaultLocked => 'Brankas terkunci.';

  @override
  String get ageJustNow => 'baru saja';

  @override
  String ageMinutes(int n) {
    return '$n mnt';
  }

  @override
  String ageHours(int n) {
    return '$n jam';
  }

  @override
  String ageDays(int n) {
    return '$n hr';
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

  @override
  String get txIdLabel => 'ID Transaksi';

  @override
  String get txHashLabel => 'Hash';

  @override
  String get txSignatureLabel => 'Tanda tangan';

  @override
  String get txAmountLabel => 'Jumlah bersih';

  @override
  String get txFeeLabel => 'Biaya';

  @override
  String get txGasFeeLabel => 'Biaya gas';

  @override
  String get txNetworkFeeLabel => 'Biaya jaringan';

  @override
  String get txBlockHeightLabel => 'Tinggi blok';

  @override
  String get txSlotLabel => 'Slot';

  @override
  String get txDateLabel => 'Tanggal';

  @override
  String get txTokenLabel => 'Token';

  @override
  String get txCounterpartyLabel => 'Lawan transaksi';

  @override
  String get sendFormRecipientLabel => 'Alamat penerima';

  @override
  String get sendFormAmountLabel => 'Jumlah';

  @override
  String get sendFormMaxButton => 'Maks';

  @override
  String get sendFormBookTooltip => 'Dari buku alamat';

  @override
  String get sendFormScanTooltip => 'Pindai QR';

  @override
  String get sendFormPasteTooltip => 'Tempel dari papan klip';

  @override
  String get sendFormFeePriorityLabel => 'PRIORITAS BIAYA';

  @override
  String get sendFormAvailableLabel => 'tersedia';

  @override
  String get sendFormConfirmHint => 'Ketik SEND untuk konfirmasi';

  @override
  String get sendFormConfirmPlaceholder => 'SEND';

  @override
  String get sendFormErrorInvalidAmount => 'Masukkan jumlah yang valid';

  @override
  String get sendFormErrorAmountExceedsBalance =>
      'Jumlah + biaya melebihi saldo';

  @override
  String get sendFormErrorRecipientRequired => 'Alamat penerima wajib';

  @override
  String get sendFormWillBeSentTo => 'akan dikirim ke';

  @override
  String get sendFormToLabel => 'Ke';

  @override
  String get tronTokensTitle => 'Token (TRC-20)';

  @override
  String get splTokensTitle => 'Token (SPL)';

  @override
  String get erc20TokensTitle => 'Token';

  @override
  String experimentalSendWarning(String symbol) {
    return 'Pengiriman masih eksperimental — uji dengan jumlah kecil sebelum mengirim $symbol dalam jumlah besar.';
  }

  @override
  String get erc20EmptyHint =>
      'Belum ada token — terima USDT/USDC/DAI ke alamat ini atau ketuk \"Tambah token\" untuk melacak ERC-20 lain via alamat kontrak.';

  @override
  String get ercAddCustomTitle => 'Tambah token ERC-20 kustom';

  @override
  String get ercAddCustomBody =>
      'Tempel alamat kontrak token. Kami akan ambil simbol dan desimal dari rantai.';

  @override
  String get ercContractLabel => 'Alamat kontrak';

  @override
  String get ercProbeAction => 'Probe';

  @override
  String get ercContractError => 'Kontrak harus 0x + 40 karakter heksadesimal';

  @override
  String ercProbingMsg(String prefix) {
    return 'Memprobe $prefix…';
  }

  @override
  String get ercProbeFailedMsg =>
      'Tidak bisa baca metadata token — rantai salah atau bukan ERC-20?';

  @override
  String ercAddedMsg(String symbol, int decimals) {
    return 'Ditambahkan $symbol ($decimals desimal)';
  }
}
