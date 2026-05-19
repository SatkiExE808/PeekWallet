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
  String receiveTitle(String coinId) {
    return 'Nhận $coinId';
  }

  @override
  String get receiveAddressLabel => 'ĐỊA CHỈ CỦA BẠN';

  @override
  String get receiveAddressCopied => 'Đã sao chép địa chỉ';

  @override
  String balanceCached(String ago) {
    return 'Bộ nhớ đệm · $ago trước';
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
}
