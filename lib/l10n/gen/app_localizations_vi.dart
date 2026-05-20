// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'PeekWallet';

  @override
  String get lockScreenSubtitle => 'Nhập mật khẩu để mở khoá';

  @override
  String get lockPasswordHint => 'Mật khẩu';

  @override
  String get lockUnlock => 'Mở khoá';

  @override
  String get lockUseBiometric => 'Dùng sinh trắc học';

  @override
  String get lockTooManyAttempts => 'Quá nhiều lần thử sai';

  @override
  String get lockTimerWarning =>
      'Khoá điện thoại hoặc khởi động lại ứng dụng sẽ không đặt lại bộ đếm — đây là chủ ý.';

  @override
  String get walletsTitle => 'Ví của tôi';

  @override
  String get walletsRefreshTooltip => 'Làm mới số dư';

  @override
  String get walletsAddTooltip => 'Thêm ví';

  @override
  String get homeTotalBalance => 'Tổng số dư';

  @override
  String homeSyncedCount(int counted, int total) {
    return '$counted / $total đã đồng bộ';
  }

  @override
  String homeAcrossWallets(int count) {
    return 'trên $count ví';
  }

  @override
  String get homeEmptyTitle => 'Chưa có ví';

  @override
  String get homeEmptyBody =>
      'Tạo ví mới hoặc khôi phục từ cụm từ khôi phục để bắt đầu.';

  @override
  String get homeAddWallet => 'Thêm ví';

  @override
  String get actionReceive => 'Nhận';

  @override
  String get actionSend => 'Gửi';

  @override
  String get actionBack => 'Quay lại';

  @override
  String get actionCopy => 'Sao chép';

  @override
  String get actionShare => 'Chia sẻ';

  @override
  String get actionExplorer => 'Trình duyệt';

  @override
  String get actionSending => 'Đang gửi…';

  @override
  String get actionContinue => 'Tiếp tục';

  @override
  String get actionCancel => 'Huỷ';

  @override
  String get actionSave => 'Lưu';

  @override
  String get actionDelete => 'Xoá';

  @override
  String get actionRefresh => 'Làm mới';

  @override
  String receiveTitle(String coinId) {
    return 'Nhận $coinId';
  }

  @override
  String get receiveAddressLabel => 'ĐỊA CHỈ CỦA BẠN';

  @override
  String get receiveAddressCopied => 'Đã sao chép địa chỉ';

  @override
  String get receiveCopiedToClipboard => 'Đã sao chép vào bộ nhớ tạm';

  @override
  String get receiveCouldNotOpenBrowser => 'Không thể mở trình duyệt';

  @override
  String coinScreenBalanceLabel(String symbol) {
    return 'Số dư $symbol';
  }

  @override
  String get coinScreenActivityTitle => 'Hoạt động';

  @override
  String get coinScreenTokensTitle => 'Token';

  @override
  String get coinScreenNoTxYet => 'Chưa có giao dịch';

  @override
  String coinScreenShareAddressHint(String symbol) {
    return 'Chia sẻ địa chỉ để nhận $symbol';
  }

  @override
  String get coinScreenLoading => 'Đang tải…';

  @override
  String get coinScreenRefreshTooltip => 'Làm mới';

  @override
  String get coinScreenAddTokenLabel => 'Thêm token';

  @override
  String balanceCached(String ago) {
    return 'Bộ nhớ đệm · $ago trước';
  }

  @override
  String balanceCachedShort(String ago) {
    return 'Cache · $ago';
  }

  @override
  String balanceCouldNotOpen(String error) {
    return 'Không thể mở ví: $error';
  }

  @override
  String get balanceVaultLocked => 'Két đang khoá.';

  @override
  String get ageJustNow => 'vừa xong';

  @override
  String ageMinutes(int n) {
    return '$n phút';
  }

  @override
  String ageHours(int n) {
    return '$n giờ';
  }

  @override
  String ageDays(int n) {
    return '$n ngày';
  }

  @override
  String get txDirectionIncoming => 'Nhận vào';

  @override
  String get txDirectionOutgoing => 'Gửi đi';

  @override
  String get txStatusConfirmed => 'Đã xác nhận';

  @override
  String get txStatusPending => 'Đang chờ';

  @override
  String get txStatusFailed => 'Thất bại';

  @override
  String get txStatusInMempool => 'Trong mempool';

  @override
  String get txCopiedToClipboard => 'Đã sao chép vào bộ nhớ tạm';

  @override
  String get txIdLabel => 'Mã giao dịch';

  @override
  String get txHashLabel => 'Hash';

  @override
  String get txSignatureLabel => 'Chữ ký';

  @override
  String get txAmountLabel => 'Tổng ròng';

  @override
  String get txFeeLabel => 'Phí';

  @override
  String get txGasFeeLabel => 'Phí gas';

  @override
  String get txNetworkFeeLabel => 'Phí mạng';

  @override
  String get txBlockHeightLabel => 'Chiều cao khối';

  @override
  String get txSlotLabel => 'Slot';

  @override
  String get txDateLabel => 'Ngày';

  @override
  String get txTokenLabel => 'Token';

  @override
  String get txCounterpartyLabel => 'Đối tác';

  @override
  String get sendFormRecipientLabel => 'Địa chỉ người nhận';

  @override
  String get sendFormAmountLabel => 'Số tiền';

  @override
  String get sendFormMaxButton => 'Tối đa';

  @override
  String get sendFormBookTooltip => 'Từ sổ địa chỉ';

  @override
  String get sendFormScanTooltip => 'Quét QR';

  @override
  String get sendFormPasteTooltip => 'Dán từ bộ nhớ tạm';

  @override
  String get sendFormFeePriorityLabel => 'ƯU TIÊN PHÍ';

  @override
  String get sendFormAvailableLabel => 'khả dụng';

  @override
  String get sendFormConfirmHint => 'Nhập SEND để xác nhận';

  @override
  String get sendFormConfirmPlaceholder => 'SEND';

  @override
  String get sendFormErrorInvalidAmount => 'Nhập số tiền hợp lệ';

  @override
  String get sendFormErrorAmountExceedsBalance =>
      'Số tiền + phí vượt quá số dư';

  @override
  String get sendFormErrorRecipientRequired => 'Cần địa chỉ người nhận';

  @override
  String get sendFormWillBeSentTo => 'sẽ được gửi đến';

  @override
  String get sendFormToLabel => 'Đến';

  @override
  String get tronTokensTitle => 'Token (TRC-20)';

  @override
  String get splTokensTitle => 'Token (SPL)';

  @override
  String get erc20TokensTitle => 'Token';

  @override
  String experimentalSendWarning(String symbol) {
    return 'Tính năng gửi đang ở giai đoạn thử nghiệm — hãy thử với số nhỏ trước khi gửi nhiều $symbol.';
  }

  @override
  String sendScreenTitle(String coinName) {
    return 'Gửi $coinName';
  }

  @override
  String sendScanTitle(String symbol) {
    return 'Quét địa chỉ $symbol';
  }

  @override
  String sendBtcAmountLabel(String symbol) {
    return 'Số tiền ($symbol hoặc sat)';
  }

  @override
  String sendBroadcastSuccess(String prefix) {
    return 'Đã phát sóng! txid: $prefix…';
  }

  @override
  String get sendBtcLoadingUtxos => 'Đang tải UTXO…';

  @override
  String sendBtcUtxoError(String error) {
    return 'Lỗi UTXO: $error';
  }

  @override
  String get sendBtcAvailableHint => 'khả dụng · chỉ UTXO đã xác nhận';

  @override
  String sendBtcFeeRatesError(String error) {
    return 'Không lấy được mức phí: $error';
  }

  @override
  String get sendBtcLoadingFeeRates => 'Đang tải mức phí…';

  @override
  String get sendBtcFinalFeeHint =>
      'Phí cuối + tiền dư sẽ hiển thị sau khi phát sóng. Khi đã gửi lên mạng, KHÔNG thể hoàn tác.';

  @override
  String get sendBtcExperimentalBody =>
      'Tính năng gửi đã được kiểm thử vector BIP-0143 nhưng chưa được audit toàn cục.';

  @override
  String sendBtcOnlyBech32(String prefix) {
    return 'Chỉ hỗ trợ địa chỉ bech32 P2WPKH ($prefix…)';
  }

  @override
  String sendBtcExceedsBalance(int available) {
    return 'Số tiền vượt quá số dư đã xác nhận ($available sat)';
  }

  @override
  String get sendBtcFeeRateLabel => 'Mức phí';

  @override
  String get sendBtcFeeTierFastest => 'Nhanh nhất';

  @override
  String get sendBtcFeeTierHalfHour => 'Nửa giờ';

  @override
  String get sendBtcFeeTierHour => 'Một giờ';

  @override
  String get sendBtcFeeTierEconomy => 'Tiết kiệm';

  @override
  String get sendBtcFeeEtaFastest => '~10 phút';

  @override
  String get sendBtcFeeEtaHalfHour => '~30 phút';

  @override
  String get sendBtcFeeEtaHour => '~1 giờ';

  @override
  String get sendBtcFeeEtaEconomy => 'Khi mempool cho phép';

  @override
  String get sendBchRecipientLabel => 'Địa chỉ người nhận (CashAddr)';

  @override
  String get sendBchExperimentalBody =>
      'P2PKH cũ với SIGHASH_FORKID. Sighash BIP143 đã được kiểm thử vector spec qua BTC SegWit; byte sighash 0x41 đặc trưng của BCH + bao bì giao dịch cũ đã được kiểm thử đơn vị nhưng chưa được audit.';

  @override
  String get sendBchErrorMustBeCashAddr =>
      'Người nhận phải là CashAddr (bitcoincash:q…/p… hoặc chỉ q…/p…)';

  @override
  String get sendBchErrorP2shNotSupported =>
      'Địa chỉ BCH P2SH (p…) chưa được hỗ trợ — bản này chỉ hỗ trợ P2KH (q…).';

  @override
  String get sendBchFinalFeeHint =>
      'BCH P2PKH cũ với SIGHASH_FORKID. Sau khi gửi, KHÔNG thể hoàn tác (BCH không hỗ trợ RBF).';

  @override
  String get sendBchAvailableShort => 'khả dụng';

  @override
  String get sendBchNetworkFeeLabel => 'Phí mạng';

  @override
  String sendBchFeeRateDescription(int rate, int typical) {
    return '$rate sat/byte — giao dịch 1 input thường ≈ $typical sat. Phí BCH cực thấp.';
  }

  @override
  String get sendBchAmountLabel => 'Số tiền (BCH hoặc sat)';

  @override
  String get sendEthExperimentalBody =>
      'RLP + sighash EIP-1559 + khôi phục ECDSA đã được kiểm thử đơn vị nhưng đường gửi đầu-cuối chưa được audit.';

  @override
  String get sendEthErrorBadAddress =>
      'Người nhận phải là địa chỉ 0x + 40 ký tự hex';

  @override
  String sendEthErrorExceedsToken(String symbol) {
    return 'Số tiền vượt số dư $symbol';
  }

  @override
  String sendEthErrorNoGas(String symbol) {
    return 'Không có $symbol để trả gas — nạp ví này trước';
  }

  @override
  String sendEthAmountLabelToken(String symbol) {
    return 'Số tiền ($symbol hoặc đơn vị cơ sở)';
  }

  @override
  String sendEthAmountLabelNative(String symbol) {
    return 'Số tiền ($symbol hoặc wei)';
  }

  @override
  String get sendEthMaxFeeLabel => 'Phí tối đa mỗi gas';

  @override
  String get sendEthPriorityFeeLabel => 'Phí ưu tiên';

  @override
  String get sendEthLoadingBalance => 'Đang tải số dư…';

  @override
  String sendEthBalanceError(String error) {
    return 'Lỗi số dư: $error';
  }

  @override
  String sendEthAvailableForGas(String amount, String symbol) {
    return 'khả dụng · $amount $symbol cho gas';
  }

  @override
  String sendEthFeeError(String error) {
    return 'Không có dữ liệu phí: $error';
  }

  @override
  String get sendEthLoadingFee => 'Đang tải mức phí…';

  @override
  String get sendEthNetworkFeeHeader => 'PHÍ MẠNG';

  @override
  String get sendEthAutoBadge => 'TỰ ĐỘNG';

  @override
  String get sendEthBaseLabel => 'Cơ sở';

  @override
  String get sendEthTipLabel => 'Tip';

  @override
  String get sendEthMaxLabel => 'Tối đa';

  @override
  String get sendEthFinalFeeHint =>
      'Phí cuối phụ thuộc vào phí cơ sở mạng khi đưa vào khối. Bất kỳ khoản nào dưới mức tối đa được hoàn — trả dư thực tế không tốn thêm. Khi đã gửi, KHÔNG thể hoàn tác.';

  @override
  String get sendSolExperimentalBody =>
      'Mã hoá giao dịch Solana đã được kiểm thử đơn vị nhưng đường gửi đầu-cuối chưa được audit.';

  @override
  String get sendSolErrorBadAddress => 'Địa chỉ phải có 32-44 ký tự base58';

  @override
  String get sendSolErrorNoSol =>
      'Không có SOL để trả phí — nạp một ít SOL vào ví này trước';

  @override
  String sendSolErrorNeedsAtaSol(String symbol) {
    return 'Người nhận chưa có tài khoản $symbol — gửi sẽ tạo một tài khoản (cần thêm ~0.00204 SOL thuê + phí).';
  }

  @override
  String get sendSolErrorNotEnoughSol => 'Không đủ SOL cho phí mạng.';

  @override
  String get sendSolErrorAmountFeeExceeds => 'Số tiền + phí vượt số dư';

  @override
  String sendSolAmountLabelToken(String symbol) {
    return 'Số tiền ($symbol hoặc đơn vị cơ sở)';
  }

  @override
  String get sendSolAmountLabelNative => 'Số tiền (SOL hoặc lamport)';

  @override
  String get sendSolAddressHint => 'Địa chỉ Solana';

  @override
  String get sendSolNetworkFeeLabel => 'Phí mạng';

  @override
  String get sendSolAtaRentLabel => 'Thuê ATA';

  @override
  String get sendSolTotalOutLabel => 'Tổng SOL ra';

  @override
  String get sendSolFinalFeeHintNative =>
      'Phí Solana cố định 5000 lamport mỗi chữ ký. Khi đã gửi KHÔNG thể hoàn tác.';

  @override
  String sendSolFinalFeeHintNewAta(String symbol) {
    return 'Người nhận chưa có tài khoản $symbol. Gửi sẽ tạo một tài khoản cho họ (~0.00204 SOL thuê, do bạn trả). Khi đã gửi KHÔNG thể hoàn tác.';
  }

  @override
  String get sendTrxExperimentalBody =>
      'Tx Tron được dựng bởi RPC và ký cục bộ. Hash txid được xác minh trước khi ký, nhưng chúng tôi không giải mã thân protobuf.';

  @override
  String get sendTrxErrorBadAddress =>
      'Người nhận phải là địa chỉ base58 Tron (bắt đầu bằng T, 34 ký tự)';

  @override
  String get sendTrxErrorNoTrx =>
      'Không có TRX cho băng thông/năng lượng — nạp TRX vào ví này trước';

  @override
  String get sendTrxRecipientLabel => 'Người nhận (Tron base58)';

  @override
  String sendTrxAmountLabelToken(String symbol) {
    return 'Số tiền ($symbol hoặc đơn vị cơ sở)';
  }

  @override
  String get sendTrxAmountLabelNative => 'Số tiền (TRX hoặc sun)';

  @override
  String get sendTrxBandwidthLabel => 'Băng thông/năng lượng';

  @override
  String get sendTrxBandwidthToken => 'Tối đa ~30 TRX tương đương (TRC-20)';

  @override
  String get sendTrxBandwidthNative => 'Quota miễn phí hoặc ~0.27 TRX';

  @override
  String get sendTrxFinalFeeHint =>
      'Giao dịch Tron được dựng bởi nút RPC; chúng tôi xác minh lại hash txid trước khi ký cục bộ. Khi đã gửi KHÔNG thể hoàn tác.';

  @override
  String get sendXmrTitle => 'Gửi XMR';

  @override
  String get sendXmrScanTitle => 'Quét địa chỉ người nhận';

  @override
  String sendXmrAvailable(String amount) {
    return 'Khả dụng: $amount XMR';
  }

  @override
  String get sendXmrAddRecipient => 'Thêm người nhận';

  @override
  String get sendXmrSendAllTitle => 'Gửi tất cả';

  @override
  String get sendXmrSendAllBody =>
      'Quét tất cả output có thể chi đến người nhận đầu tiên — phí sẽ được trừ tự động.';

  @override
  String get sendXmrFeePriorityLabel => 'Ưu tiên phí';

  @override
  String get sendXmrTierSlow => 'Chậm';

  @override
  String get sendXmrTierNormal => 'Bình thường';

  @override
  String get sendXmrTierFast => 'Nhanh';

  @override
  String get sendXmrReviewAction => 'Xem trước gửi';

  @override
  String get sendXmrToLabel => 'Đến';

  @override
  String sendXmrToNumbered(int index) {
    return 'Đến #$index';
  }

  @override
  String get sendXmrSubtotalLabel => 'Tạm tính';

  @override
  String get sendXmrSweepLabel => 'Đang gửi (quét)';

  @override
  String get sendXmrNetworkFee => 'Phí mạng';

  @override
  String sendXmrSplitWarning(int count) {
    return 'Lần gửi này sẽ được phát thành $count sub-transaction.';
  }

  @override
  String get sendXmrBroadcastTitle => 'Đã phát giao dịch';

  @override
  String get sendXmrBroadcastBody =>
      'Sẽ xuất hiện trong lịch sử giao dịch khi mạng xác nhận.';

  @override
  String get sendXmrTxIdLabel => 'Mã giao dịch';

  @override
  String get sendXmrTxIdCopied => 'Đã sao chép mã giao dịch';

  @override
  String get sendXmrCopyTxIdAction => 'Sao chép TX ID';

  @override
  String get sendXmrDoneAction => 'Xong';

  @override
  String get sendXmrRecipientHeader => 'Người nhận';

  @override
  String get sendXmrRemoveTooltip => 'Xoá';

  @override
  String get sendXmrAddressLabel => 'Địa chỉ người nhận';

  @override
  String get sendXmrAddressBookTooltip => 'Sổ địa chỉ';

  @override
  String get sendXmrPasteTooltip => 'Dán';

  @override
  String get sendXmrAmountLabel => 'Số tiền (XMR)';

  @override
  String get sendXmrAmountHintSweep => 'Quét — số tiền tự động';

  @override
  String sendXmrErrorBadAddress(String tag) {
    return 'Địa chỉ không giống Monero$tag.';
  }

  @override
  String sendXmrErrorAmountZero(String tag) {
    return 'Số tiền phải lớn hơn 0$tag.';
  }

  @override
  String get sendXmrErrorExceedsBalance => 'Tổng vượt số dư.';

  @override
  String get erc20EmptyHint =>
      'Chưa có token — nhận USDT/USDC/DAI vào địa chỉ này hoặc nhấn \"Thêm token\" để theo dõi ERC-20 khác qua địa chỉ hợp đồng.';

  @override
  String get ercAddCustomTitle => 'Thêm token ERC-20 tùy chỉnh';

  @override
  String get ercAddCustomBody =>
      'Dán địa chỉ hợp đồng token. Chúng tôi sẽ lấy ký hiệu và số thập phân từ chuỗi.';

  @override
  String get ercContractLabel => 'Địa chỉ hợp đồng';

  @override
  String get ercProbeAction => 'Dò';

  @override
  String get ercContractError => 'Hợp đồng phải là 0x + 40 ký tự hex';

  @override
  String ercProbingMsg(String prefix) {
    return 'Đang dò $prefix…';
  }

  @override
  String get ercProbeFailedMsg =>
      'Không đọc được dữ liệu token — sai chuỗi hoặc không phải ERC-20?';

  @override
  String ercAddedMsg(String symbol, int decimals) {
    return 'Đã thêm $symbol ($decimals số thập phân)';
  }
}
