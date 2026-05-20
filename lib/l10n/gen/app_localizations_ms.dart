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
  String sendScreenTitle(String coinName) {
    return 'Hantar $coinName';
  }

  @override
  String sendScanTitle(String symbol) {
    return 'Imbas alamat $symbol';
  }

  @override
  String sendBtcAmountLabel(String symbol) {
    return 'Jumlah ($symbol atau sat)';
  }

  @override
  String sendBroadcastSuccess(String prefix) {
    return 'Siaran selesai! txid: $prefix…';
  }

  @override
  String get sendBtcLoadingUtxos => 'Memuatkan UTXO…';

  @override
  String sendBtcUtxoError(String error) {
    return 'Ralat UTXO: $error';
  }

  @override
  String get sendBtcAvailableHint => 'tersedia · hanya UTXO disahkan';

  @override
  String sendBtcFeeRatesError(String error) {
    return 'Kadar yuran tidak tersedia: $error';
  }

  @override
  String get sendBtcLoadingFeeRates => 'Memuatkan kadar yuran…';

  @override
  String get sendBtcFinalFeeHint =>
      'Yuran akhir + baki akan ditunjukkan selepas siaran. Setelah dihantar ke rangkaian, ia TIDAK boleh dibatalkan.';

  @override
  String get sendBtcExperimentalBody =>
      'Hantar telah diuji vektor spec BIP-0143 tetapi belum diaudit hujung-ke-hujung.';

  @override
  String sendBtcOnlyBech32(String prefix) {
    return 'Hanya alamat bech32 P2WPKH ($prefix…) yang disokong';
  }

  @override
  String sendBtcExceedsBalance(int available) {
    return 'Jumlah melebihi baki disahkan ($available sat)';
  }

  @override
  String get sendBtcFeeRateLabel => 'Kadar yuran';

  @override
  String get sendBtcFeeTierFastest => 'Terpantas';

  @override
  String get sendBtcFeeTierHalfHour => 'Setengah jam';

  @override
  String get sendBtcFeeTierHour => 'Sejam';

  @override
  String get sendBtcFeeTierEconomy => 'Ekonomi';

  @override
  String get sendBtcFeeEtaFastest => '~10 min';

  @override
  String get sendBtcFeeEtaHalfHour => '~30 min';

  @override
  String get sendBtcFeeEtaHour => '~1 jam';

  @override
  String get sendBtcFeeEtaEconomy => 'Apabila mempool membenarkan';

  @override
  String get sendBchRecipientLabel => 'Alamat penerima (CashAddr)';

  @override
  String get sendBchExperimentalBody =>
      'P2PKH legasi dengan SIGHASH_FORKID. Sighash BIP143 telah diuji vektor spec melalui BTC SegWit; bait sighash 0x41 khas BCH + sampul transaksi legasi telah diuji unit tetapi belum diaudit.';

  @override
  String get sendBchErrorMustBeCashAddr =>
      'Penerima mesti CashAddr (bitcoincash:q…/p… atau q…/p… sahaja)';

  @override
  String get sendBchErrorP2shNotSupported =>
      'Alamat BCH P2SH (p…) belum disokong — hanya P2KH (q…) dalam binaan ini.';

  @override
  String get sendBchFinalFeeHint =>
      'BCH P2PKH legasi dengan SIGHASH_FORKID. Setelah dihantar ini TIDAK boleh dibatalkan (BCH tidak menyokong RBF).';

  @override
  String get sendBchAvailableShort => 'tersedia';

  @override
  String get sendBchNetworkFeeLabel => 'Yuran rangkaian';

  @override
  String sendBchFeeRateDescription(int rate, int typical) {
    return '$rate sat/byte — biasanya tx 1-input ≈ $typical sat. Yuran BCH sangat rendah.';
  }

  @override
  String get sendBchAmountLabel => 'Jumlah (BCH atau sat)';

  @override
  String get sendEthExperimentalBody =>
      'RLP + sighash EIP-1559 + pemulihan ECDSA telah diuji unit tetapi laluan hantar hujung-ke-hujung belum diaudit.';

  @override
  String get sendEthErrorBadAddress =>
      'Penerima mesti alamat 0x + 40 aksara heksadesimal';

  @override
  String sendEthErrorExceedsToken(String symbol) {
    return 'Jumlah melebihi baki $symbol';
  }

  @override
  String sendEthErrorNoGas(String symbol) {
    return 'Tiada $symbol untuk gas — dana dompet ini dahulu';
  }

  @override
  String sendEthAmountLabelToken(String symbol) {
    return 'Jumlah ($symbol atau unit asas)';
  }

  @override
  String sendEthAmountLabelNative(String symbol) {
    return 'Jumlah ($symbol atau wei)';
  }

  @override
  String get sendEthMaxFeeLabel => 'Yuran maks per gas';

  @override
  String get sendEthPriorityFeeLabel => 'Yuran keutamaan';

  @override
  String get sendEthLoadingBalance => 'Memuatkan baki…';

  @override
  String sendEthBalanceError(String error) {
    return 'Ralat baki: $error';
  }

  @override
  String sendEthAvailableForGas(String amount, String symbol) {
    return 'tersedia · $amount $symbol untuk gas';
  }

  @override
  String sendEthFeeError(String error) {
    return 'Data yuran tidak tersedia: $error';
  }

  @override
  String get sendEthLoadingFee => 'Memuatkan kadar yuran…';

  @override
  String get sendEthNetworkFeeHeader => 'YURAN RANGKAIAN';

  @override
  String get sendEthAutoBadge => 'AUTO';

  @override
  String get sendEthBaseLabel => 'Asas';

  @override
  String get sendEthTipLabel => 'Tip';

  @override
  String get sendEthMaxLabel => 'Maks';

  @override
  String get sendEthFinalFeeHint =>
      'Yuran akhir bergantung pada yuran asas rangkaian semasa dimasukkan. Apa-apa di bawah maks dikembalikan — bayar lebih tidak benar-benar berkos. Setelah dihantar ini TIDAK boleh dibatalkan.';

  @override
  String get sendSolExperimentalBody =>
      'Pengekodan transaksi Solana telah diuji unit tetapi laluan hantar hujung-ke-hujung belum diaudit.';

  @override
  String get sendSolErrorBadAddress => 'Alamat sepatutnya 32-44 aksara base58';

  @override
  String get sendSolErrorNoSol =>
      'Tiada SOL untuk yuran — dana dompet ini dengan sedikit SOL dahulu';

  @override
  String sendSolErrorNeedsAtaSol(String symbol) {
    return 'Penerima tiada akaun $symbol — penghantaran akan mencipta satu (memerlukan ~0.00204 SOL sewa + yuran).';
  }

  @override
  String get sendSolErrorNotEnoughSol =>
      'Tidak cukup SOL untuk yuran rangkaian.';

  @override
  String get sendSolErrorAmountFeeExceeds => 'Jumlah + yuran melebihi baki';

  @override
  String sendSolAmountLabelToken(String symbol) {
    return 'Jumlah ($symbol atau unit asas)';
  }

  @override
  String get sendSolAmountLabelNative => 'Jumlah (SOL atau lamport)';

  @override
  String get sendSolAddressHint => 'Alamat Solana';

  @override
  String get sendSolNetworkFeeLabel => 'Yuran rangkaian';

  @override
  String get sendSolAtaRentLabel => 'Sewa ATA';

  @override
  String get sendSolTotalOutLabel => 'Jumlah SOL keluar';

  @override
  String get sendSolFinalFeeHintNative =>
      'Yuran Solana ditetapkan pada 5000 lamport setiap tandatangan. Setelah dihantar TIDAK boleh dibatalkan.';

  @override
  String sendSolFinalFeeHintNewAta(String symbol) {
    return 'Penerima belum ada akaun $symbol. Menghantar mencipta satu untuk mereka (~0.00204 SOL sewa, dibayar anda). Setelah dihantar TIDAK boleh dibatalkan.';
  }

  @override
  String get sendTrxExperimentalBody =>
      'Tx Tron dibina oleh RPC dan ditandatangani secara tempatan. Hash txid disahkan sebelum ditandatangan, tetapi kami tidak menyahkod badan protobuf.';

  @override
  String get sendTrxErrorBadAddress =>
      'Penerima mesti alamat base58 Tron (mula dengan T, 34 aksara)';

  @override
  String get sendTrxErrorNoTrx =>
      'Tiada TRX untuk lebar jalur/tenaga — dana dompet ini dengan TRX dahulu';

  @override
  String get sendTrxRecipientLabel => 'Penerima (Tron base58)';

  @override
  String sendTrxAmountLabelToken(String symbol) {
    return 'Jumlah ($symbol atau unit asas)';
  }

  @override
  String get sendTrxAmountLabelNative => 'Jumlah (TRX atau sun)';

  @override
  String get sendTrxBandwidthLabel => 'Lebar jalur/tenaga';

  @override
  String get sendTrxBandwidthToken => 'Sehingga ~30 TRX setara (TRC-20)';

  @override
  String get sendTrxBandwidthNative => 'Kuota percuma atau ~0.27 TRX';

  @override
  String get sendTrxFinalFeeHint =>
      'Transaksi Tron dibina oleh nod RPC; kami mengesahkan semula hash txid sebelum menandatangan secara tempatan. Setelah dihantar TIDAK boleh dibatalkan.';

  @override
  String get sendXmrTitle => 'Hantar XMR';

  @override
  String get sendXmrScanTitle => 'Imbas alamat penerima';

  @override
  String sendXmrAvailable(String amount) {
    return 'Tersedia: $amount XMR';
  }

  @override
  String get sendXmrAddRecipient => 'Tambah penerima';

  @override
  String get sendXmrSendAllTitle => 'Hantar semua';

  @override
  String get sendXmrSendAllBody =>
      'Sapu setiap output yang boleh dibelanjakan kepada penerima pertama — yuran akan ditolak secara automatik.';

  @override
  String get sendXmrFeePriorityLabel => 'Keutamaan yuran';

  @override
  String get sendXmrTierSlow => 'Perlahan';

  @override
  String get sendXmrTierNormal => 'Biasa';

  @override
  String get sendXmrTierFast => 'Pantas';

  @override
  String get sendXmrReviewAction => 'Semak penghantaran';

  @override
  String get sendXmrToLabel => 'Kepada';

  @override
  String sendXmrToNumbered(int index) {
    return 'Kepada #$index';
  }

  @override
  String get sendXmrSubtotalLabel => 'Subjumlah';

  @override
  String get sendXmrSweepLabel => 'Menghantar (sapu)';

  @override
  String get sendXmrNetworkFee => 'Yuran rangkaian';

  @override
  String sendXmrSplitWarning(int count) {
    return 'Penghantaran ini akan disalurkan sebagai $count sub-transaksi.';
  }

  @override
  String get sendXmrBroadcastTitle => 'Transaksi disiarkan';

  @override
  String get sendXmrBroadcastBody =>
      'Ia akan muncul dalam sejarah transaksi anda setelah rangkaian mengesahkannya.';

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
  String get sendXmrRemoveTooltip => 'Buang';

  @override
  String get sendXmrAddressLabel => 'Alamat penerima';

  @override
  String get sendXmrAddressBookTooltip => 'Buku alamat';

  @override
  String get sendXmrPasteTooltip => 'Tampal';

  @override
  String get sendXmrAmountLabel => 'Jumlah (XMR)';

  @override
  String get sendXmrAmountHintSweep =>
      'Sapu — jumlah ditetapkan secara automatik';

  @override
  String sendXmrErrorBadAddress(String tag) {
    return 'Alamat tidak kelihatan seperti Monero$tag.';
  }

  @override
  String sendXmrErrorAmountZero(String tag) {
    return 'Jumlah mesti lebih daripada 0$tag.';
  }

  @override
  String get sendXmrErrorExceedsBalance => 'Jumlah melebihi baki anda.';

  @override
  String get settingsTitle => 'Tetapan';

  @override
  String get settingsMoneroNode => 'Nod Monero';

  @override
  String get settingsMoneroNodeBody =>
      'Daemon Monero yang PeekWallet sambung untuk sinkronisasi. Lalai ialah nod awam Cake Wallet. Untuk privasi penuh, jalankan monerod sendiri dan tunjukkan ke sini.';

  @override
  String get settingsDaemonUrlLabel => 'URL Daemon';

  @override
  String get settingsPasteTooltip => 'Tampal';

  @override
  String settingsConnectsToPreview(String hostPort, String ssl) {
    return 'Menyambung ke $hostPort (ssl=$ssl)';
  }

  @override
  String get settingsMessageBadUrl =>
      'Tidak dapat menghuraikan URL itu. Cuba contohnya https://node.example.com:18081';

  @override
  String get settingsMessageSaved =>
      'Disimpan. Kunci + buka kunci aplikasi untuk menukar dompet anda ke nod baharu.';

  @override
  String settingsMessageReset(String url) {
    return 'Tetapan semula. Aplikasi akan menggunakan $url pada kunci semula berikutnya.';
  }

  @override
  String get settingsResetToDefault => 'Tetapkan semula ke lalai';

  @override
  String get settingsSectionPublicNodes => 'Nod awam';

  @override
  String get settingsSectionSecurity => 'Keselamatan';

  @override
  String get settingsSectionDisplay => 'Paparan';

  @override
  String get settingsBiometricUnlock => 'Buka kunci biometrik';

  @override
  String get settingsBiometricUnlockOn =>
      'Guna cap jari / muka untuk membuka kunci';

  @override
  String get settingsBiometricUnlockOff =>
      'Tidak tersedia — tiada biometrik yang didaftar';

  @override
  String get settingsBiometricEnableTitle => 'Aktifkan buka kunci biometrik';

  @override
  String get settingsBiometricEnableHint =>
      'Masukkan kata laluan aplikasi untuk mengesahkan';

  @override
  String settingsBiometricEnableFailed(String error) {
    return 'Tidak dapat diaktifkan: $error';
  }

  @override
  String get settingsPasswordLabel => 'Kata laluan';

  @override
  String get settingsRevealSeedTitle => 'Dedahkan frasa pemulihan';

  @override
  String get settingsRevealSeedBody =>
      'Lihat benih BIP39 + kunci belanja/lihat Monero';

  @override
  String get settingsAddressBookTitle => 'Buku alamat';

  @override
  String get settingsAddressBookBody =>
      'Label tersimpan untuk penerima yang anda hantar';

  @override
  String get settingsAutoLockTitle => 'Kunci auto';

  @override
  String get settingsAutoLockSheetTitle => 'Kunci auto selepas pergi latar';

  @override
  String get settingsAutoLockSheetBody =>
      'Berapa lama PeekWallet boleh kekal terbuka kunci semasa anda menggunakan aplikasi lain. Pulang dalam tempoh ini kekal log masuk; lebih lama, kata laluan diperlukan semula.';

  @override
  String get settingsAutoLockImmediately => 'Serta-merta';

  @override
  String get settingsAutoLockNever => 'Tidak pernah';

  @override
  String settingsAutoLockSeconds(int n) {
    return '$n s';
  }

  @override
  String get settingsAutoLock30Seconds => '30 saat';

  @override
  String get settingsAutoLock1Minute => '1 minit';

  @override
  String get settingsAutoLock2MinutesDefault => '2 minit (lalai)';

  @override
  String get settingsAutoLock5Minutes => '5 minit';

  @override
  String get settingsAutoLock15Minutes => '15 minit';

  @override
  String get settingsAutoLock1Hour => '1 jam';

  @override
  String get settingsLockAppTitle => 'Kunci aplikasi';

  @override
  String get settingsLockAppBody =>
      'Kosongkan benih dalam memori dan perlukan kata laluan semula';

  @override
  String get settingsLockConfirmTitle => 'Kunci aplikasi?';

  @override
  String get settingsLockConfirmBody =>
      'Anda perlu masukkan kata laluan untuk membuka kunci. Sebarang sinkronisasi Monero akan menyambung dari tempat ia berhenti.';

  @override
  String get settingsLockConfirmAction => 'Kunci';

  @override
  String get settingsDisplayCurrencyTitle => 'Mata wang paparan';

  @override
  String get settingsDisplayCurrencyDisabled => 'Dinyahaktifkan';

  @override
  String get settingsShowFiatValues => 'Tunjuk nilai fiat';

  @override
  String get settingsShowFiatValuesBody =>
      'Mengundi CoinGecko setiap 5 minit. Tiada PII dihantar.';

  @override
  String get settingsExportLogsTitle => 'Eksport log';

  @override
  String get settingsExportLogsBody =>
      '7 hari terakhir. Alamat dan kunci diredaksi automatik.';

  @override
  String get settingsExportLogsEmpty => 'Belum ada log untuk dieksport.';

  @override
  String get settingsExportLogsDialogTitle => 'Log (7 hari terakhir)';

  @override
  String get settingsExportLogsCopied => 'Log disalin ke papan keratan';

  @override
  String get settingsCloseAction => 'Tutup';

  @override
  String get settingsRestoreAllTitle =>
      'Pulihkan semua syiling daripada benih bilik kebal';

  @override
  String get settingsRestoreAllBody =>
      'Sekali ketik untuk menerbitkan dompet bagi setiap syiling daripada benih 12/24-perkataan sedia ada anda.';

  @override
  String get settingsCustomRpcTitle => 'Titik akhir RPC tersuai';

  @override
  String get settingsCustomRpcBody =>
      'Tunjukkan BTC/LTC/BCH/ETH/POL/SOL/TRX ke nod anda sendiri.';

  @override
  String get settingsUpdateTitle => 'Semak kemas kini';

  @override
  String get settingsUpdateChecking => 'Menyemak GitHub…';

  @override
  String get settingsUpdateTapToCheck => 'Ketik untuk semak';

  @override
  String get settingsUpdateFailedFallback => 'Semakan gagal';

  @override
  String settingsUpdateAvailable(String ago) {
    return 'Kemas kini tersedia — dikeluarkan $ago. Ketik untuk muat turun.';
  }

  @override
  String get settingsUpdateDebugBuild =>
      'Binaan debug — semakan versi dinyahaktifkan. Ketik untuk cuba semula.';

  @override
  String get settingsUpdateUpToDate => 'Terkini · disemak baru sahaja';

  @override
  String get settingsAboutTitle => 'Mengenai PeekWallet';

  @override
  String get settingsAboutBody => 'Versi, lesen, kod sumber';

  @override
  String get addWalletChooseCoin => 'Pilih syiling';

  @override
  String addWalletTitle(String coin) {
    return 'Tambah dompet $coin';
  }

  @override
  String get addWalletCreateTitle => 'Cipta dompet baharu';

  @override
  String get addWalletCreateBody =>
      'Hasilkan frasa benih baharu. Sesiapa dengan frasa itu boleh membelanjakan dompet — tulis di atas kertas.';

  @override
  String get addWalletRestoreSeedTitle => 'Pulihkan dari benih';

  @override
  String get addWalletRestoreSeedBody =>
      'Gunakan frasa pemulihan yang anda sudah ada (BIP39 12/24 perkataan, benih Monero 25-perkataan, atau Polyseed 14 perkataan).';

  @override
  String get addWalletRestoreKeysTitle => 'Pulihkan dari kunci';

  @override
  String get addWalletRestoreKeysBody =>
      'Alamat + kunci belanja peribadi + kunci lihat peribadi. Gunakan jika anda ada kunci tetapi bukan frasa benih.';

  @override
  String get addWalletFormatNew => 'Format benih baharu';

  @override
  String get addWalletFormatRestore => 'Format pulih';

  @override
  String get addWalletFormatBip39Hint =>
      'Mnemonik BIP39 — format standard 12/24 perkataan yang digunakan setiap dompet moden. Trezor, Ledger. Universal merentas banyak syiling.';

  @override
  String get addWalletFormatMoneroLegacyHint =>
      'Benih asli Monero gaya electrum. Interoperabiliti terus dengan Cake, Feather, dan Monero GUI.';

  @override
  String get addWalletFormatPolyseedHint =>
      'Standard Monero terbaru — 14 perkataan. Tinggi pemulihan disertakan.';

  @override
  String get addWalletFormatKeysOnlyHint =>
      'Kunci belanja + kunci lihat + alamat. Tiada perkataan.';

  @override
  String get addWalletVaultLocked =>
      'Bilik kebal berkunci — buka kunci semula dan cuba lagi.';

  @override
  String addWalletGenerateHeader(String format) {
    return 'Hasilkan $format';
  }

  @override
  String get addWalletGenerateBody =>
      'Apabila anda ketik Hasilkan, perkataan akan muncul sekali sahaja. Tuliskannya di atas kertas sebelum meneruskan. Sesiapa dengan perkataan ini boleh menguras dompet ini.';

  @override
  String get addWalletGenerateAction => 'Hasilkan benih';

  @override
  String get addWalletWriteThisDown => 'Tuliskan ini';

  @override
  String get addWalletWordsWarning =>
      'Perkataan ini ADALAH dompet. Sesiapa dengannya boleh membelanjakannya.';

  @override
  String get addWalletCopyClipboardClears =>
      'Disalin — papan keratan dikosongkan auto dalam 30 s';

  @override
  String get addWalletCopyPhraseAction => 'Salin frasa';

  @override
  String get addWalletNameLabel => 'Nama dompet (hanya anda yang nampak)';

  @override
  String get addWalletNameHint => 'cth. \"Monero Utama\"';

  @override
  String get addWalletSavedConfirm =>
      'Saya telah simpan perkataan — tambah dompet';

  @override
  String addWalletRestoreTitle(String format) {
    return 'Pulihkan $format';
  }

  @override
  String get addWalletRestoreNameLabel => 'Nama dompet';

  @override
  String get addWalletRestoreNameHint => 'cth. \"Diimport dari Cake\"';

  @override
  String get addWalletRecoveryPhraseLabel => 'Frasa pemulihan';

  @override
  String get addWalletSeedWordsLabel => 'Perkataan benih';

  @override
  String get addWalletPassphraseLabel =>
      'Frasa laluan BIP39 (perkataan ke-25) — pilihan';

  @override
  String get addWalletPassphraseHint => 'Biar kosong jika tidak digunakan';

  @override
  String get addWalletPassphraseWarning =>
      'Jika dompet sumber mempunyai frasa laluan, anda MESTI masukkan — jika tidak anda akan dapat dompet yang berbeza sama sekali.';

  @override
  String get addWalletSeedOffsetLabel => 'Offset benih — pilihan';

  @override
  String get addWalletSeedOffsetHint =>
      'Biar kosong jika benih tidak disulitkan';

  @override
  String get addWalletRestoreHeightLabel => 'Tinggi pemulihan — pilihan';

  @override
  String get addWalletRestoreHeightHint => 'Nombor blok untuk mula mengimbas';

  @override
  String get addWalletRestoreHeightBody =>
      'Lebih rendah = lebih menyeluruh tapi sinkronisasi perlahan; lebih tinggi = lebih cepat tapi mungkin terlepas resit lama.';

  @override
  String get addWalletRestoreAction => 'Pulihkan dompet';

  @override
  String get addWalletKeysRestoreTitle => 'Pulihkan dari kunci';

  @override
  String get addWalletPrimaryAddressLabel => 'Alamat utama';

  @override
  String get addWalletSpendKeyLabel => 'Kunci belanja peribadi (hex)';

  @override
  String get addWalletViewKeyLabel => 'Kunci lihat peribadi (hex)';

  @override
  String get addWalletKeysRestoreHeightLabel => 'Tinggi pemulihan';

  @override
  String get addWalletKeysRestoreHeightHint =>
      'Nombor blok — lebih awal merangkumi resit lebih lama';

  @override
  String get addWalletScanAddressTitle => 'Imbas alamat';

  @override
  String get addWalletConfirmPasswordTitle => 'Sahkan kata laluan';

  @override
  String get addWalletAppPasswordLabel => 'Kata laluan aplikasi';

  @override
  String lockTryAgainIn(String duration) {
    return 'Cuba lagi dalam $duration.';
  }

  @override
  String get welcomeTagline =>
      'Dompet self-custody untuk BTC, ETH, XMR dan lain-lain.';

  @override
  String get welcomeCreateAction => 'Cipta dompet baharu';

  @override
  String get welcomeImportAction => 'Saya sudah ada frasa pemulihan';

  @override
  String get welcomeBackupWarning =>
      'Frasa pemulihan 12-perkataan anda adalah satu-satunya sandaran. Sesiapa dengannya boleh ambil dana anda.';

  @override
  String get welcomeDisclaimerAction => 'Baca penafian tanpa-jaminan';

  @override
  String get welcomeDisclaimerTitle => 'Penafian';

  @override
  String get welcomeCopiedToast => 'Disalin';

  @override
  String get welcomeCopyTextAction => 'Salin teks';

  @override
  String get welcomeIUnderstandAction => 'Saya faham';

  @override
  String get revealSeedTitle => 'Dedahkan frasa pemulihan';

  @override
  String get revealSeedWarning =>
      'Anda akan mendedahkan frasa benih dan kunci Monero. Sesiapa yang melihat boleh ambil dana anda — pastikan tiada siapa melihat skrin dan anda tidak berkongsi skrin.';

  @override
  String get revealSeedPasswordPrompt =>
      'Masukkan kata laluan aplikasi untuk meneruskan.';

  @override
  String get revealSeedRevealAction => 'Dedahkan';

  @override
  String get revealSeedBip39Section => 'Frasa pemulihan BIP39';

  @override
  String get revealSeedPassphraseSection =>
      'Frasa laluan BIP39 (perkataan ke-25)';

  @override
  String get revealSeedXmrAddressSection => 'Alamat utama Monero';

  @override
  String get revealSeedXmrSpendSection => 'Kunci belanja peribadi Monero';

  @override
  String get revealSeedXmrViewSection => 'Kunci lihat peribadi Monero';

  @override
  String get revealSeedCopyPhrase => 'Salin frasa';

  @override
  String get revealSeedCopyPassphrase => 'Salin frasa laluan';

  @override
  String get revealSeedCopyAddress => 'Salin alamat';

  @override
  String get revealSeedCopySpendKey => 'Salin kunci belanja';

  @override
  String get revealSeedCopyViewKey => 'Salin kunci lihat';

  @override
  String get revealSeedRestoreHint =>
      'Anda boleh memulihkan dompet ini di Cake / Feather / Monero GUI dengan \"Pulihkan dari kunci\" menggunakan alamat + kunci lihat + kunci belanja di atas, atau \"Pulihkan dari benih\" dengan frasa BIP39 dalam mana-mana dompet yang serasi BIP39.';

  @override
  String get revealSeedCopiedSensitive =>
      'Disalin — papan keratan dikosongkan auto dalam 30 s';

  @override
  String get revealSeedCopiedPlain => 'Disalin';

  @override
  String get aboutScreenTitle => 'Mengenai';

  @override
  String aboutVersionLine(String version, String build) {
    return 'v$version (binaan $build)';
  }

  @override
  String get aboutAppVersion => 'Versi aplikasi';

  @override
  String get aboutBuildNumber => 'Nombor binaan';

  @override
  String get aboutPackage => 'Pakej';

  @override
  String get aboutBuildSignature => 'Tandatangan binaan';

  @override
  String get aboutSourceSection => 'Kod sumber';

  @override
  String get aboutLegalSection => 'Undang-undang';

  @override
  String get aboutGithubRepo => 'Repositori GitHub';

  @override
  String get aboutLicenseLink => 'Lesen (GPL-3.0-or-later)';

  @override
  String get aboutDisclaimerLink => 'Penafian (tanpa jaminan)';

  @override
  String get aboutSecurityModelLink => 'Model keselamatan';

  @override
  String get aboutFreeSoftwareBody =>
      'PeekWallet ialah perisian sumber terbuka percuma. Sesiapa boleh membaca sumber, membinanya sendiri, dan mengesahkan binari di /releases sepadan dengan kod awam (kebolehulangan dijejaki dalam peta jalan).';

  @override
  String get aboutUrlCopiedToast => 'URL disalin — buka di pelayar anda';

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
      'Simpan penerima yang akan anda hantar.';

  @override
  String get addressBookEmptyBody =>
      'Simpan alamat orang yang anda hantar dengan kerap supaya tidak perlu tampal setiap kali.';

  @override
  String get addressBookAddAction => 'Tambah entri';

  @override
  String get addressBookErrorLabelEmpty => 'Label tidak boleh kosong.';

  @override
  String get addressBookErrorAddressEmpty => 'Alamat tidak boleh kosong.';

  @override
  String get addressBookDeleteTitle => 'Padam entri?';

  @override
  String get addressBookDeleteBody =>
      'Alamat tidak terjejas — hanya label / nota tersimpan ini yang dibuang.';

  @override
  String get addressBookDeleteAction => 'Padam';

  @override
  String get addressBookEditTitle => 'Edit alamat';

  @override
  String get addressBookAddTitle => 'Tambah alamat';

  @override
  String get addressBookDeleteTooltip => 'Padam';

  @override
  String get addressBookLabelField => 'Label';

  @override
  String get addressBookAddressField => 'Alamat';

  @override
  String get addressBookAddressLocked =>
      'Alamat tidak boleh disunting — padam dan tambah semula untuk mengubah.';

  @override
  String get addressBookScanTooltip => 'Imbas';

  @override
  String get addressBookPasteTooltip => 'Tampal';

  @override
  String get addressBookNotesField => 'Nota (pilihan)';

  @override
  String get addressBookNotesHint =>
      'Teks bebas — disimpan secara tempatan sahaja.';

  @override
  String get addressBookSaveChanges => 'Simpan perubahan';

  @override
  String get addressBookAddToBook => 'Tambah ke buku';

  @override
  String get qrScanTitle => 'Imbas QR';

  @override
  String get qrScanTorchTooltip => 'Lampu suluh';

  @override
  String qrScanCameraError(String code) {
    return 'Ralat kamera: $code';
  }

  @override
  String get qrScanPermissionDenied => 'Kebenaran kamera ditolak';

  @override
  String get qrScanPermissionBody =>
      'PeekWallet memerlukan akses kamera untuk mengimbas kod QR. Kamera hanya digunakan semasa skrin ini terbuka dan hanya membaca muatan QR.';

  @override
  String get qrScanTryAgain => 'Cuba lagi';

  @override
  String get qrScanOpenSettings => 'Buka tetapan aplikasi';

  @override
  String get qrScanCenterHint => 'Tengahkan kod QR dalam bingkai';

  @override
  String get rpcResetTitle => 'Tetapkan semula semua override?';

  @override
  String get rpcResetBody =>
      'Setiap rantaian akan kembali ke titik akhir lalai awam. Anda boleh menambah override semula bila-bila masa.';

  @override
  String get rpcResetAction => 'Tetap semula';

  @override
  String get rpcScreenTitle => 'Titik akhir RPC tersuai';

  @override
  String get rpcResetAllTooltip => 'Tetap semula semua';

  @override
  String get rpcIntroBody =>
      'Tunjukkan setiap rantaian ke nod anda sendiri dan bukan lalai awam. Membiar medan kosong mengekalkan lalai semasa.';

  @override
  String rpcDefaultHint(String hint) {
    return 'Lalai: $hint';
  }

  @override
  String get rpcSaveAction => 'Simpan';

  @override
  String get rpcPrivacyNotesBody =>
      'Nota privasi:\n• Lalai awam melihat alamat IP anda dan alamat yang anda tanyakan. Jalankan nod sendiri atau proksi melalui VPN / LAN melalui Tailscale.\n• Titik akhir RPC tersuai yang dihantar di sini terus ke URL yang anda masukkan — rangkaian anda melihat destinasi. Pilih penyedia yang anda percaya.';

  @override
  String get restoreAllTitle => 'Pulihkan semua syiling dari bilik kebal';

  @override
  String get restoreAllIntro =>
      'Menambah dompet untuk setiap syiling yang disokong, diterbitkan daripada benih bilik kebal 12/24-perkataan sedia ada anda.';

  @override
  String get restoreAllNote =>
      'Dompet sedia ada dilangkau (tiada pendua). Monero dikecualikan — ia mempunyai format benih berasingan dan dipulihkan dari persediaannya sendiri.';

  @override
  String get restoreAllAction => 'Pulihkan semua dari benih bilik kebal';

  @override
  String get restoreAllVaultLocked =>
      'Bilik kebal berkunci. Buka kunci dan cuba lagi.';

  @override
  String restoreAllHasWallet(String symbol) {
    return 'Sudah ada dompet $symbol — langkau';
  }

  @override
  String get restoreAllWillDerive =>
      'Akan diterbitkan daripada benih BIP39 bilik kebal';

  @override
  String showSeedTitle(String name) {
    return 'Frasa pemulihan · $name';
  }

  @override
  String get showSeedPasswordPrompt =>
      'Masukkan kata laluan aplikasi untuk melihat frasa pemulihan dompet ini.';

  @override
  String get showSeedPasswordLabel => 'Kata laluan aplikasi';

  @override
  String get showSeedRevealAction => 'Dedahkan';

  @override
  String get showSeedRecoveryPhrase => 'Frasa pemulihan';

  @override
  String get showSeedCopyPhrase => 'Salin frasa';

  @override
  String get showSeedCopyClipboardClears =>
      'Disalin — papan keratan dikosongkan auto dalam 30s';

  @override
  String get showSeedPassphraseSection => 'Frasa laluan (perkataan ke-25)';

  @override
  String get showSeedSeedOffsetSection => 'Offset benih';

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
    return 'Simpanan: $format. Syiling: $coin.';
  }

  @override
  String get showSeedWriteDownWarning =>
      'Tuliskan di atas kertas dan simpan di tempat selamat. Sesiapa dengan frasa ini mempunyai kawalan penuh ke atas dompet. Jangan ambil tangkapan skrin — FLAG_SECURE menyekatnya juga.';

  @override
  String get showSeedKeysOnlyDisplay => 'Kunci sahaja';

  @override
  String get walletMenuShowSeed => 'Tunjuk frasa pemulihan';

  @override
  String get walletMenuShowSeedBody =>
      'Sandarkan ini secara berasingan daripada benih bilik kebal.';

  @override
  String get walletMenuRename => 'Namakan semula';

  @override
  String get walletMenuRenameTitle => 'Namakan semula dompet';

  @override
  String walletMenuDeleteTitle(String name) {
    return 'Padam $name?';
  }

  @override
  String get walletMenuDeleteBody =>
      'Dompet di rantaian tidak terjejas — sesiapa dengan benih masih boleh memulihkannya kemudian. Hanya rekod di peranti ini dipadam.';

  @override
  String get cwSeedTitle => 'Frasa pemulihan';

  @override
  String get cwConfirmTitle => 'Sahkan frasa';

  @override
  String get cwPasswordTitle => 'Tetapkan kata laluan';

  @override
  String get cwSeedWarning =>
      'Tulis 12 perkataan ini di atas kertas dan simpan dengan selamat. Sesiapa yang memiliki frasa ini boleh mengambil dana anda. Jangan taipkannya di mana-mana laman web.';

  @override
  String get cwIveWrittenItDown => 'Saya telah menulisnya';

  @override
  String get cwConfirmBody =>
      'Taipkan perkataan yang diminta untuk mengesahkan anda telah menyimpan frasa.';

  @override
  String get cwWordPlaceholderHint => 'Huruf kecil, tiada ruang';

  @override
  String cwWordNumberLabel(int n) {
    return 'Perkataan #$n';
  }

  @override
  String get cwPasswordBody =>
      'Kata laluan ini menyulitkan dompet anda pada peranti ini. Anda perlu memasukkannya setiap kali membuka kunci.';

  @override
  String get cwPasswordMinLabel => 'Kata laluan (min 8 aksara)';

  @override
  String get cwConfirmPasswordLabel => 'Sahkan kata laluan';

  @override
  String get cwPasswordTooShort =>
      'Kata laluan mestilah sekurang-kurangnya 8 aksara.';

  @override
  String get cwPasswordsDontMatch => 'Kata laluan tidak sepadan.';

  @override
  String get cwCreateWalletAction => 'Cipta dompet';

  @override
  String get cwCopyPhrase => 'Salin frasa';

  @override
  String get cwCopiedClipboardAutoClear =>
      'Disalin — papan keratan kosong sendiri dalam 30 s';

  @override
  String get iwScreenTitle => 'Import dompet';

  @override
  String get iwIntro =>
      'Tampal frasa pemulihan BIP39 sedia ada anda (12 atau 24 perkataan). Format sama seperti vault-wallet.';

  @override
  String get iwRecoveryPhraseLabel => 'Frasa pemulihan';

  @override
  String get iwPhraseHint => 'word1 word2 word3 ...';

  @override
  String get iwPassphraseOptionalLabel =>
      'Frasa laluan BIP39 (perkataan ke-25) — pilihan';

  @override
  String get iwPassphraseHintBlank =>
      'Biar kosong jika anda tidak menetapkannya';

  @override
  String get iwPassphraseWarning =>
      'Jika anda menggunakan frasa laluan BIP39 dalam vault-wallet (atau dompet lain) anda MESTI memasukkannya di sini — tanpanya alamat yang diimport tidak akan sepadan dan baki akan muncul sebagai sifar.';

  @override
  String get iwAppPasswordMinLabel => 'Kata laluan aplikasi (min 8 aksara)';

  @override
  String get iwConfirmAppPasswordLabel => 'Sahkan kata laluan aplikasi';

  @override
  String get iwErrorBadWordCount =>
      'Masukkan frasa pemulihan 12 atau 24 perkataan anda.';

  @override
  String get iwErrorBip39Checksum =>
      'Frasa pemulihan tidak sah (gagal semakan BIP39).';

  @override
  String get iwErrorAppPasswordTooShort =>
      'Kata laluan aplikasi mestilah sekurang-kurangnya 8 aksara.';

  @override
  String get iwImportAction => 'Import dompet';

  @override
  String get xmrScreenUnlockTitle => 'Buka kunci dompet';

  @override
  String get xmrScreenUnlockAction => 'Buka';

  @override
  String get xmrScreenErrLocked => 'Dompet berkunci';

  @override
  String xmrScreenErrAddressDerivation(String error) {
    return 'Penerbitan alamat gagal: $error';
  }

  @override
  String get xmrScreenErrVaultLocked =>
      'Bilik kebal berkunci — kata laluan dompet tidak tersedia';

  @override
  String get xmrScreenErrPasswordRequired =>
      'Kata laluan diperlukan untuk membuka dompet ini';

  @override
  String xmrScreenErrCouldNotOpen(String error) {
    return 'Tidak dapat membuka dompet: $error';
  }

  @override
  String xmrScreenErrUnknownCoin(String coin) {
    return 'Syiling tidak dikenali: $coin';
  }

  @override
  String xmrScreenBootStage(String stage) {
    return 'But: $stage';
  }

  @override
  String get xmrScreenConnectingDaemon => 'Menyambung ke daemon…';

  @override
  String xmrScreenSyncingPct(int pct) {
    return 'Menyegerak $pct%';
  }

  @override
  String xmrScreenSyncedAtHeight(String h) {
    return 'Disegerakkan · tinggi $h';
  }

  @override
  String get xmrScreenSynced => 'Disegerakkan';

  @override
  String xmrScreenDaemonError(String error) {
    return 'Daemon: $error';
  }

  @override
  String xmrScreenEngineError(String error) {
    return 'Enjin: $error';
  }

  @override
  String get xmrScreenBootingWallet => 'Mulakan dompet…';

  @override
  String get xmrScreenResetTitle => 'Tetapkan semula fail dompet?';

  @override
  String get xmrScreenResetBody =>
      'Tindakan ini memadam fail dompet pada cakera dan menciptanya semula daripada benih yang disimpan. Cache penyegerakan rantai akan hilang jadi dompet perlu mengimbas semula dari tinggi pemulihan anda (mungkin mengambil masa). Benih anda TIDAK disentuh — dana selamat.\n\nGunakan ini jika anda terperangkap dengan ralat \"kata laluan tidak sah\" yang berterusan.';

  @override
  String get xmrScreenResetAction => 'Tetap semula & imbas semula';

  @override
  String get xmrScreenResetAndRescanFromSeed =>
      'Tetap semula & imbas semula daripada benih';

  @override
  String get xmrScreenActivity => 'Aktiviti';

  @override
  String get xmrScreenWalletStillSyncing =>
      'Dompet masih menyegerak — aktiviti lebih baharu akan muncul setelah kami menyusul puncak rantai.';

  @override
  String get xmrScreenAddressCopied => 'Alamat disalin';

  @override
  String get xmrScreenCopyAddress => 'Salin alamat';

  @override
  String get xmrScreenTxStatusFailed => 'Gagal';

  @override
  String get xmrScreenTxStatusPending => 'Belum selesai';

  @override
  String get xmrScreenTxStatusConfirmed => 'Disahkan';

  @override
  String get xmrScreenDirIncoming => 'Masuk';

  @override
  String get xmrScreenDirOutgoing => 'Keluar';

  @override
  String get xmrScreenTxAmount => 'Jumlah';

  @override
  String get xmrScreenTxFee => 'Yuran';

  @override
  String get xmrScreenTxDate => 'Tarikh';

  @override
  String get xmrScreenTxBlockHeight => 'Tinggi blok';

  @override
  String get xmrScreenTxConfirmations => 'Pengesahan';

  @override
  String get xmrScreenTxStatus => 'Status';

  @override
  String get xmrScreenTxPaymentId => 'Payment ID';

  @override
  String get xmrScreenTxNote => 'Nota';

  @override
  String get xmrScreenTxAdd => 'Tambah';

  @override
  String get xmrScreenTxEdit => 'Edit';

  @override
  String get xmrScreenTxId => 'TX ID';

  @override
  String get xmrScreenTxIdCopied => 'TX ID disalin';

  @override
  String get xmrScreenCopy => 'Salin';

  @override
  String get xmrScreenExplorer => 'Penjelajah';

  @override
  String get xmrScreenCouldNotOpenBrowser => 'Tidak dapat membuka pelayar';

  @override
  String get xmrScreenTxNoteTitle => 'Nota transaksi';

  @override
  String get xmrScreenTxNoteHint => 'Teks bebas — hanya anda boleh membacanya.';

  @override
  String get xmrScreenClear => 'Kosongkan';

  @override
  String get xmrScreenNoteSaved => 'Nota disimpan';

  @override
  String get xmrScreenNoteCleared => 'Nota dikosongkan';

  @override
  String xmrScreenCouldNotSaveNote(String error) {
    return 'Tidak dapat menyimpan nota: $error';
  }

  @override
  String get xmrScreenLabelPrimary => 'Utama';

  @override
  String xmrScreenLabelSubaddress(int index) {
    return 'Label subaddress #$index';
  }

  @override
  String xmrScreenCouldNotSaveLabel(String error) {
    return 'Tidak dapat menyimpan label: $error';
  }

  @override
  String get xmrScreenReceiveTitle => 'Terima XMR';

  @override
  String get xmrScreenSubaddrUnavailable =>
      'Subaddress tidak tersedia sehingga dompet selesai dimulakan.';

  @override
  String get xmrScreenSubaddrSectionTitle => 'Subaddress';

  @override
  String get xmrScreenSubaddrNew => 'Baharu';

  @override
  String get xmrScreenSubaddrBody =>
      'Jana alamat baharu bagi setiap pembayar supaya pemerhati tidak boleh menghubungkan dua pembayaran ke dompet yang sama. Semua menunjuk ke baki yang sama.';

  @override
  String get xmrScreenEditLabelTooltip => 'Edit label';

  @override
  String get xmrScreenAppPasswordLabel => 'Kata laluan aplikasi';

  @override
  String xmrScreenSyncingPctBehind(int pct, int behind) {
    return 'Menyegerak $pct% · $behind blok di belakang';
  }

  @override
  String xmrScreenConfirmationsShort(int n) {
    return '$n konf';
  }

  @override
  String get xmrScreenNoNote => '— Tiada nota —';

  @override
  String get xmrScreenSubaddrLabelHint =>
      'cth. \"Bayaran pelanggan\", \"Kerja sampingan\"';

  @override
  String get xmrScreenEngineLoaded => '✓ Enjin monero_c asli dimuatkan';

  @override
  String xmrScreenEngineNotLoaded(String error) {
    return '✗ Enjin tidak dimuatkan: $error';
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
