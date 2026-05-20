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
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsMoneroNode => 'Node Monero';

  @override
  String get settingsMoneroNodeBody =>
      'Daemon Monero yang PeekWallet sambungkan untuk sinkronisasi. Default adalah node publik Cake Wallet. Untuk privasi penuh, jalankan monerod sendiri dan arahkan ke sini.';

  @override
  String get settingsDaemonUrlLabel => 'URL Daemon';

  @override
  String get settingsPasteTooltip => 'Tempel';

  @override
  String settingsConnectsToPreview(String hostPort, String ssl) {
    return 'Tersambung ke $hostPort (ssl=$ssl)';
  }

  @override
  String get settingsMessageBadUrl =>
      'Tidak bisa menguraikan URL itu. Coba contoh https://node.example.com:18081';

  @override
  String get settingsMessageSaved =>
      'Tersimpan. Kunci + buka kunci aplikasi untuk beralih ke node baru.';

  @override
  String settingsMessageReset(String url) {
    return 'Direset. Aplikasi akan memakai $url pada buka kunci berikutnya.';
  }

  @override
  String get settingsResetToDefault => 'Reset ke default';

  @override
  String get settingsSectionPublicNodes => 'Node publik';

  @override
  String get settingsSectionSecurity => 'Keamanan';

  @override
  String get settingsSectionDisplay => 'Tampilan';

  @override
  String get settingsBiometricUnlock => 'Buka kunci biometrik';

  @override
  String get settingsBiometricUnlockOn =>
      'Gunakan sidik jari / wajah untuk membuka kunci';

  @override
  String get settingsBiometricUnlockOff =>
      'Tidak tersedia — belum ada biometrik terdaftar';

  @override
  String get settingsBiometricEnableTitle => 'Aktifkan buka kunci biometrik';

  @override
  String get settingsBiometricEnableHint =>
      'Masukkan kata sandi aplikasi untuk konfirmasi';

  @override
  String settingsBiometricEnableFailed(String error) {
    return 'Tidak bisa diaktifkan: $error';
  }

  @override
  String get settingsPasswordLabel => 'Kata sandi';

  @override
  String get settingsRevealSeedTitle => 'Tampilkan frasa pemulihan';

  @override
  String get settingsRevealSeedBody =>
      'Lihat seed BIP39 + kunci belanja/lihat Monero';

  @override
  String get settingsAddressBookTitle => 'Buku alamat';

  @override
  String get settingsAddressBookBody =>
      'Label tersimpan untuk penerima yang Anda kirim';

  @override
  String get settingsAutoLockTitle => 'Kunci otomatis';

  @override
  String get settingsAutoLockSheetTitle => 'Kunci otomatis setelah masuk latar';

  @override
  String get settingsAutoLockSheetBody =>
      'Berapa lama PeekWallet bisa tetap terbuka saat Anda memakai aplikasi lain. Kembali dalam waktu ini tetap masuk; lebih lama harus masukkan kata sandi lagi.';

  @override
  String get settingsAutoLockImmediately => 'Langsung';

  @override
  String get settingsAutoLockNever => 'Tidak pernah';

  @override
  String settingsAutoLockSeconds(int n) {
    return '$n dtk';
  }

  @override
  String get settingsAutoLock30Seconds => '30 detik';

  @override
  String get settingsAutoLock1Minute => '1 menit';

  @override
  String get settingsAutoLock2MinutesDefault => '2 menit (default)';

  @override
  String get settingsAutoLock5Minutes => '5 menit';

  @override
  String get settingsAutoLock15Minutes => '15 menit';

  @override
  String get settingsAutoLock1Hour => '1 jam';

  @override
  String get settingsLockAppTitle => 'Kunci aplikasi';

  @override
  String get settingsLockAppBody =>
      'Hapus seed di memori dan minta kata sandi lagi';

  @override
  String get settingsLockConfirmTitle => 'Kunci aplikasi?';

  @override
  String get settingsLockConfirmBody =>
      'Anda perlu memasukkan kata sandi untuk membuka kunci. Sinkronisasi Monero yang sedang berjalan akan melanjut dari posisi terakhir.';

  @override
  String get settingsLockConfirmAction => 'Kunci';

  @override
  String get settingsDisplayCurrencyTitle => 'Mata uang tampilan';

  @override
  String get settingsDisplayCurrencyDisabled => 'Dinonaktifkan';

  @override
  String get settingsShowFiatValues => 'Tampilkan nilai fiat';

  @override
  String get settingsShowFiatValuesBody =>
      'Polling CoinGecko setiap 5 menit. Tidak mengirim PII.';

  @override
  String get settingsExportLogsTitle => 'Ekspor log';

  @override
  String get settingsExportLogsBody =>
      '7 hari terakhir. Alamat dan kunci diredaksi otomatis.';

  @override
  String get settingsExportLogsEmpty => 'Belum ada log untuk diekspor.';

  @override
  String get settingsExportLogsDialogTitle => 'Log (7 hari terakhir)';

  @override
  String get settingsExportLogsCopied => 'Log disalin ke papan klip';

  @override
  String get settingsCloseAction => 'Tutup';

  @override
  String get settingsRestoreAllTitle => 'Pulihkan semua koin dari seed brankas';

  @override
  String get settingsRestoreAllBody =>
      'Satu ketuk untuk menurunkan dompet bagi setiap koin dari seed 12/24-kata Anda.';

  @override
  String get settingsCustomRpcTitle => 'Endpoint RPC kustom';

  @override
  String get settingsCustomRpcBody =>
      'Arahkan BTC/LTC/BCH/ETH/POL/SOL/TRX ke node Anda sendiri.';

  @override
  String get settingsUpdateTitle => 'Periksa pembaruan';

  @override
  String get settingsUpdateChecking => 'Memeriksa GitHub…';

  @override
  String get settingsUpdateTapToCheck => 'Ketuk untuk memeriksa';

  @override
  String get settingsUpdateFailedFallback => 'Pemeriksaan gagal';

  @override
  String settingsUpdateAvailable(String ago) {
    return 'Pembaruan tersedia — dirilis $ago. Ketuk untuk unduh.';
  }

  @override
  String get settingsUpdateDebugBuild =>
      'Build debug — pemeriksaan versi dimatikan. Ketuk untuk coba lagi.';

  @override
  String get settingsUpdateUpToDate => 'Sudah terbaru · baru saja diperiksa';

  @override
  String get settingsAboutTitle => 'Tentang PeekWallet';

  @override
  String get settingsAboutBody => 'Versi, lisensi, kode sumber';

  @override
  String get addWalletChooseCoin => 'Pilih koin';

  @override
  String addWalletTitle(String coin) {
    return 'Tambah dompet $coin';
  }

  @override
  String get addWalletCreateTitle => 'Buat dompet baru';

  @override
  String get addWalletCreateBody =>
      'Buat frasa seed baru. Siapa pun dengan frasa itu bisa menggunakan dompet — tulis di atas kertas.';

  @override
  String get addWalletRestoreSeedTitle => 'Pulihkan dari seed';

  @override
  String get addWalletRestoreSeedBody =>
      'Gunakan frasa pemulihan yang Anda miliki (BIP39 12/24 kata, seed Monero 25-kata, atau Polyseed 14 kata).';

  @override
  String get addWalletRestoreKeysTitle => 'Pulihkan dari kunci';

  @override
  String get addWalletRestoreKeysBody =>
      'Alamat + kunci belanja pribadi + kunci lihat pribadi. Gunakan ketika punya kunci tapi tidak punya frasa seed.';

  @override
  String get addWalletFormatNew => 'Format seed baru';

  @override
  String get addWalletFormatRestore => 'Format pemulihan';

  @override
  String get addWalletFormatBip39Hint =>
      'Mnemonik BIP39 — format standar 12/24 kata yang digunakan setiap dompet modern. Trezor, Ledger. Universal antar banyak koin.';

  @override
  String get addWalletFormatMoneroLegacyHint =>
      'Seed asli Monero gaya electrum. Interop langsung dengan Cake, Feather, dan Monero GUI.';

  @override
  String get addWalletFormatPolyseedHint =>
      'Standar Monero baru — 14 kata. Restore height sudah disertakan.';

  @override
  String get addWalletFormatKeysOnlyHint =>
      'Kunci belanja + kunci lihat + alamat. Tidak ada kata.';

  @override
  String get addWalletVaultLocked =>
      'Brankas terkunci — buka kunci lagi dan coba.';

  @override
  String addWalletGenerateHeader(String format) {
    return 'Buat $format';
  }

  @override
  String get addWalletGenerateBody =>
      'Saat Anda ketuk Buat, kata akan muncul sekali. Tulis di kertas sebelum lanjut. Siapa pun dengan kata-kata ini bisa menguras dompet ini.';

  @override
  String get addWalletGenerateAction => 'Buat seed';

  @override
  String get addWalletWriteThisDown => 'Tulis ini';

  @override
  String get addWalletWordsWarning =>
      'Kata-kata ini ADALAH dompet. Siapa pun dengannya bisa menggunakannya.';

  @override
  String get addWalletCopyClipboardClears =>
      'Disalin — papan klip otomatis kosong dalam 30 d';

  @override
  String get addWalletCopyPhraseAction => 'Salin frasa';

  @override
  String get addWalletNameLabel => 'Nama dompet (hanya Anda yang lihat)';

  @override
  String get addWalletNameHint => 'mis. \"Monero Utama\"';

  @override
  String get addWalletSavedConfirm =>
      'Saya sudah simpan kata-kata — tambah dompet';

  @override
  String addWalletRestoreTitle(String format) {
    return 'Pulihkan $format';
  }

  @override
  String get addWalletRestoreNameLabel => 'Nama dompet';

  @override
  String get addWalletRestoreNameHint => 'mis. \"Diimpor dari Cake\"';

  @override
  String get addWalletRecoveryPhraseLabel => 'Frasa pemulihan';

  @override
  String get addWalletSeedWordsLabel => 'Kata seed';

  @override
  String get addWalletPassphraseLabel =>
      'Passphrase BIP39 (kata ke-25) — opsional';

  @override
  String get addWalletPassphraseHint => 'Biarkan kosong jika tidak dipakai';

  @override
  String get addWalletPassphraseWarning =>
      'Jika dompet sumber punya passphrase, Anda HARUS memasukkannya — kalau tidak, akan dapat dompet berbeda sama sekali.';

  @override
  String get addWalletSeedOffsetLabel => 'Seed offset — opsional';

  @override
  String get addWalletSeedOffsetHint =>
      'Biarkan kosong jika seed tidak dienkripsi';

  @override
  String get addWalletRestoreHeightLabel => 'Restore height — opsional';

  @override
  String get addWalletRestoreHeightHint => 'Nomor blok mulai memindai';

  @override
  String get addWalletRestoreHeightBody =>
      'Lebih rendah = lebih menyeluruh tapi sinkron lambat; lebih tinggi = lebih cepat tapi mungkin lewat tanda terima lama.';

  @override
  String get addWalletRestoreAction => 'Pulihkan dompet';

  @override
  String get addWalletKeysRestoreTitle => 'Pulihkan dari kunci';

  @override
  String get addWalletPrimaryAddressLabel => 'Alamat utama';

  @override
  String get addWalletSpendKeyLabel => 'Kunci belanja pribadi (hex)';

  @override
  String get addWalletViewKeyLabel => 'Kunci lihat pribadi (hex)';

  @override
  String get addWalletKeysRestoreHeightLabel => 'Restore height';

  @override
  String get addWalletKeysRestoreHeightHint =>
      'Nomor blok — lebih awal mencakup tanda terima lebih lama';

  @override
  String get addWalletScanAddressTitle => 'Pindai alamat';

  @override
  String get addWalletConfirmPasswordTitle => 'Konfirmasi kata sandi';

  @override
  String get addWalletAppPasswordLabel => 'Kata sandi aplikasi';

  @override
  String lockTryAgainIn(String duration) {
    return 'Coba lagi dalam $duration.';
  }

  @override
  String get welcomeTagline =>
      'Dompet self-custody untuk BTC, ETH, XMR, dan lainnya.';

  @override
  String get welcomeCreateAction => 'Buat dompet baru';

  @override
  String get welcomeImportAction => 'Saya sudah punya frasa pemulihan';

  @override
  String get welcomeBackupWarning =>
      'Frasa pemulihan 12-kata Anda adalah satu-satunya cadangan. Siapa pun dengannya bisa mengambil dana Anda.';

  @override
  String get welcomeDisclaimerAction => 'Baca penafian tanpa jaminan';

  @override
  String get welcomeDisclaimerTitle => 'Penafian';

  @override
  String get welcomeCopiedToast => 'Disalin';

  @override
  String get welcomeCopyTextAction => 'Salin teks';

  @override
  String get welcomeIUnderstandAction => 'Saya mengerti';

  @override
  String get revealSeedTitle => 'Tampilkan frasa pemulihan';

  @override
  String get revealSeedWarning =>
      'Anda akan menampilkan frasa seed dan kunci Monero. Siapa pun yang melihatnya bisa mengambil dana Anda — pastikan tidak ada yang melihat layar dan Anda tidak sedang berbagi layar.';

  @override
  String get revealSeedPasswordPrompt =>
      'Masukkan kata sandi aplikasi untuk lanjut.';

  @override
  String get revealSeedRevealAction => 'Tampilkan';

  @override
  String get revealSeedBip39Section => 'Frasa pemulihan BIP39';

  @override
  String get revealSeedPassphraseSection => 'Passphrase BIP39 (kata ke-25)';

  @override
  String get revealSeedXmrAddressSection => 'Alamat utama Monero';

  @override
  String get revealSeedXmrSpendSection => 'Kunci belanja pribadi Monero';

  @override
  String get revealSeedXmrViewSection => 'Kunci lihat pribadi Monero';

  @override
  String get revealSeedCopyPhrase => 'Salin frasa';

  @override
  String get revealSeedCopyPassphrase => 'Salin passphrase';

  @override
  String get revealSeedCopyAddress => 'Salin alamat';

  @override
  String get revealSeedCopySpendKey => 'Salin kunci belanja';

  @override
  String get revealSeedCopyViewKey => 'Salin kunci lihat';

  @override
  String get revealSeedRestoreHint =>
      'Anda bisa memulihkan dompet ini di Cake / Feather / Monero GUI dengan \"Pulihkan dari kunci\" memakai alamat + kunci lihat + kunci belanja di atas (atau \"Pulihkan dari seed\" dengan frasa BIP39 di dompet yang kompatibel BIP39).';

  @override
  String get revealSeedCopiedSensitive =>
      'Disalin — papan klip otomatis kosong dalam 30 d';

  @override
  String get revealSeedCopiedPlain => 'Disalin';

  @override
  String get aboutScreenTitle => 'Tentang';

  @override
  String aboutVersionLine(String version, String build) {
    return 'v$version (build $build)';
  }

  @override
  String get aboutAppVersion => 'Versi aplikasi';

  @override
  String get aboutBuildNumber => 'Nomor build';

  @override
  String get aboutPackage => 'Paket';

  @override
  String get aboutBuildSignature => 'Tanda tangan build';

  @override
  String get aboutSourceSection => 'Kode sumber';

  @override
  String get aboutLegalSection => 'Legal';

  @override
  String get aboutGithubRepo => 'Repository GitHub';

  @override
  String get aboutLicenseLink => 'Lisensi (GPL-3.0-or-later)';

  @override
  String get aboutDisclaimerLink => 'Penafian (tanpa jaminan)';

  @override
  String get aboutSecurityModelLink => 'Model keamanan';

  @override
  String get aboutFreeSoftwareBody =>
      'PeekWallet adalah perangkat lunak gratis dan open-source. Siapa pun bisa membaca sumber, build sendiri, dan memverifikasi biner di /releases sesuai kode publik (reproduktifitas dilacak di roadmap).';

  @override
  String get aboutUrlCopiedToast => 'URL disalin — buka di browser Anda';

  @override
  String get addressBookTitle => 'Buku alamat';

  @override
  String get addressBookPickerTitle => 'Pilih penerima';

  @override
  String get addressBookAddTooltip => 'Tambah entri';

  @override
  String get addressBookEmptyTitle => 'Belum ada alamat tersimpan';

  @override
  String get addressBookEmptyBodyPicker =>
      'Simpan penerima yang akan Anda kirim.';

  @override
  String get addressBookEmptyBody =>
      'Simpan alamat orang yang sering Anda kirim agar tidak perlu menempel tiap kali.';

  @override
  String get addressBookAddAction => 'Tambah entri';

  @override
  String get addressBookErrorLabelEmpty => 'Label tidak boleh kosong.';

  @override
  String get addressBookErrorAddressEmpty => 'Alamat tidak boleh kosong.';

  @override
  String get addressBookDeleteTitle => 'Hapus entri?';

  @override
  String get addressBookDeleteBody =>
      'Alamat tidak terpengaruh — hanya label / catatan tersimpan ini yang dihapus.';

  @override
  String get addressBookDeleteAction => 'Hapus';

  @override
  String get addressBookEditTitle => 'Sunting alamat';

  @override
  String get addressBookAddTitle => 'Tambah alamat';

  @override
  String get addressBookDeleteTooltip => 'Hapus';

  @override
  String get addressBookLabelField => 'Label';

  @override
  String get addressBookAddressField => 'Alamat';

  @override
  String get addressBookAddressLocked =>
      'Alamat tidak bisa diedit — hapus dan tambah ulang untuk mengubah.';

  @override
  String get addressBookScanTooltip => 'Pindai';

  @override
  String get addressBookPasteTooltip => 'Tempel';

  @override
  String get addressBookNotesField => 'Catatan (opsional)';

  @override
  String get addressBookNotesHint => 'Teks bebas — hanya disimpan lokal.';

  @override
  String get addressBookSaveChanges => 'Simpan perubahan';

  @override
  String get addressBookAddToBook => 'Tambah ke buku';

  @override
  String get qrScanTitle => 'Pindai QR';

  @override
  String get qrScanTorchTooltip => 'Senter';

  @override
  String qrScanCameraError(String code) {
    return 'Galat kamera: $code';
  }

  @override
  String get qrScanPermissionDenied => 'Izin kamera ditolak';

  @override
  String get qrScanPermissionBody =>
      'PeekWallet butuh akses kamera untuk memindai kode QR. Kamera hanya dipakai saat layar ini terbuka dan hanya membaca payload QR.';

  @override
  String get qrScanTryAgain => 'Coba lagi';

  @override
  String get qrScanOpenSettings => 'Buka pengaturan aplikasi';

  @override
  String get qrScanCenterHint => 'Tempatkan kode QR di tengah bingkai';

  @override
  String get rpcResetTitle => 'Reset semua override?';

  @override
  String get rpcResetBody =>
      'Setiap rantai akan kembali ke endpoint default publik. Anda bisa menambah override lagi kapan saja.';

  @override
  String get rpcResetAction => 'Reset';

  @override
  String get rpcScreenTitle => 'Endpoint RPC kustom';

  @override
  String get rpcResetAllTooltip => 'Reset semua';

  @override
  String get rpcIntroBody =>
      'Arahkan tiap rantai ke node Anda sendiri, bukan default publik. Bidang kosong tetap pakai default.';

  @override
  String rpcDefaultHint(String hint) {
    return 'Default: $hint';
  }

  @override
  String get rpcSaveAction => 'Simpan';

  @override
  String get rpcPrivacyNotesBody =>
      'Catatan privasi:\n• Default publik melihat alamat IP Anda dan alamat yang Anda kueri. Jalankan node sendiri atau proxy lewat VPN / LAN via Tailscale.\n• Endpoint RPC kustom langsung ke URL yang Anda masukkan — jaringan Anda melihat tujuan. Pilih provider yang Anda percaya.';

  @override
  String get restoreAllTitle => 'Pulihkan semua koin dari brankas';

  @override
  String get restoreAllIntro =>
      'Menambah dompet untuk setiap koin yang didukung, diturunkan dari seed brankas 12/24-kata yang sudah ada.';

  @override
  String get restoreAllNote =>
      'Dompet yang sudah ada dilewati (tidak duplikat). Monero dikecualikan — format seed-nya terpisah dan dipulihkan dari setup-nya sendiri.';

  @override
  String get restoreAllAction => 'Pulihkan semua dari seed brankas';

  @override
  String get restoreAllVaultLocked =>
      'Brankas terkunci. Buka kunci dan coba lagi.';

  @override
  String restoreAllHasWallet(String symbol) {
    return 'Sudah punya dompet $symbol — lewati';
  }

  @override
  String get restoreAllWillDerive => 'Akan diturunkan dari seed BIP39 brankas';

  @override
  String showSeedTitle(String name) {
    return 'Frasa pemulihan · $name';
  }

  @override
  String get showSeedPasswordPrompt =>
      'Masukkan kata sandi aplikasi untuk melihat frasa pemulihan dompet ini.';

  @override
  String get showSeedPasswordLabel => 'Kata sandi aplikasi';

  @override
  String get showSeedRevealAction => 'Tampilkan';

  @override
  String get showSeedRecoveryPhrase => 'Frasa pemulihan';

  @override
  String get showSeedCopyPhrase => 'Salin frasa';

  @override
  String get showSeedCopyClipboardClears =>
      'Disalin — papan klip otomatis kosong dalam 30d';

  @override
  String get showSeedPassphraseSection => 'Passphrase (kata ke-25)';

  @override
  String get showSeedSeedOffsetSection => 'Seed offset';

  @override
  String get showSeedAddressLabel => 'Alamat';

  @override
  String get showSeedViewKeyLabel => 'Kunci lihat';

  @override
  String get showSeedSpendKeyLabel => 'Kunci belanja';

  @override
  String get showSeedCopySpendKey => 'Salin kunci belanja';

  @override
  String showSeedStorageFooter(String format, String coin) {
    return 'Penyimpanan: $format. Koin: $coin.';
  }

  @override
  String get showSeedWriteDownWarning =>
      'Tulis di kertas dan simpan di tempat aman. Siapa pun dengan frasa ini punya kendali penuh dompet. Jangan tangkap layar — FLAG_SECURE memblokirnya.';

  @override
  String get showSeedKeysOnlyDisplay => 'Hanya kunci';

  @override
  String get walletMenuShowSeed => 'Tampilkan frasa pemulihan';

  @override
  String get walletMenuShowSeedBody => 'Cadangkan terpisah dari seed brankas.';

  @override
  String get walletMenuRename => 'Ganti nama';

  @override
  String get walletMenuRenameTitle => 'Ganti nama dompet';

  @override
  String walletMenuDeleteTitle(String name) {
    return 'Hapus $name?';
  }

  @override
  String get walletMenuDeleteBody =>
      'Dompet di rantai tidak terpengaruh — siapa pun dengan seed bisa memulihkannya lagi. Hanya catatan di perangkat ini yang dihapus.';

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
