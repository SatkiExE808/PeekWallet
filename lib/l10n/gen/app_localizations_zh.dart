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
  String get walletsTitle => '我的錢包';

  @override
  String get walletsRefreshTooltip => '重新整理餘額';

  @override
  String get walletsAddTooltip => '新增錢包';

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
  String get actionContinue => '繼續';

  @override
  String get actionCancel => '取消';

  @override
  String get actionSave => '儲存';

  @override
  String get actionDelete => '刪除';

  @override
  String get actionRefresh => '重新整理';

  @override
  String receiveTitle(String coinId) {
    return '接收 $coinId';
  }

  @override
  String get receiveAddressLabel => '您的地址';

  @override
  String get receiveAddressCopied => '地址已複製';

  @override
  String get receiveCopiedToClipboard => '已複製到剪貼簿';

  @override
  String get receiveCouldNotOpenBrowser => '無法開啟瀏覽器';

  @override
  String coinScreenBalanceLabel(String symbol) {
    return '$symbol 餘額';
  }

  @override
  String get coinScreenActivityTitle => '交易紀錄';

  @override
  String get coinScreenTokensTitle => '代幣';

  @override
  String get coinScreenNoTxYet => '尚未有交易';

  @override
  String coinScreenShareAddressHint(String symbol) {
    return '分享地址以接收 $symbol';
  }

  @override
  String get coinScreenLoading => '載入中…';

  @override
  String get coinScreenRefreshTooltip => '重新整理';

  @override
  String get coinScreenAddTokenLabel => '新增代幣';

  @override
  String balanceCached(String ago) {
    return '快取 · $ago前';
  }

  @override
  String balanceCachedShort(String ago) {
    return '快取 · $ago';
  }

  @override
  String balanceCouldNotOpen(String error) {
    return '無法開啟錢包：$error';
  }

  @override
  String get balanceVaultLocked => '金庫已鎖定。';

  @override
  String get ageJustNow => '剛剛';

  @override
  String ageMinutes(int n) {
    return '$n 分鐘';
  }

  @override
  String ageHours(int n) {
    return '$n 小時';
  }

  @override
  String ageDays(int n) {
    return '$n 天';
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

  @override
  String get txIdLabel => '交易 ID';

  @override
  String get txHashLabel => '雜湊值';

  @override
  String get txSignatureLabel => '簽章';

  @override
  String get txAmountLabel => '淨額';

  @override
  String get txFeeLabel => '手續費';

  @override
  String get txGasFeeLabel => '燃料費';

  @override
  String get txNetworkFeeLabel => '網路費';

  @override
  String get txBlockHeightLabel => '區塊高度';

  @override
  String get txSlotLabel => 'Slot';

  @override
  String get txDateLabel => '日期';

  @override
  String get txTokenLabel => '代幣';

  @override
  String get txCounterpartyLabel => '對方';

  @override
  String get sendFormRecipientLabel => '收款地址';

  @override
  String get sendFormAmountLabel => '金額';

  @override
  String get sendFormMaxButton => '最大';

  @override
  String get sendFormBookTooltip => '從通訊錄選取';

  @override
  String get sendFormScanTooltip => '掃描 QR 碼';

  @override
  String get sendFormPasteTooltip => '從剪貼簿貼上';

  @override
  String get sendFormFeePriorityLabel => '手續費優先順序';

  @override
  String get sendFormAvailableLabel => '可用';

  @override
  String get sendFormConfirmHint => '輸入 SEND 以確認';

  @override
  String get sendFormConfirmPlaceholder => 'SEND';

  @override
  String get sendFormErrorInvalidAmount => '請輸入有效金額';

  @override
  String get sendFormErrorAmountExceedsBalance => '金額加手續費超過餘額';

  @override
  String get sendFormErrorRecipientRequired => '請輸入收款地址';

  @override
  String get sendFormWillBeSentTo => '將傳送至';

  @override
  String get sendFormToLabel => '收款人';

  @override
  String get tronTokensTitle => '代幣 (TRC-20)';

  @override
  String get splTokensTitle => '代幣 (SPL)';

  @override
  String get erc20TokensTitle => '代幣';

  @override
  String experimentalSendWarning(String symbol) {
    return '傳送功能仍為實驗性 — 請以小額測試後再傳送大額 $symbol。';
  }

  @override
  String get erc20EmptyHint =>
      '尚未有代幣 — 將 USDT/USDC/DAI 等代幣傳送至此地址,或點擊「新增代幣」以追蹤其他 ERC-20 合約。';

  @override
  String get ercAddCustomTitle => '新增自訂 ERC-20 代幣';

  @override
  String get ercAddCustomBody => '貼上代幣合約地址,我們會自動讀取符號與小數位數。';

  @override
  String get ercContractLabel => '合約地址';

  @override
  String get ercProbeAction => '查詢';

  @override
  String get ercContractError => '合約必須是 0x 加 40 個十六進位字元';

  @override
  String ercProbingMsg(String prefix) {
    return '正在查詢 $prefix…';
  }

  @override
  String get ercProbeFailedMsg => '無法讀取代幣資料 — 鏈不對或不是 ERC-20?';

  @override
  String ercAddedMsg(String symbol, int decimals) {
    return '已新增 $symbol($decimals 位小數)';
  }
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
  String get walletsTitle => '我的錢包';

  @override
  String get walletsRefreshTooltip => '重新整理餘額';

  @override
  String get walletsAddTooltip => '新增錢包';

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
  String get actionContinue => '繼續';

  @override
  String get actionCancel => '取消';

  @override
  String get actionSave => '儲存';

  @override
  String get actionDelete => '刪除';

  @override
  String get actionRefresh => '重新整理';

  @override
  String receiveTitle(String coinId) {
    return '接收 $coinId';
  }

  @override
  String get receiveAddressLabel => '您的地址';

  @override
  String get receiveAddressCopied => '地址已複製';

  @override
  String get receiveCopiedToClipboard => '已複製到剪貼簿';

  @override
  String get receiveCouldNotOpenBrowser => '無法開啟瀏覽器';

  @override
  String coinScreenBalanceLabel(String symbol) {
    return '$symbol 餘額';
  }

  @override
  String get coinScreenActivityTitle => '交易紀錄';

  @override
  String get coinScreenTokensTitle => '代幣';

  @override
  String get coinScreenNoTxYet => '尚未有交易';

  @override
  String coinScreenShareAddressHint(String symbol) {
    return '分享地址以接收 $symbol';
  }

  @override
  String get coinScreenLoading => '載入中…';

  @override
  String get coinScreenRefreshTooltip => '重新整理';

  @override
  String get coinScreenAddTokenLabel => '新增代幣';

  @override
  String balanceCached(String ago) {
    return '快取 · $ago前';
  }

  @override
  String balanceCachedShort(String ago) {
    return '快取 · $ago';
  }

  @override
  String balanceCouldNotOpen(String error) {
    return '無法開啟錢包：$error';
  }

  @override
  String get balanceVaultLocked => '金庫已鎖定。';

  @override
  String get ageJustNow => '剛剛';

  @override
  String ageMinutes(int n) {
    return '$n 分鐘';
  }

  @override
  String ageHours(int n) {
    return '$n 小時';
  }

  @override
  String ageDays(int n) {
    return '$n 天';
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

  @override
  String get txIdLabel => '交易 ID';

  @override
  String get txHashLabel => '雜湊值';

  @override
  String get txSignatureLabel => '簽章';

  @override
  String get txAmountLabel => '淨額';

  @override
  String get txFeeLabel => '手續費';

  @override
  String get txGasFeeLabel => '燃料費';

  @override
  String get txNetworkFeeLabel => '網路費';

  @override
  String get txBlockHeightLabel => '區塊高度';

  @override
  String get txSlotLabel => 'Slot';

  @override
  String get txDateLabel => '日期';

  @override
  String get txTokenLabel => '代幣';

  @override
  String get txCounterpartyLabel => '對方';

  @override
  String get sendFormRecipientLabel => '收款地址';

  @override
  String get sendFormAmountLabel => '金額';

  @override
  String get sendFormMaxButton => '最大';

  @override
  String get sendFormBookTooltip => '從通訊錄選取';

  @override
  String get sendFormScanTooltip => '掃描 QR 碼';

  @override
  String get sendFormPasteTooltip => '從剪貼簿貼上';

  @override
  String get sendFormFeePriorityLabel => '手續費優先順序';

  @override
  String get sendFormAvailableLabel => '可用';

  @override
  String get sendFormConfirmHint => '輸入 SEND 以確認';

  @override
  String get sendFormConfirmPlaceholder => 'SEND';

  @override
  String get sendFormErrorInvalidAmount => '請輸入有效金額';

  @override
  String get sendFormErrorAmountExceedsBalance => '金額加手續費超過餘額';

  @override
  String get sendFormErrorRecipientRequired => '請輸入收款地址';

  @override
  String get sendFormWillBeSentTo => '將傳送至';

  @override
  String get sendFormToLabel => '收款人';

  @override
  String get tronTokensTitle => '代幣 (TRC-20)';

  @override
  String get splTokensTitle => '代幣 (SPL)';

  @override
  String get erc20TokensTitle => '代幣';

  @override
  String experimentalSendWarning(String symbol) {
    return '傳送功能仍為實驗性 — 請以小額測試後再傳送大額 $symbol。';
  }

  @override
  String get erc20EmptyHint =>
      '尚未有代幣 — 將 USDT/USDC/DAI 等代幣傳送至此地址,或點擊「新增代幣」以追蹤其他 ERC-20 合約。';

  @override
  String get ercAddCustomTitle => '新增自訂 ERC-20 代幣';

  @override
  String get ercAddCustomBody => '貼上代幣合約地址,我們會自動讀取符號與小數位數。';

  @override
  String get ercContractLabel => '合約地址';

  @override
  String get ercProbeAction => '查詢';

  @override
  String get ercContractError => '合約必須是 0x 加 40 個十六進位字元';

  @override
  String ercProbingMsg(String prefix) {
    return '正在查詢 $prefix…';
  }

  @override
  String get ercProbeFailedMsg => '無法讀取代幣資料 — 鏈不對或不是 ERC-20?';

  @override
  String ercAddedMsg(String symbol, int decimals) {
    return '已新增 $symbol($decimals 位小數)';
  }
}
