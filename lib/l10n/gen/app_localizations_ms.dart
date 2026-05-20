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
