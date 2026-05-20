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
  String get walletsTitle => 'Dompet Saya';

  @override
  String get walletsRefreshTooltip => 'Muat semula baki';

  @override
  String get walletsAddTooltip => 'Tambah dompet';

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
  String get actionContinue => 'Teruskan';

  @override
  String get actionCancel => 'Batal';

  @override
  String get actionSave => 'Simpan';

  @override
  String get actionDelete => 'Padam';

  @override
  String get actionRefresh => 'Muat semula';

  @override
  String receiveTitle(String coinId) {
    return 'Terima $coinId';
  }

  @override
  String get receiveAddressLabel => 'ALAMAT ANDA';

  @override
  String get receiveAddressCopied => 'Alamat disalin';

  @override
  String get receiveCopiedToClipboard => 'Disalin ke papan keratan';

  @override
  String get receiveCouldNotOpenBrowser => 'Tidak dapat buka pelayar';

  @override
  String coinScreenBalanceLabel(String symbol) {
    return 'Baki $symbol';
  }

  @override
  String get coinScreenActivityTitle => 'Aktiviti';

  @override
  String get coinScreenTokensTitle => 'Token';

  @override
  String get coinScreenNoTxYet => 'Tiada transaksi lagi';

  @override
  String coinScreenShareAddressHint(String symbol) {
    return 'Kongsi alamat anda untuk menerima $symbol';
  }

  @override
  String get coinScreenLoading => 'Memuatkan…';

  @override
  String get coinScreenRefreshTooltip => 'Muat semula';

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
    return 'Tidak dapat buka dompet: $error';
  }

  @override
  String get balanceVaultLocked => 'Bilik kebal berkunci.';

  @override
  String get ageJustNow => 'baru sahaja';

  @override
  String ageMinutes(int n) {
    return '$n min';
  }

  @override
  String ageHours(int n) {
    return '$n jam';
  }

  @override
  String ageDays(int n) {
    return '$n hari';
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

  @override
  String get txIdLabel => 'ID Transaksi';

  @override
  String get txHashLabel => 'Cincang';

  @override
  String get txSignatureLabel => 'Tandatangan';

  @override
  String get txAmountLabel => 'Jumlah bersih';

  @override
  String get txFeeLabel => 'Yuran';

  @override
  String get txGasFeeLabel => 'Yuran gas';

  @override
  String get txNetworkFeeLabel => 'Yuran rangkaian';

  @override
  String get txBlockHeightLabel => 'Tinggi blok';

  @override
  String get txSlotLabel => 'Slot';

  @override
  String get txDateLabel => 'Tarikh';

  @override
  String get txTokenLabel => 'Token';

  @override
  String get txCounterpartyLabel => 'Pihak lawan';

  @override
  String get sendFormRecipientLabel => 'Alamat penerima';

  @override
  String get sendFormAmountLabel => 'Jumlah';

  @override
  String get sendFormMaxButton => 'Maks';

  @override
  String get sendFormBookTooltip => 'Dari buku alamat';

  @override
  String get sendFormScanTooltip => 'Imbas QR';

  @override
  String get sendFormPasteTooltip => 'Tampal dari papan keratan';

  @override
  String get sendFormFeePriorityLabel => 'KEUTAMAAN YURAN';

  @override
  String get sendFormAvailableLabel => 'tersedia';

  @override
  String get sendFormConfirmHint => 'Taip SEND untuk sahkan';

  @override
  String get sendFormConfirmPlaceholder => 'SEND';

  @override
  String get sendFormErrorInvalidAmount => 'Masukkan jumlah yang sah';

  @override
  String get sendFormErrorAmountExceedsBalance =>
      'Jumlah + yuran melebihi baki';

  @override
  String get sendFormErrorRecipientRequired => 'Alamat penerima diperlukan';

  @override
  String get sendFormWillBeSentTo => 'akan dihantar ke';

  @override
  String get sendFormToLabel => 'Kepada';

  @override
  String get tronTokensTitle => 'Token (TRC-20)';

  @override
  String get splTokensTitle => 'Token (SPL)';

  @override
  String get erc20TokensTitle => 'Token';

  @override
  String experimentalSendWarning(String symbol) {
    return 'Penghantaran masih eksperimen — uji dengan jumlah kecil sebelum menghantar $symbol yang besar.';
  }

  @override
  String get erc20EmptyHint =>
      'Belum ada token — terima USDT/USDC/DAI ke alamat ini atau ketik \"Tambah token\" untuk menjejaki ERC-20 lain melalui alamat kontrak.';

  @override
  String get ercAddCustomTitle => 'Tambah token ERC-20 tersuai';

  @override
  String get ercAddCustomBody =>
      'Tampal alamat kontrak token. Kami akan dapatkan simbol dan perpuluhan dari rantaian.';

  @override
  String get ercContractLabel => 'Alamat kontrak';

  @override
  String get ercProbeAction => 'Siasat';

  @override
  String get ercContractError => 'Kontrak mesti 0x + 40 aksara heksadesimal';

  @override
  String ercProbingMsg(String prefix) {
    return 'Menyiasat $prefix…';
  }

  @override
  String get ercProbeFailedMsg =>
      'Tidak dapat baca metadata token — rantaian salah atau bukan ERC-20?';

  @override
  String ercAddedMsg(String symbol, int decimals) {
    return 'Ditambah $symbol ($decimals perpuluhan)';
  }
}
