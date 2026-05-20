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
