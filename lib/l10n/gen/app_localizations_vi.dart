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
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsMoneroNode => 'Nút Monero';

  @override
  String get settingsMoneroNodeBody =>
      'Daemon Monero mà PeekWallet kết nối để đồng bộ. Mặc định là nút công khai của Cake Wallet. Để bảo mật tối đa, hãy tự chạy monerod và trỏ về đó.';

  @override
  String get settingsDaemonUrlLabel => 'URL Daemon';

  @override
  String get settingsPasteTooltip => 'Dán';

  @override
  String settingsConnectsToPreview(String hostPort, String ssl) {
    return 'Kết nối tới $hostPort (ssl=$ssl)';
  }

  @override
  String get settingsMessageBadUrl =>
      'Không phân tích được URL đó. Hãy thử ví dụ https://node.example.com:18081';

  @override
  String get settingsMessageSaved =>
      'Đã lưu. Khoá rồi mở khoá ứng dụng để chuyển ví sang nút mới.';

  @override
  String settingsMessageReset(String url) {
    return 'Đã đặt lại. Ứng dụng sẽ dùng $url ở lần mở khoá kế tiếp.';
  }

  @override
  String get settingsResetToDefault => 'Đặt lại mặc định';

  @override
  String get settingsSectionPublicNodes => 'Nút công khai';

  @override
  String get settingsSectionSecurity => 'Bảo mật';

  @override
  String get settingsSectionDisplay => 'Hiển thị';

  @override
  String get settingsBiometricUnlock => 'Mở khoá sinh trắc';

  @override
  String get settingsBiometricUnlockOn => 'Dùng vân tay / khuôn mặt để mở khoá';

  @override
  String get settingsBiometricUnlockOff =>
      'Không khả dụng — chưa đăng ký sinh trắc';

  @override
  String get settingsBiometricEnableTitle => 'Bật mở khoá sinh trắc';

  @override
  String get settingsBiometricEnableHint =>
      'Nhập mật khẩu ứng dụng để xác nhận';

  @override
  String settingsBiometricEnableFailed(String error) {
    return 'Không thể bật: $error';
  }

  @override
  String get settingsPasswordLabel => 'Mật khẩu';

  @override
  String get settingsRevealSeedTitle => 'Hiện cụm từ khôi phục';

  @override
  String get settingsRevealSeedBody =>
      'Xem seed BIP39 + khoá chi tiêu/xem Monero';

  @override
  String get settingsAddressBookTitle => 'Sổ địa chỉ';

  @override
  String get settingsAddressBookBody => 'Nhãn đã lưu cho người nhận bạn gửi';

  @override
  String get settingsAutoLockTitle => 'Tự khoá';

  @override
  String get settingsAutoLockSheetTitle => 'Tự khoá sau khi vào nền';

  @override
  String get settingsAutoLockSheetBody =>
      'PeekWallet có thể mở khoá bao lâu khi bạn dùng ứng dụng khác. Trở lại trong khoảng này thì vẫn đăng nhập; lâu hơn thì cần nhập mật khẩu lại.';

  @override
  String get settingsAutoLockImmediately => 'Ngay lập tức';

  @override
  String get settingsAutoLockNever => 'Không bao giờ';

  @override
  String settingsAutoLockSeconds(int n) {
    return '$n giây';
  }

  @override
  String get settingsAutoLock30Seconds => '30 giây';

  @override
  String get settingsAutoLock1Minute => '1 phút';

  @override
  String get settingsAutoLock2MinutesDefault => '2 phút (mặc định)';

  @override
  String get settingsAutoLock5Minutes => '5 phút';

  @override
  String get settingsAutoLock15Minutes => '15 phút';

  @override
  String get settingsAutoLock1Hour => '1 giờ';

  @override
  String get settingsLockAppTitle => 'Khoá ứng dụng';

  @override
  String get settingsLockAppBody =>
      'Xoá seed trong bộ nhớ và yêu cầu mật khẩu lại';

  @override
  String get settingsLockConfirmTitle => 'Khoá ứng dụng?';

  @override
  String get settingsLockConfirmBody =>
      'Bạn sẽ cần nhập mật khẩu để mở khoá. Đồng bộ Monero đang chạy sẽ tiếp tục từ nơi nó dừng.';

  @override
  String get settingsLockConfirmAction => 'Khoá';

  @override
  String get settingsDisplayCurrencyTitle => 'Tiền tệ hiển thị';

  @override
  String get settingsDisplayCurrencyDisabled => 'Đã tắt';

  @override
  String get settingsShowFiatValues => 'Hiện giá trị fiat';

  @override
  String get settingsShowFiatValuesBody =>
      'Truy vấn CoinGecko 5 phút một lần. Không gửi PII.';

  @override
  String get settingsExportLogsTitle => 'Xuất log';

  @override
  String get settingsExportLogsBody =>
      '7 ngày qua. Địa chỉ và khoá tự động che.';

  @override
  String get settingsExportLogsEmpty => 'Chưa có log để xuất.';

  @override
  String get settingsExportLogsDialogTitle => 'Log (7 ngày qua)';

  @override
  String get settingsExportLogsCopied => 'Đã sao chép log vào bộ nhớ tạm';

  @override
  String get settingsCloseAction => 'Đóng';

  @override
  String get settingsRestoreAllTitle => 'Khôi phục mọi đồng từ seed kho';

  @override
  String get settingsRestoreAllBody =>
      'Một chạm để dẫn xuất ví cho mọi đồng từ seed 12/24-từ hiện có của bạn.';

  @override
  String get settingsCustomRpcTitle => 'Endpoint RPC tuỳ chỉnh';

  @override
  String get settingsCustomRpcBody =>
      'Trỏ BTC/LTC/BCH/ETH/POL/SOL/TRX sang nút của bạn.';

  @override
  String get settingsUpdateTitle => 'Kiểm tra cập nhật';

  @override
  String get settingsUpdateChecking => 'Đang kiểm tra GitHub…';

  @override
  String get settingsUpdateTapToCheck => 'Nhấn để kiểm tra';

  @override
  String get settingsUpdateFailedFallback => 'Kiểm tra thất bại';

  @override
  String settingsUpdateAvailable(String ago) {
    return 'Có bản cập nhật — phát hành $ago. Nhấn để tải.';
  }

  @override
  String get settingsUpdateDebugBuild =>
      'Bản debug — đã tắt kiểm tra phiên bản. Nhấn để thử lại.';

  @override
  String get settingsUpdateUpToDate => 'Đã mới nhất · vừa kiểm tra';

  @override
  String get settingsAboutTitle => 'Về PeekWallet';

  @override
  String get settingsAboutBody => 'Phiên bản, giấy phép, mã nguồn';

  @override
  String get addWalletChooseCoin => 'Chọn đồng';

  @override
  String addWalletTitle(String coin) {
    return 'Thêm ví $coin';
  }

  @override
  String get addWalletCreateTitle => 'Tạo ví mới';

  @override
  String get addWalletCreateBody =>
      'Sinh cụm từ seed mới. Bất kỳ ai có cụm từ này đều có thể chi ví — hãy ghi ra giấy.';

  @override
  String get addWalletRestoreSeedTitle => 'Khôi phục từ seed';

  @override
  String get addWalletRestoreSeedBody =>
      'Dùng cụm từ khôi phục bạn đã có (BIP39 12/24 từ, Monero 25 từ, hoặc Polyseed 14 từ).';

  @override
  String get addWalletRestoreKeysTitle => 'Khôi phục từ khoá';

  @override
  String get addWalletRestoreKeysBody =>
      'Địa chỉ + khoá chi tiêu riêng + khoá xem riêng. Dùng khi bạn có khoá nhưng không có seed.';

  @override
  String get addWalletFormatNew => 'Định dạng seed mới';

  @override
  String get addWalletFormatRestore => 'Định dạng khôi phục';

  @override
  String get addWalletFormatBip39Hint =>
      'Cụm từ BIP39 — định dạng tiêu chuẩn 12/24 từ mọi ví hiện đại dùng. Trezor, Ledger. Phổ quát cho nhiều đồng.';

  @override
  String get addWalletFormatMoneroLegacyHint =>
      'Seed kiểu electrum gốc của Monero. Tương thích trực tiếp với Cake, Feather, và Monero GUI.';

  @override
  String get addWalletFormatPolyseedHint =>
      'Chuẩn Monero mới hơn — 14 từ. Đã bao gồm restore height.';

  @override
  String get addWalletFormatKeysOnlyHint =>
      'Khoá chi tiêu + khoá xem + địa chỉ. Không có từ.';

  @override
  String get addWalletVaultLocked => 'Két bị khoá — mở khoá lại và thử tiếp.';

  @override
  String addWalletGenerateHeader(String format) {
    return 'Sinh $format';
  }

  @override
  String get addWalletGenerateBody =>
      'Khi bạn nhấn Sinh, các từ sẽ xuất hiện một lần. Hãy ghi ra giấy trước khi tiếp tục. Bất cứ ai có những từ này có thể rút sạch ví.';

  @override
  String get addWalletGenerateAction => 'Sinh seed';

  @override
  String get addWalletWriteThisDown => 'Ghi lại các từ này';

  @override
  String get addWalletWordsWarning =>
      'Những từ này CHÍNH LÀ ví. Bất cứ ai có chúng đều có thể tiêu.';

  @override
  String get addWalletCopyClipboardClears =>
      'Đã sao chép — bộ nhớ tạm tự xoá sau 30 s';

  @override
  String get addWalletCopyPhraseAction => 'Sao chép cụm từ';

  @override
  String get addWalletNameLabel => 'Tên ví (chỉ bạn thấy)';

  @override
  String get addWalletNameHint => 'ví dụ \"Monero chính\"';

  @override
  String get addWalletSavedConfirm => 'Đã lưu các từ — thêm ví';

  @override
  String addWalletRestoreTitle(String format) {
    return 'Khôi phục $format';
  }

  @override
  String get addWalletRestoreNameLabel => 'Tên ví';

  @override
  String get addWalletRestoreNameHint => 'ví dụ \"Nhập từ Cake\"';

  @override
  String get addWalletRecoveryPhraseLabel => 'Cụm từ khôi phục';

  @override
  String get addWalletSeedWordsLabel => 'Từ seed';

  @override
  String get addWalletPassphraseLabel => 'Passphrase BIP39 (từ 25) — tuỳ chọn';

  @override
  String get addWalletPassphraseHint => 'Bỏ trống nếu không dùng';

  @override
  String get addWalletPassphraseWarning =>
      'Nếu ví nguồn có passphrase, bạn PHẢI nhập — nếu không sẽ ra ví hoàn toàn khác.';

  @override
  String get addWalletSeedOffsetLabel => 'Seed offset — tuỳ chọn';

  @override
  String get addWalletSeedOffsetHint => 'Bỏ trống nếu seed không mã hoá';

  @override
  String get addWalletRestoreHeightLabel => 'Restore height — tuỳ chọn';

  @override
  String get addWalletRestoreHeightHint => 'Số block bắt đầu quét';

  @override
  String get addWalletRestoreHeightBody =>
      'Thấp = kỹ hơn nhưng sync chậm; cao = nhanh hơn nhưng có thể bỏ qua biên lai cũ.';

  @override
  String get addWalletRestoreAction => 'Khôi phục ví';

  @override
  String get addWalletKeysRestoreTitle => 'Khôi phục từ khoá';

  @override
  String get addWalletPrimaryAddressLabel => 'Địa chỉ chính';

  @override
  String get addWalletSpendKeyLabel => 'Khoá chi tiêu riêng (hex)';

  @override
  String get addWalletViewKeyLabel => 'Khoá xem riêng (hex)';

  @override
  String get addWalletKeysRestoreHeightLabel => 'Restore height';

  @override
  String get addWalletKeysRestoreHeightHint =>
      'Số block — sớm hơn bao quát biên lai cũ hơn';

  @override
  String get addWalletScanAddressTitle => 'Quét địa chỉ';

  @override
  String get addWalletConfirmPasswordTitle => 'Xác nhận mật khẩu';

  @override
  String get addWalletAppPasswordLabel => 'Mật khẩu ứng dụng';

  @override
  String lockTryAgainIn(String duration) {
    return 'Thử lại sau $duration.';
  }

  @override
  String get welcomeTagline =>
      'Ví tự lưu trữ cho BTC, ETH, XMR và nhiều hơn nữa.';

  @override
  String get welcomeCreateAction => 'Tạo ví mới';

  @override
  String get welcomeImportAction => 'Tôi đã có cụm từ khôi phục';

  @override
  String get welcomeBackupWarning =>
      'Cụm từ khôi phục 12 từ là bản sao duy nhất. Bất kỳ ai có nó đều có thể lấy tiền của bạn.';

  @override
  String get welcomeDisclaimerAction => 'Đọc tuyên bố miễn trừ trách nhiệm';

  @override
  String get welcomeDisclaimerTitle => 'Tuyên bố';

  @override
  String get welcomeCopiedToast => 'Đã sao chép';

  @override
  String get welcomeCopyTextAction => 'Sao chép văn bản';

  @override
  String get welcomeIUnderstandAction => 'Tôi hiểu';

  @override
  String get revealSeedTitle => 'Hiện cụm từ khôi phục';

  @override
  String get revealSeedWarning =>
      'Bạn sắp hiển thị cụm từ seed và khoá Monero. Bất kỳ ai nhìn thấy đều có thể lấy tiền của bạn — đảm bảo không ai nhìn vào màn hình và bạn không đang chia sẻ màn hình.';

  @override
  String get revealSeedPasswordPrompt => 'Nhập mật khẩu ứng dụng để tiếp tục.';

  @override
  String get revealSeedRevealAction => 'Hiển thị';

  @override
  String get revealSeedBip39Section => 'Cụm từ khôi phục BIP39';

  @override
  String get revealSeedPassphraseSection => 'Passphrase BIP39 (từ 25)';

  @override
  String get revealSeedXmrAddressSection => 'Địa chỉ chính Monero';

  @override
  String get revealSeedXmrSpendSection => 'Khoá chi tiêu riêng Monero';

  @override
  String get revealSeedXmrViewSection => 'Khoá xem riêng Monero';

  @override
  String get revealSeedCopyPhrase => 'Sao chép cụm từ';

  @override
  String get revealSeedCopyPassphrase => 'Sao chép passphrase';

  @override
  String get revealSeedCopyAddress => 'Sao chép địa chỉ';

  @override
  String get revealSeedCopySpendKey => 'Sao chép khoá chi tiêu';

  @override
  String get revealSeedCopyViewKey => 'Sao chép khoá xem';

  @override
  String get revealSeedRestoreHint =>
      'Bạn có thể khôi phục ví này trong Cake / Feather / Monero GUI bằng \"Khôi phục từ khoá\" với địa chỉ + khoá xem + khoá chi tiêu ở trên (hoặc \"Khôi phục từ seed\" với cụm từ BIP39 trong bất kỳ ví nào tương thích BIP39).';

  @override
  String get revealSeedCopiedSensitive =>
      'Đã sao chép — bộ nhớ tạm tự xoá sau 30 s';

  @override
  String get revealSeedCopiedPlain => 'Đã sao chép';

  @override
  String get aboutScreenTitle => 'Giới thiệu';

  @override
  String aboutVersionLine(String version, String build) {
    return 'v$version (build $build)';
  }

  @override
  String get aboutAppVersion => 'Phiên bản ứng dụng';

  @override
  String get aboutBuildNumber => 'Số build';

  @override
  String get aboutPackage => 'Package';

  @override
  String get aboutBuildSignature => 'Chữ ký build';

  @override
  String get aboutSourceSection => 'Mã nguồn';

  @override
  String get aboutLegalSection => 'Pháp lý';

  @override
  String get aboutGithubRepo => 'Kho GitHub';

  @override
  String get aboutLicenseLink => 'Giấy phép (GPL-3.0-or-later)';

  @override
  String get aboutDisclaimerLink => 'Tuyên bố (không bảo hành)';

  @override
  String get aboutSecurityModelLink => 'Mô hình bảo mật';

  @override
  String get aboutFreeSoftwareBody =>
      'PeekWallet là phần mềm tự do, mã nguồn mở. Mọi người có thể đọc mã, tự build và xác minh binary trên /releases khớp với mã công khai (khả năng tái hiện được theo dõi trong lộ trình).';

  @override
  String get aboutUrlCopiedToast =>
      'URL đã sao chép — mở trên trình duyệt của bạn';

  @override
  String get addressBookTitle => 'Sổ địa chỉ';

  @override
  String get addressBookPickerTitle => 'Chọn người nhận';

  @override
  String get addressBookAddTooltip => 'Thêm mục';

  @override
  String get addressBookEmptyTitle => 'Chưa có địa chỉ đã lưu';

  @override
  String get addressBookEmptyBodyPicker => 'Lưu người nhận bạn sắp gửi.';

  @override
  String get addressBookEmptyBody =>
      'Lưu địa chỉ của những người bạn hay gửi để không phải dán lại mỗi lần.';

  @override
  String get addressBookAddAction => 'Thêm mục';

  @override
  String get addressBookErrorLabelEmpty => 'Nhãn không được trống.';

  @override
  String get addressBookErrorAddressEmpty => 'Địa chỉ không được trống.';

  @override
  String get addressBookDeleteTitle => 'Xoá mục?';

  @override
  String get addressBookDeleteBody =>
      'Địa chỉ không bị ảnh hưởng — chỉ nhãn / ghi chú đã lưu này bị xoá.';

  @override
  String get addressBookDeleteAction => 'Xoá';

  @override
  String get addressBookEditTitle => 'Sửa địa chỉ';

  @override
  String get addressBookAddTitle => 'Thêm địa chỉ';

  @override
  String get addressBookDeleteTooltip => 'Xoá';

  @override
  String get addressBookLabelField => 'Nhãn';

  @override
  String get addressBookAddressField => 'Địa chỉ';

  @override
  String get addressBookAddressLocked =>
      'Địa chỉ không sửa được — xoá rồi thêm lại để đổi.';

  @override
  String get addressBookScanTooltip => 'Quét';

  @override
  String get addressBookPasteTooltip => 'Dán';

  @override
  String get addressBookNotesField => 'Ghi chú (tuỳ chọn)';

  @override
  String get addressBookNotesHint => 'Văn bản tự do — chỉ lưu cục bộ.';

  @override
  String get addressBookSaveChanges => 'Lưu thay đổi';

  @override
  String get addressBookAddToBook => 'Thêm vào sổ';

  @override
  String get qrScanTitle => 'Quét QR';

  @override
  String get qrScanTorchTooltip => 'Đèn pin';

  @override
  String qrScanCameraError(String code) {
    return 'Lỗi camera: $code';
  }

  @override
  String get qrScanPermissionDenied => 'Bị từ chối quyền camera';

  @override
  String get qrScanPermissionBody =>
      'PeekWallet cần quyền camera để quét mã QR. Camera chỉ dùng khi màn hình này mở và chỉ đọc payload QR.';

  @override
  String get qrScanTryAgain => 'Thử lại';

  @override
  String get qrScanOpenSettings => 'Mở cài đặt ứng dụng';

  @override
  String get qrScanCenterHint => 'Đặt mã QR vào giữa khung';

  @override
  String get rpcResetTitle => 'Đặt lại tất cả override?';

  @override
  String get rpcResetBody =>
      'Mỗi chuỗi sẽ về endpoint mặc định công khai. Bạn có thể thêm override lại bất cứ lúc nào.';

  @override
  String get rpcResetAction => 'Đặt lại';

  @override
  String get rpcScreenTitle => 'Endpoint RPC tuỳ chỉnh';

  @override
  String get rpcResetAllTooltip => 'Đặt lại tất cả';

  @override
  String get rpcIntroBody =>
      'Trỏ mỗi chuỗi tới nút riêng của bạn thay vì mặc định công khai. Để trống thì giữ mặc định.';

  @override
  String rpcDefaultHint(String hint) {
    return 'Mặc định: $hint';
  }

  @override
  String get rpcSaveAction => 'Lưu';

  @override
  String get rpcPrivacyNotesBody =>
      'Lưu ý quyền riêng tư:\n• Mặc định công khai nhìn thấy địa chỉ IP của bạn và những địa chỉ bạn hỏi. Chạy nút riêng hoặc proxy qua VPN / LAN qua Tailscale.\n• Endpoint RPC tuỳ chỉnh sẽ đi thẳng tới URL bạn nhập — mạng của bạn thấy đích đến. Chọn nhà cung cấp đáng tin cậy.';

  @override
  String get restoreAllTitle => 'Khôi phục mọi đồng từ kho';

  @override
  String get restoreAllIntro =>
      'Thêm ví cho từng đồng được hỗ trợ, dẫn xuất từ seed 12/24-từ kho hiện có của bạn.';

  @override
  String get restoreAllNote =>
      'Ví đã có sẽ bỏ qua (không trùng). Monero không bao gồm — nó có định dạng seed riêng và được khôi phục qua thiết lập riêng.';

  @override
  String get restoreAllAction => 'Khôi phục tất cả từ seed kho';

  @override
  String get restoreAllVaultLocked => 'Két đang khoá. Mở khoá và thử lại.';

  @override
  String restoreAllHasWallet(String symbol) {
    return 'Đã có ví $symbol — bỏ qua';
  }

  @override
  String get restoreAllWillDerive => 'Sẽ dẫn xuất từ seed BIP39 của kho';

  @override
  String showSeedTitle(String name) {
    return 'Cụm từ khôi phục · $name';
  }

  @override
  String get showSeedPasswordPrompt =>
      'Nhập mật khẩu ứng dụng để xem cụm từ khôi phục của ví này.';

  @override
  String get showSeedPasswordLabel => 'Mật khẩu ứng dụng';

  @override
  String get showSeedRevealAction => 'Hiển thị';

  @override
  String get showSeedRecoveryPhrase => 'Cụm từ khôi phục';

  @override
  String get showSeedCopyPhrase => 'Sao chép cụm từ';

  @override
  String get showSeedCopyClipboardClears =>
      'Đã sao chép — bộ nhớ tạm tự xoá sau 30s';

  @override
  String get showSeedPassphraseSection => 'Passphrase (từ 25)';

  @override
  String get showSeedSeedOffsetSection => 'Seed offset';

  @override
  String get showSeedAddressLabel => 'Địa chỉ';

  @override
  String get showSeedViewKeyLabel => 'Khoá xem';

  @override
  String get showSeedSpendKeyLabel => 'Khoá chi tiêu';

  @override
  String get showSeedCopySpendKey => 'Sao chép khoá chi tiêu';

  @override
  String showSeedStorageFooter(String format, String coin) {
    return 'Lưu trữ: $format. Đồng: $coin.';
  }

  @override
  String get showSeedWriteDownWarning =>
      'Ghi ra giấy và cất nơi an toàn. Bất cứ ai có cụm từ này đều kiểm soát toàn bộ ví. Đừng chụp màn hình — FLAG_SECURE cũng chặn nó.';

  @override
  String get showSeedKeysOnlyDisplay => 'Chỉ khoá';

  @override
  String get walletMenuShowSeed => 'Hiện cụm từ khôi phục';

  @override
  String get walletMenuShowSeedBody =>
      'Sao lưu riêng, độc lập với seed của két.';

  @override
  String get walletMenuRename => 'Đổi tên';

  @override
  String get walletMenuRenameTitle => 'Đổi tên ví';

  @override
  String walletMenuDeleteTitle(String name) {
    return 'Xoá $name?';
  }

  @override
  String get walletMenuDeleteBody =>
      'Ví trên chuỗi không bị ảnh hưởng — bất kỳ ai có seed vẫn có thể khôi phục về sau. Chỉ bản ghi trên thiết bị này bị xoá.';

  @override
  String get cwSeedTitle => 'Cụm từ khôi phục';

  @override
  String get cwConfirmTitle => 'Xác nhận cụm từ';

  @override
  String get cwPasswordTitle => 'Đặt mật khẩu';

  @override
  String get cwSeedWarning =>
      'Hãy ghi 12 từ này ra giấy và cất nơi an toàn. Bất kỳ ai có cụm từ này đều có thể lấy tiền của bạn. Đừng bao giờ nhập chúng trên một trang web.';

  @override
  String get cwIveWrittenItDown => 'Tôi đã ghi lại';

  @override
  String get cwConfirmBody =>
      'Nhập các từ được yêu cầu để xác nhận bạn đã lưu cụm từ.';

  @override
  String get cwWordPlaceholderHint => 'Chữ thường, không khoảng trắng';

  @override
  String cwWordNumberLabel(int n) {
    return 'Từ #$n';
  }

  @override
  String get cwPasswordBody =>
      'Mật khẩu này mã hoá ví của bạn trên thiết bị này. Bạn sẽ cần nhập mỗi khi mở khoá.';

  @override
  String get cwPasswordMinLabel => 'Mật khẩu (tối thiểu 8 ký tự)';

  @override
  String get cwConfirmPasswordLabel => 'Xác nhận mật khẩu';

  @override
  String get cwPasswordTooShort => 'Mật khẩu phải có ít nhất 8 ký tự.';

  @override
  String get cwPasswordsDontMatch => 'Mật khẩu không khớp.';

  @override
  String get cwCreateWalletAction => 'Tạo ví';

  @override
  String get cwCopyPhrase => 'Sao chép cụm từ';

  @override
  String get cwCopiedClipboardAutoClear =>
      'Đã sao chép — bộ nhớ tạm tự xoá sau 30 giây';

  @override
  String get iwScreenTitle => 'Nhập ví';

  @override
  String get iwIntro =>
      'Dán cụm từ khôi phục BIP39 hiện có (12 hoặc 24 từ). Cùng định dạng với vault-wallet.';

  @override
  String get iwRecoveryPhraseLabel => 'Cụm từ khôi phục';

  @override
  String get iwPhraseHint => 'word1 word2 word3 ...';

  @override
  String get iwPassphraseOptionalLabel =>
      'Passphrase BIP39 (từ thứ 25) — tuỳ chọn';

  @override
  String get iwPassphraseHintBlank => 'Bỏ trống nếu bạn không đặt';

  @override
  String get iwPassphraseWarning =>
      'Nếu bạn đã dùng passphrase BIP39 trong vault-wallet (hoặc ví khác) bạn PHẢI nhập tại đây — không có nó, các địa chỉ được nhập sẽ không khớp và số dư sẽ hiển thị bằng không.';

  @override
  String get iwAppPasswordMinLabel => 'Mật khẩu ứng dụng (tối thiểu 8 ký tự)';

  @override
  String get iwConfirmAppPasswordLabel => 'Xác nhận mật khẩu ứng dụng';

  @override
  String get iwErrorBadWordCount =>
      'Nhập cụm từ khôi phục 12 hoặc 24 từ của bạn.';

  @override
  String get iwErrorBip39Checksum =>
      'Cụm từ khôi phục không hợp lệ (BIP39 checksum thất bại).';

  @override
  String get iwErrorAppPasswordTooShort =>
      'Mật khẩu ứng dụng phải có ít nhất 8 ký tự.';

  @override
  String get iwImportAction => 'Nhập ví';

  @override
  String get xmrScreenUnlockTitle => 'Mở khoá ví';

  @override
  String get xmrScreenUnlockAction => 'Mở';

  @override
  String get xmrScreenErrLocked => 'Ví đang khoá';

  @override
  String xmrScreenErrAddressDerivation(String error) {
    return 'Dẫn xuất địa chỉ thất bại: $error';
  }

  @override
  String get xmrScreenErrVaultLocked => 'Két đang khoá — không có mật khẩu ví';

  @override
  String get xmrScreenErrPasswordRequired => 'Cần mật khẩu để mở ví này';

  @override
  String xmrScreenErrCouldNotOpen(String error) {
    return 'Không thể mở ví: $error';
  }

  @override
  String xmrScreenErrUnknownCoin(String coin) {
    return 'Đồng không xác định: $coin';
  }

  @override
  String xmrScreenBootStage(String stage) {
    return 'Khởi động: $stage';
  }

  @override
  String get xmrScreenConnectingDaemon => 'Đang kết nối daemon…';

  @override
  String xmrScreenSyncingPct(int pct) {
    return 'Đang đồng bộ $pct%';
  }

  @override
  String xmrScreenSyncedAtHeight(String h) {
    return 'Đã đồng bộ · chiều cao $h';
  }

  @override
  String get xmrScreenSynced => 'Đã đồng bộ';

  @override
  String xmrScreenDaemonError(String error) {
    return 'Daemon: $error';
  }

  @override
  String xmrScreenEngineError(String error) {
    return 'Engine: $error';
  }

  @override
  String get xmrScreenBootingWallet => 'Đang khởi động ví…';

  @override
  String get xmrScreenResetTitle => 'Đặt lại tệp ví?';

  @override
  String get xmrScreenResetBody =>
      'Thao tác này xoá tệp ví trên đĩa và tạo lại từ seed đã lưu. Bộ nhớ đệm đồng bộ chuỗi sẽ mất nên ví cần quét lại từ restore height của bạn (có thể mất một lúc). Seed KHÔNG bị động đến — tiền vẫn an toàn.\n\nDùng tính năng này nếu bạn kẹt với lỗi \"sai mật khẩu\" lặp đi lặp lại.';

  @override
  String get xmrScreenResetAction => 'Đặt lại & quét lại';

  @override
  String get xmrScreenResetAndRescanFromSeed => 'Đặt lại & quét lại từ seed';

  @override
  String get xmrScreenActivity => 'Hoạt động';

  @override
  String get xmrScreenWalletStillSyncing =>
      'Ví vẫn đang đồng bộ — hoạt động mới sẽ xuất hiện khi đã theo kịp đỉnh chuỗi.';

  @override
  String get xmrScreenAddressCopied => 'Đã sao chép địa chỉ';

  @override
  String get xmrScreenCopyAddress => 'Sao chép địa chỉ';

  @override
  String get xmrScreenTxStatusFailed => 'Thất bại';

  @override
  String get xmrScreenTxStatusPending => 'Đang chờ';

  @override
  String get xmrScreenTxStatusConfirmed => 'Đã xác nhận';

  @override
  String get xmrScreenDirIncoming => 'Nhận vào';

  @override
  String get xmrScreenDirOutgoing => 'Gửi đi';

  @override
  String get xmrScreenTxAmount => 'Số tiền';

  @override
  String get xmrScreenTxFee => 'Phí';

  @override
  String get xmrScreenTxDate => 'Ngày';

  @override
  String get xmrScreenTxBlockHeight => 'Chiều cao khối';

  @override
  String get xmrScreenTxConfirmations => 'Số xác nhận';

  @override
  String get xmrScreenTxStatus => 'Trạng thái';

  @override
  String get xmrScreenTxPaymentId => 'Payment ID';

  @override
  String get xmrScreenTxNote => 'Ghi chú';

  @override
  String get xmrScreenTxAdd => 'Thêm';

  @override
  String get xmrScreenTxEdit => 'Sửa';

  @override
  String get xmrScreenTxId => 'TX ID';

  @override
  String get xmrScreenTxIdCopied => 'Đã sao chép TX ID';

  @override
  String get xmrScreenCopy => 'Sao chép';

  @override
  String get xmrScreenExplorer => 'Trình duyệt';

  @override
  String get xmrScreenCouldNotOpenBrowser => 'Không thể mở trình duyệt';

  @override
  String get xmrScreenTxNoteTitle => 'Ghi chú giao dịch';

  @override
  String get xmrScreenTxNoteHint => 'Văn bản tự do — chỉ bạn đọc được.';

  @override
  String get xmrScreenClear => 'Xoá';

  @override
  String get xmrScreenNoteSaved => 'Đã lưu ghi chú';

  @override
  String get xmrScreenNoteCleared => 'Đã xoá ghi chú';

  @override
  String xmrScreenCouldNotSaveNote(String error) {
    return 'Không thể lưu ghi chú: $error';
  }

  @override
  String get xmrScreenLabelPrimary => 'Chính';

  @override
  String xmrScreenLabelSubaddress(int index) {
    return 'Gán nhãn subaddress #$index';
  }

  @override
  String xmrScreenCouldNotSaveLabel(String error) {
    return 'Không thể lưu nhãn: $error';
  }

  @override
  String get xmrScreenReceiveTitle => 'Nhận XMR';

  @override
  String get xmrScreenSubaddrUnavailable =>
      'Subaddress không khả dụng cho đến khi ví hoàn tất khởi động.';

  @override
  String get xmrScreenSubaddrSectionTitle => 'Subaddress';

  @override
  String get xmrScreenSubaddrNew => 'Mới';

  @override
  String get xmrScreenSubaddrBody =>
      'Sinh một địa chỉ mới cho mỗi người trả tiền để người quan sát không thể liên kết hai khoản thanh toán với cùng một ví. Tất cả đều trỏ về cùng số dư.';

  @override
  String get xmrScreenEditLabelTooltip => 'Sửa nhãn';

  @override
  String get xmrScreenAppPasswordLabel => 'Mật khẩu ứng dụng';

  @override
  String xmrScreenSyncingPctBehind(int pct, int behind) {
    return 'Đang đồng bộ $pct% · còn $behind khối';
  }

  @override
  String xmrScreenConfirmationsShort(int n) {
    return '$n xác nhận';
  }

  @override
  String get xmrScreenNoNote => '— Không có ghi chú —';

  @override
  String get xmrScreenSubaddrLabelHint =>
      'ví dụ \"Thanh toán khách hàng\", \"Việc tay trái\"';

  @override
  String get xmrScreenEngineLoaded => '✓ Đã tải engine monero_c gốc';

  @override
  String xmrScreenEngineNotLoaded(String error) {
    return '✗ Engine chưa tải: $error';
  }

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
