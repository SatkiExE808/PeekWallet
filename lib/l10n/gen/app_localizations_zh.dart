// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'PeekWallet';

  @override
  String get lockScreenSubtitle => '輸入密碼以解鎖';

  @override
  String get lockPasswordHint => '密碼';

  @override
  String get lockUnlock => '解鎖';

  @override
  String get lockUseBiometric => '使用生物辨識';

  @override
  String get lockTooManyAttempts => '錯誤次數過多';

  @override
  String get lockTimerWarning => '鎖機或重啟程式不會重置倒數計時 — 這是刻意設計。';

  @override
  String get homeTotalBalance => '總資產';

  @override
  String homeSyncedCount(int counted, int total) {
    return '$counted / $total 已同步';
  }

  @override
  String homeAcrossWallets(int count) {
    return '共 $count 個錢包';
  }

  @override
  String get homeEmptyTitle => '尚未有錢包';

  @override
  String get homeEmptyBody => '建立新錢包或使用助記詞還原來開始。';

  @override
  String get homeAddWallet => '新增錢包';

  @override
  String get actionReceive => '接收';

  @override
  String get actionSend => '傳送';

  @override
  String get actionBack => '返回';

  @override
  String get actionCopy => '複製';

  @override
  String get actionShare => '分享';

  @override
  String get actionExplorer => '瀏覽器';

  @override
  String get actionSending => '傳送中…';

  @override
  String receiveTitle(String coinId) {
    return '接收 $coinId';
  }

  @override
  String get receiveAddressLabel => '您的地址';

  @override
  String get receiveAddressCopied => '地址已複製';

  @override
  String balanceCached(String ago) {
    return '快取 · $ago前';
  }

  @override
  String get txDirectionIncoming => '收入';

  @override
  String get txDirectionOutgoing => '支出';

  @override
  String get txStatusConfirmed => '已確認';

  @override
  String get txStatusPending => '待確認';

  @override
  String get txStatusFailed => '失敗';

  @override
  String get txStatusInMempool => '在記憶池中';

  @override
  String get txCopiedToClipboard => '已複製到剪貼簿';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appName => 'PeekWallet';

  @override
  String get lockScreenSubtitle => '輸入密碼以解鎖';

  @override
  String get lockPasswordHint => '密碼';

  @override
  String get lockUnlock => '解鎖';

  @override
  String get lockUseBiometric => '使用生物辨識';

  @override
  String get lockTooManyAttempts => '錯誤次數過多';

  @override
  String get lockTimerWarning => '鎖機或重啟程式不會重置倒數計時 — 這是刻意設計。';

  @override
  String get homeTotalBalance => '總資產';

  @override
  String homeSyncedCount(int counted, int total) {
    return '$counted / $total 已同步';
  }

  @override
  String homeAcrossWallets(int count) {
    return '共 $count 個錢包';
  }

  @override
  String get homeEmptyTitle => '尚未有錢包';

  @override
  String get homeEmptyBody => '建立新錢包或使用助記詞還原來開始。';

  @override
  String get homeAddWallet => '新增錢包';

  @override
  String get actionReceive => '接收';

  @override
  String get actionSend => '傳送';

  @override
  String get actionBack => '返回';

  @override
  String get actionCopy => '複製';

  @override
  String get actionShare => '分享';

  @override
  String get actionExplorer => '瀏覽器';

  @override
  String get actionSending => '傳送中…';

  @override
  String receiveTitle(String coinId) {
    return '接收 $coinId';
  }

  @override
  String get receiveAddressLabel => '您的地址';

  @override
  String get receiveAddressCopied => '地址已複製';

  @override
  String balanceCached(String ago) {
    return '快取 · $ago前';
  }

  @override
  String get txDirectionIncoming => '收入';

  @override
  String get txDirectionOutgoing => '支出';

  @override
  String get txStatusConfirmed => '已確認';

  @override
  String get txStatusPending => '待確認';

  @override
  String get txStatusFailed => '失敗';

  @override
  String get txStatusInMempool => '在記憶池中';

  @override
  String get txCopiedToClipboard => '已複製到剪貼簿';
}
