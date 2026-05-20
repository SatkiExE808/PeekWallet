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
  String sendScreenTitle(String coinName) {
    return 'Kirim $coinName';
  }

  @override
  String sendScanTitle(String symbol) {
    return 'Pindai alamat $symbol';
  }

  @override
  String sendBtcAmountLabel(String symbol) {
    return 'Jumlah ($symbol atau sat)';
  }

  @override
  String sendBroadcastSuccess(String prefix) {
    return 'Dikirim! txid: $prefix…';
  }

  @override
  String get sendBtcLoadingUtxos => 'Memuat UTXO…';

  @override
  String sendBtcUtxoError(String error) {
    return 'Galat UTXO: $error';
  }

  @override
  String get sendBtcAvailableHint => 'tersedia · hanya UTXO terkonfirmasi';

  @override
  String sendBtcFeeRatesError(String error) {
    return 'Tarif biaya tidak tersedia: $error';
  }

  @override
  String get sendBtcLoadingFeeRates => 'Memuat tarif biaya…';

  @override
  String get sendBtcFinalFeeHint =>
      'Biaya akhir + kembalian akan ditampilkan setelah dikirim. Setelah dikirim ke jaringan, TIDAK bisa dibatalkan.';

  @override
  String get sendBtcExperimentalBody =>
      'Pengiriman telah diuji vector spec BIP-0143 tapi belum diaudit menyeluruh.';

  @override
  String sendBtcOnlyBech32(String prefix) {
    return 'Hanya alamat bech32 P2WPKH ($prefix…) yang didukung';
  }

  @override
  String sendBtcExceedsBalance(int available) {
    return 'Jumlah melebihi saldo terkonfirmasi ($available sat)';
  }

  @override
  String get sendBtcFeeRateLabel => 'Tarif biaya';

  @override
  String get sendBtcFeeTierFastest => 'Tercepat';

  @override
  String get sendBtcFeeTierHalfHour => 'Setengah jam';

  @override
  String get sendBtcFeeTierHour => 'Satu jam';

  @override
  String get sendBtcFeeTierEconomy => 'Ekonomi';

  @override
  String get sendBtcFeeEtaFastest => '~10 mnt';

  @override
  String get sendBtcFeeEtaHalfHour => '~30 mnt';

  @override
  String get sendBtcFeeEtaHour => '~1 jam';

  @override
  String get sendBtcFeeEtaEconomy => 'Saat mempool memungkinkan';

  @override
  String get sendBchRecipientLabel => 'Alamat penerima (CashAddr)';

  @override
  String get sendBchExperimentalBody =>
      'P2PKH lawas dengan SIGHASH_FORKID. Sighash BIP143 telah diuji vector spec via BTC SegWit; byte sighash 0x41 spesifik BCH + envelope tx lawas telah diuji unit tapi belum diaudit.';

  @override
  String get sendBchErrorMustBeCashAddr =>
      'Penerima harus CashAddr (bitcoincash:q…/p… atau q…/p… saja)';

  @override
  String get sendBchErrorP2shNotSupported =>
      'Alamat BCH P2SH (p…) belum didukung — hanya P2KH (q…) di build ini.';

  @override
  String get sendBchFinalFeeHint =>
      'BCH P2PKH lawas dengan SIGHASH_FORKID. Setelah dikirim TIDAK bisa dibatalkan (BCH tidak mendukung RBF).';

  @override
  String get sendBchAvailableShort => 'tersedia';

  @override
  String get sendBchNetworkFeeLabel => 'Biaya jaringan';

  @override
  String sendBchFeeRateDescription(int rate, int typical) {
    return '$rate sat/byte — biasanya tx 1-input ≈ $typical sat. Biaya BCH sangat rendah.';
  }

  @override
  String get sendBchAmountLabel => 'Jumlah (BCH atau sat)';

  @override
  String get sendEthExperimentalBody =>
      'RLP + sighash EIP-1559 + pemulihan ECDSA telah diuji unit tapi alur kirim ujung-ke-ujung belum diaudit.';

  @override
  String get sendEthErrorBadAddress =>
      'Penerima harus alamat 0x + 40 karakter heksadesimal';

  @override
  String sendEthErrorExceedsToken(String symbol) {
    return 'Jumlah melebihi saldo $symbol';
  }

  @override
  String sendEthErrorNoGas(String symbol) {
    return 'Tidak ada $symbol untuk gas — danai dompet ini dulu';
  }

  @override
  String sendEthAmountLabelToken(String symbol) {
    return 'Jumlah ($symbol atau unit dasar)';
  }

  @override
  String sendEthAmountLabelNative(String symbol) {
    return 'Jumlah ($symbol atau wei)';
  }

  @override
  String get sendEthMaxFeeLabel => 'Biaya maks per gas';

  @override
  String get sendEthPriorityFeeLabel => 'Biaya prioritas';

  @override
  String get sendEthLoadingBalance => 'Memuat saldo…';

  @override
  String sendEthBalanceError(String error) {
    return 'Galat saldo: $error';
  }

  @override
  String sendEthAvailableForGas(String amount, String symbol) {
    return 'tersedia · $amount $symbol untuk gas';
  }

  @override
  String sendEthFeeError(String error) {
    return 'Data biaya tidak tersedia: $error';
  }

  @override
  String get sendEthLoadingFee => 'Memuat tarif biaya…';

  @override
  String get sendEthNetworkFeeHeader => 'BIAYA JARINGAN';

  @override
  String get sendEthAutoBadge => 'OTOMATIS';

  @override
  String get sendEthBaseLabel => 'Dasar';

  @override
  String get sendEthTipLabel => 'Tip';

  @override
  String get sendEthMaxLabel => 'Maks';

  @override
  String get sendEthFinalFeeHint =>
      'Biaya akhir bergantung pada biaya dasar jaringan saat dimasukkan. Apa pun di bawah maks akan dikembalikan — bayar lebih tidak benar-benar berbiaya. Setelah dikirim TIDAK bisa dibatalkan.';

  @override
  String get sendSolExperimentalBody =>
      'Encoding transaksi Solana telah diuji unit tapi alur kirim ujung-ke-ujung belum diaudit.';

  @override
  String get sendSolErrorBadAddress => 'Alamat harus 32-44 karakter base58';

  @override
  String get sendSolErrorNoSol =>
      'Tidak ada SOL untuk biaya — danai dompet ini dengan sedikit SOL dulu';

  @override
  String sendSolErrorNeedsAtaSol(String symbol) {
    return 'Penerima tidak punya akun $symbol — pengiriman akan membuat satu (butuh ~0.00204 SOL sewa + biaya).';
  }

  @override
  String get sendSolErrorNotEnoughSol =>
      'SOL tidak cukup untuk biaya jaringan.';

  @override
  String get sendSolErrorAmountFeeExceeds => 'Jumlah + biaya melebihi saldo';

  @override
  String sendSolAmountLabelToken(String symbol) {
    return 'Jumlah ($symbol atau unit dasar)';
  }

  @override
  String get sendSolAmountLabelNative => 'Jumlah (SOL atau lamport)';

  @override
  String get sendSolAddressHint => 'Alamat Solana';

  @override
  String get sendSolNetworkFeeLabel => 'Biaya jaringan';

  @override
  String get sendSolAtaRentLabel => 'Sewa ATA';

  @override
  String get sendSolTotalOutLabel => 'Total SOL keluar';

  @override
  String get sendSolFinalFeeHintNative =>
      'Biaya Solana tetap 5000 lamport per tanda tangan. Setelah dikirim TIDAK bisa dibatalkan.';

  @override
  String sendSolFinalFeeHintNewAta(String symbol) {
    return 'Penerima belum punya akun $symbol. Mengirim membuat satu untuk mereka (~0.00204 SOL sewa, dibayar Anda). Setelah dikirim TIDAK bisa dibatalkan.';
  }

  @override
  String get sendTrxExperimentalBody =>
      'Tx Tron dibangun oleh RPC dan ditandatangani lokal. Hash txid diverifikasi sebelum ditandatangani, tapi kami tidak mendekode badan protobuf.';

  @override
  String get sendTrxErrorBadAddress =>
      'Penerima harus alamat base58 Tron (mulai dengan T, 34 karakter)';

  @override
  String get sendTrxErrorNoTrx =>
      'Tidak ada TRX untuk bandwidth/energi — danai dompet ini dengan TRX dulu';

  @override
  String get sendTrxRecipientLabel => 'Penerima (Tron base58)';

  @override
  String sendTrxAmountLabelToken(String symbol) {
    return 'Jumlah ($symbol atau unit dasar)';
  }

  @override
  String get sendTrxAmountLabelNative => 'Jumlah (TRX atau sun)';

  @override
  String get sendTrxBandwidthLabel => 'Bandwidth/energi';

  @override
  String get sendTrxBandwidthToken => 'Hingga ~30 TRX setara (TRC-20)';

  @override
  String get sendTrxBandwidthNative => 'Kuota gratis atau ~0.27 TRX';

  @override
  String get sendTrxFinalFeeHint =>
      'Transaksi Tron dibangun oleh node RPC; kami memverifikasi ulang hash txid sebelum menandatangani lokal. Setelah dikirim TIDAK bisa dibatalkan.';

  @override
  String get sendXmrTitle => 'Kirim XMR';

  @override
  String get sendXmrScanTitle => 'Pindai alamat penerima';

  @override
  String sendXmrAvailable(String amount) {
    return 'Tersedia: $amount XMR';
  }

  @override
  String get sendXmrAddRecipient => 'Tambah penerima';

  @override
  String get sendXmrSendAllTitle => 'Kirim semua';

  @override
  String get sendXmrSendAllBody =>
      'Sapu setiap output yang bisa dibelanjakan ke penerima pertama — biaya dikurangi otomatis.';

  @override
  String get sendXmrFeePriorityLabel => 'Prioritas biaya';

  @override
  String get sendXmrTierSlow => 'Lambat';

  @override
  String get sendXmrTierNormal => 'Normal';

  @override
  String get sendXmrTierFast => 'Cepat';

  @override
  String get sendXmrReviewAction => 'Tinjau pengiriman';

  @override
  String get sendXmrToLabel => 'Ke';

  @override
  String sendXmrToNumbered(int index) {
    return 'Ke #$index';
  }

  @override
  String get sendXmrSubtotalLabel => 'Subtotal';

  @override
  String get sendXmrSweepLabel => 'Mengirim (sapu)';

  @override
  String get sendXmrNetworkFee => 'Biaya jaringan';

  @override
  String sendXmrSplitWarning(int count) {
    return 'Pengiriman ini akan disiarkan sebagai $count sub-transaksi.';
  }

  @override
  String get sendXmrBroadcastTitle => 'Transaksi disiarkan';

  @override
  String get sendXmrBroadcastBody =>
      'Akan muncul di riwayat transaksi setelah dikonfirmasi jaringan.';

  @override
  String get sendXmrTxIdLabel => 'TX ID';

  @override
  String get sendXmrTxIdCopied => 'TX ID disalin';

  @override
  String get sendXmrCopyTxIdAction => 'Salin TX ID';

  @override
  String get sendXmrDoneAction => 'Selesai';

  @override
  String get sendXmrRecipientHeader => 'Penerima';

  @override
  String get sendXmrRemoveTooltip => 'Hapus';

  @override
  String get sendXmrAddressLabel => 'Alamat penerima';

  @override
  String get sendXmrAddressBookTooltip => 'Buku alamat';

  @override
  String get sendXmrPasteTooltip => 'Tempel';

  @override
  String get sendXmrAmountLabel => 'Jumlah (XMR)';

  @override
  String get sendXmrAmountHintSweep => 'Sapu — jumlah otomatis';

  @override
  String sendXmrErrorBadAddress(String tag) {
    return 'Alamat tidak terlihat seperti Monero$tag.';
  }

  @override
  String sendXmrErrorAmountZero(String tag) {
    return 'Jumlah harus lebih besar dari 0$tag.';
  }

  @override
  String get sendXmrErrorExceedsBalance => 'Total melebihi saldo Anda.';

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
