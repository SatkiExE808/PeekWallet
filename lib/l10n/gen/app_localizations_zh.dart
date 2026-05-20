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
  String sendScreenTitle(String coinName) {
    return '傳送 $coinName';
  }

  @override
  String sendScanTitle(String symbol) {
    return '掃描 $symbol 地址';
  }

  @override
  String sendBtcAmountLabel(String symbol) {
    return '金額($symbol 或 sat)';
  }

  @override
  String sendBroadcastSuccess(String prefix) {
    return '已廣播!交易 ID: $prefix…';
  }

  @override
  String get sendBtcLoadingUtxos => '載入 UTXO 中…';

  @override
  String sendBtcUtxoError(String error) {
    return 'UTXO 錯誤:$error';
  }

  @override
  String get sendBtcAvailableHint => '可用 · 僅計算已確認 UTXO';

  @override
  String sendBtcFeeRatesError(String error) {
    return '無法取得手續費率:$error';
  }

  @override
  String get sendBtcLoadingFeeRates => '載入手續費率…';

  @override
  String get sendBtcFinalFeeHint => '最終手續費與找零會在廣播後顯示。一旦提交至網路後即無法撤回。';

  @override
  String get sendBtcExperimentalBody => '傳送已通過 BIP-0143 規範向量測試,但尚未經過端對端審計。';

  @override
  String sendBtcOnlyBech32(String prefix) {
    return '僅支援 bech32 P2WPKH($prefix…)地址';
  }

  @override
  String sendBtcExceedsBalance(int available) {
    return '金額超過已確認餘額($available sat)';
  }

  @override
  String get sendBtcFeeRateLabel => '手續費率';

  @override
  String get sendBtcFeeTierFastest => '最快';

  @override
  String get sendBtcFeeTierHalfHour => '半小時';

  @override
  String get sendBtcFeeTierHour => '一小時';

  @override
  String get sendBtcFeeTierEconomy => '節省';

  @override
  String get sendBtcFeeEtaFastest => '約 10 分鐘';

  @override
  String get sendBtcFeeEtaHalfHour => '約 30 分鐘';

  @override
  String get sendBtcFeeEtaHour => '約 1 小時';

  @override
  String get sendBtcFeeEtaEconomy => '視記憶池而定';

  @override
  String get sendBchRecipientLabel => '收款地址(CashAddr)';

  @override
  String get sendBchExperimentalBody =>
      '傳統 P2PKH 加 SIGHASH_FORKID。BIP143 sighash 已透過 BTC SegWit 規範向量測試;BCH 專屬的 0x41 sighash 位元組及傳統交易封包已單元測試但未經審計。';

  @override
  String get sendBchErrorMustBeCashAddr =>
      '收款人必須為 CashAddr(bitcoincash:q…/p… 或直接 q…/p…)';

  @override
  String get sendBchErrorP2shNotSupported =>
      '目前尚未支援 P2SH BCH 地址(p…) — 本版本只支援 P2KH(q…)。';

  @override
  String get sendBchFinalFeeHint =>
      'BCH 傳統 P2PKH 含 SIGHASH_FORKID。一旦提交後即無法撤回(BCH 不支援 RBF)。';

  @override
  String get sendBchAvailableShort => '可用';

  @override
  String get sendBchNetworkFeeLabel => '網路手續費';

  @override
  String sendBchFeeRateDescription(int rate, int typical) {
    return '$rate sat/byte — 一般單輸入交易約 $typical sat。BCH 手續費極低。';
  }

  @override
  String get sendBchAmountLabel => '金額(BCH 或 sat)';

  @override
  String get sendEthExperimentalBody =>
      'RLP + EIP-1559 sighash + ECDSA 復原已單元測試,但端對端傳送流程尚未審計。';

  @override
  String get sendEthErrorBadAddress => '收款人必須是 0x 前綴加 40 字元十六進位地址';

  @override
  String sendEthErrorExceedsToken(String symbol) {
    return '金額超過 $symbol 餘額';
  }

  @override
  String sendEthErrorNoGas(String symbol) {
    return '沒有 $symbol 可付手續費 — 請先注資至此錢包';
  }

  @override
  String sendEthAmountLabelToken(String symbol) {
    return '金額($symbol 或最小單位)';
  }

  @override
  String sendEthAmountLabelNative(String symbol) {
    return '金額($symbol 或 wei)';
  }

  @override
  String get sendEthMaxFeeLabel => '每單位 gas 上限';

  @override
  String get sendEthPriorityFeeLabel => '優先費';

  @override
  String get sendEthLoadingBalance => '載入餘額中…';

  @override
  String sendEthBalanceError(String error) {
    return '餘額錯誤:$error';
  }

  @override
  String sendEthAvailableForGas(String amount, String symbol) {
    return '可用 · $amount $symbol 可付手續費';
  }

  @override
  String sendEthFeeError(String error) {
    return '手續費資料無法取得:$error';
  }

  @override
  String get sendEthLoadingFee => '載入手續費率…';

  @override
  String get sendEthNetworkFeeHeader => '網路手續費';

  @override
  String get sendEthAutoBadge => '自動';

  @override
  String get sendEthBaseLabel => '基本';

  @override
  String get sendEthTipLabel => '小費';

  @override
  String get sendEthMaxLabel => '上限';

  @override
  String get sendEthFinalFeeHint =>
      '最終手續費取決於上鏈時的網路基礎費。低於上限的部分會退回 — 多付不會真的多花。一旦提交即無法撤回。';

  @override
  String get sendSolExperimentalBody => 'Solana 交易編碼已單元測試,但端對端傳送流程尚未審計。';

  @override
  String get sendSolErrorBadAddress => '地址應為 32-44 個 base58 字元';

  @override
  String get sendSolErrorNoSol => '沒有 SOL 可付手續費 — 請先注入少量 SOL 至此錢包';

  @override
  String sendSolErrorNeedsAtaSol(String symbol) {
    return '收款人尚未有 $symbol 帳戶 — 傳送會建立一個(需額外 ~0.00204 SOL 租金 + 手續費)。';
  }

  @override
  String get sendSolErrorNotEnoughSol => 'SOL 不足以付網路費。';

  @override
  String get sendSolErrorAmountFeeExceeds => '金額加手續費超過餘額';

  @override
  String sendSolAmountLabelToken(String symbol) {
    return '金額($symbol 或最小單位)';
  }

  @override
  String get sendSolAmountLabelNative => '金額(SOL 或 lamport)';

  @override
  String get sendSolAddressHint => 'Solana 地址';

  @override
  String get sendSolNetworkFeeLabel => '網路手續費';

  @override
  String get sendSolAtaRentLabel => 'ATA 租金';

  @override
  String get sendSolTotalOutLabel => 'SOL 總支出';

  @override
  String get sendSolFinalFeeHintNative =>
      'Solana 手續費固定為每個簽章 5000 lamport。一旦提交即無法撤回。';

  @override
  String sendSolFinalFeeHintNewAta(String symbol) {
    return '收款人尚未有 $symbol 帳戶。傳送會為對方建立一個(約 0.00204 SOL 租金,由你支付)。一旦提交即無法撤回。';
  }

  @override
  String get sendTrxExperimentalBody =>
      'Tron 交易由 RPC 建構並於本機簽章。簽章前會驗證 txid 雜湊,但不會解碼 protobuf 內容。';

  @override
  String get sendTrxErrorBadAddress => '收款人必須是 base58 Tron 地址(以 T 開頭,34 字元)';

  @override
  String get sendTrxErrorNoTrx => '沒有 TRX 可付頻寬/能量 — 請先注入 TRX 至此錢包';

  @override
  String get sendTrxRecipientLabel => '收款人(Tron base58)';

  @override
  String sendTrxAmountLabelToken(String symbol) {
    return '金額($symbol 或最小單位)';
  }

  @override
  String get sendTrxAmountLabelNative => '金額(TRX 或 sun)';

  @override
  String get sendTrxBandwidthLabel => '頻寬/能量';

  @override
  String get sendTrxBandwidthToken => '最多約 30 TRX 等值(TRC-20)';

  @override
  String get sendTrxBandwidthNative => '免費配額或約 0.27 TRX';

  @override
  String get sendTrxFinalFeeHint =>
      'Tron 交易由 RPC 節點建構;我們會在本機簽章前重新驗證 txid 雜湊。一旦提交即無法撤回。';

  @override
  String get sendXmrTitle => '傳送 XMR';

  @override
  String get sendXmrScanTitle => '掃描收款地址';

  @override
  String sendXmrAvailable(String amount) {
    return '可用:$amount XMR';
  }

  @override
  String get sendXmrAddRecipient => '新增收款人';

  @override
  String get sendXmrSendAllTitle => '全部傳送';

  @override
  String get sendXmrSendAllBody => '將所有可花費的輸出轉至第一位收款人 — 手續費會自動扣除。';

  @override
  String get sendXmrFeePriorityLabel => '手續費優先順序';

  @override
  String get sendXmrTierSlow => '慢';

  @override
  String get sendXmrTierNormal => '一般';

  @override
  String get sendXmrTierFast => '快';

  @override
  String get sendXmrReviewAction => '檢視傳送';

  @override
  String get sendXmrToLabel => '收款人';

  @override
  String sendXmrToNumbered(int index) {
    return '收款人 #$index';
  }

  @override
  String get sendXmrSubtotalLabel => '小計';

  @override
  String get sendXmrSweepLabel => '傳送(全部)';

  @override
  String get sendXmrNetworkFee => '網路費';

  @override
  String sendXmrSplitWarning(int count) {
    return '此次傳送將拆為 $count 筆子交易發送。';
  }

  @override
  String get sendXmrBroadcastTitle => '交易已廣播';

  @override
  String get sendXmrBroadcastBody => '網路確認後將出現在你的交易紀錄中。';

  @override
  String get sendXmrTxIdLabel => '交易 ID';

  @override
  String get sendXmrTxIdCopied => '交易 ID 已複製';

  @override
  String get sendXmrCopyTxIdAction => '複製交易 ID';

  @override
  String get sendXmrDoneAction => '完成';

  @override
  String get sendXmrRecipientHeader => '收款人';

  @override
  String get sendXmrRemoveTooltip => '移除';

  @override
  String get sendXmrAddressLabel => '收款地址';

  @override
  String get sendXmrAddressBookTooltip => '通訊錄';

  @override
  String get sendXmrPasteTooltip => '貼上';

  @override
  String get sendXmrAmountLabel => '金額(XMR)';

  @override
  String get sendXmrAmountHintSweep => '全部 — 金額自動設定';

  @override
  String sendXmrErrorBadAddress(String tag) {
    return '地址不像是 Monero 格式$tag。';
  }

  @override
  String sendXmrErrorAmountZero(String tag) {
    return '金額必須大於 0$tag。';
  }

  @override
  String get sendXmrErrorExceedsBalance => '總額超過餘額。';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsMoneroNode => 'Monero 節點';

  @override
  String get settingsMoneroNodeBody =>
      'PeekWallet 用來同步的 Monero 守護程式。預設為 Cake Wallet 的公開節點。如需完全隱私,可自架 monerod 並指向自己的節點。';

  @override
  String get settingsDaemonUrlLabel => '節點 URL';

  @override
  String get settingsPasteTooltip => '貼上';

  @override
  String settingsConnectsToPreview(String hostPort, String ssl) {
    return '連線至 $hostPort(ssl=$ssl)';
  }

  @override
  String get settingsMessageBadUrl =>
      '無法解析此 URL。請試試 https://node.example.com:18081';

  @override
  String get settingsMessageSaved => '已儲存。鎖定再解鎖即可切換到新節點。';

  @override
  String settingsMessageReset(String url) {
    return '已重置。下次解鎖將使用 $url。';
  }

  @override
  String get settingsResetToDefault => '重置為預設';

  @override
  String get settingsSectionPublicNodes => '公開節點';

  @override
  String get settingsSectionSecurity => '安全性';

  @override
  String get settingsSectionDisplay => '顯示';

  @override
  String get settingsBiometricUnlock => '生物辨識解鎖';

  @override
  String get settingsBiometricUnlockOn => '使用指紋 / 臉部解鎖';

  @override
  String get settingsBiometricUnlockOff => '無法使用 — 尚未註冊生物辨識';

  @override
  String get settingsBiometricEnableTitle => '啟用生物辨識解鎖';

  @override
  String get settingsBiometricEnableHint => '輸入應用程式密碼以確認';

  @override
  String settingsBiometricEnableFailed(String error) {
    return '無法啟用:$error';
  }

  @override
  String get settingsPasswordLabel => '密碼';

  @override
  String get settingsRevealSeedTitle => '顯示助記詞';

  @override
  String get settingsRevealSeedBody => '查看 BIP39 種子及 Monero 花費/檢視金鑰';

  @override
  String get settingsAddressBookTitle => '通訊錄';

  @override
  String get settingsAddressBookBody => '已儲存的收款人標籤';

  @override
  String get settingsAutoLockTitle => '自動鎖定';

  @override
  String get settingsAutoLockSheetTitle => '切換到背景後自動鎖定';

  @override
  String get settingsAutoLockSheetBody =>
      'PeekWallet 在你使用其他應用程式時可保持解鎖多久。在此期間返回保持登入;超時則需重新輸入密碼。';

  @override
  String get settingsAutoLockImmediately => '立即';

  @override
  String get settingsAutoLockNever => '永不';

  @override
  String settingsAutoLockSeconds(int n) {
    return '$n 秒';
  }

  @override
  String get settingsAutoLock30Seconds => '30 秒';

  @override
  String get settingsAutoLock1Minute => '1 分鐘';

  @override
  String get settingsAutoLock2MinutesDefault => '2 分鐘(預設)';

  @override
  String get settingsAutoLock5Minutes => '5 分鐘';

  @override
  String get settingsAutoLock15Minutes => '15 分鐘';

  @override
  String get settingsAutoLock1Hour => '1 小時';

  @override
  String get settingsLockAppTitle => '鎖定應用程式';

  @override
  String get settingsLockAppBody => '清除記憶體中的種子,需重新輸入密碼';

  @override
  String get settingsLockConfirmTitle => '鎖定應用程式?';

  @override
  String get settingsLockConfirmBody => '需重新輸入密碼以解鎖。任何進行中的 Monero 同步將從中斷處繼續。';

  @override
  String get settingsLockConfirmAction => '鎖定';

  @override
  String get settingsDisplayCurrencyTitle => '顯示幣別';

  @override
  String get settingsDisplayCurrencyDisabled => '已停用';

  @override
  String get settingsShowFiatValues => '顯示法幣值';

  @override
  String get settingsShowFiatValuesBody => '每 5 分鐘輪詢 CoinGecko。不傳送個人識別資訊。';

  @override
  String get settingsExportLogsTitle => '匯出日誌';

  @override
  String get settingsExportLogsBody => '最近 7 天。地址與金鑰會自動遮罩。';

  @override
  String get settingsExportLogsEmpty => '尚無日誌可匯出。';

  @override
  String get settingsExportLogsDialogTitle => '日誌(最近 7 天)';

  @override
  String get settingsExportLogsCopied => '日誌已複製到剪貼簿';

  @override
  String get settingsCloseAction => '關閉';

  @override
  String get settingsRestoreAllTitle => '從金庫種子還原所有幣種';

  @override
  String get settingsRestoreAllBody => '一鍵用既有的 12/24 字種子衍生每種幣的錢包。';

  @override
  String get settingsCustomRpcTitle => '自訂 RPC 端點';

  @override
  String get settingsCustomRpcBody => '將 BTC/LTC/BCH/ETH/POL/SOL/TRX 指向你自己的節點。';

  @override
  String get settingsUpdateTitle => '檢查更新';

  @override
  String get settingsUpdateChecking => '正在查詢 GitHub…';

  @override
  String get settingsUpdateTapToCheck => '點擊以檢查';

  @override
  String get settingsUpdateFailedFallback => '檢查失敗';

  @override
  String settingsUpdateAvailable(String ago) {
    return '有可用更新 — 發佈於 $ago。點擊下載。';
  }

  @override
  String get settingsUpdateDebugBuild => 'Debug 版本 — 已停用版本檢查。點擊重試。';

  @override
  String get settingsUpdateUpToDate => '已是最新版 · 剛剛檢查';

  @override
  String get settingsAboutTitle => '關於 PeekWallet';

  @override
  String get settingsAboutBody => '版本、授權、原始碼';

  @override
  String get addWalletChooseCoin => '選擇幣種';

  @override
  String addWalletTitle(String coin) {
    return '新增 $coin 錢包';
  }

  @override
  String get addWalletCreateTitle => '建立新錢包';

  @override
  String get addWalletCreateBody => '產生全新的助記詞。任何持有此助記詞的人都能花費此錢包 — 請寫在紙上。';

  @override
  String get addWalletRestoreSeedTitle => '從助記詞還原';

  @override
  String get addWalletRestoreSeedBody =>
      '使用既有的助記詞(BIP39 12/24 字、Monero 25 字、Polyseed 14 字)。';

  @override
  String get addWalletRestoreKeysTitle => '從金鑰還原';

  @override
  String get addWalletRestoreKeysBody => '地址 + 私人花費金鑰 + 私人檢視金鑰。當你有金鑰但無助記詞時使用。';

  @override
  String get addWalletFormatNew => '新種子格式';

  @override
  String get addWalletFormatRestore => '還原格式';

  @override
  String get addWalletFormatBip39Hint =>
      'BIP39 助記詞 — 所有現代錢包使用的標準 12/24 字格式。Trezor、Ledger 通用。';

  @override
  String get addWalletFormatMoneroLegacyHint =>
      'Monero 原生 electrum 風格助記詞。可直接與 Cake、Feather、Monero GUI 互通。';

  @override
  String get addWalletFormatPolyseedHint => '新版 Monero 標準 — 14 字。內含還原高度。';

  @override
  String get addWalletFormatKeysOnlyHint => '花費金鑰 + 檢視金鑰 + 地址。沒有助記詞。';

  @override
  String get addWalletVaultLocked => '金庫已鎖定 — 請重新解鎖後再試。';

  @override
  String addWalletGenerateHeader(String format) {
    return '產生 $format';
  }

  @override
  String get addWalletGenerateBody =>
      '點擊「產生」後,助記詞只會顯示一次。請先寫在紙上再繼續。任何持有這些字的人都能轉走此錢包。';

  @override
  String get addWalletGenerateAction => '產生助記詞';

  @override
  String get addWalletWriteThisDown => '請寫下這些字';

  @override
  String get addWalletWordsWarning => '這些字就是錢包。任何人有了就能花費。';

  @override
  String get addWalletCopyClipboardClears => '已複製 — 剪貼簿將於 30 秒後自動清除';

  @override
  String get addWalletCopyPhraseAction => '複製助記詞';

  @override
  String get addWalletNameLabel => '錢包名稱(僅你看得到)';

  @override
  String get addWalletNameHint => '例如「主 Monero」';

  @override
  String get addWalletSavedConfirm => '我已保存助記詞 — 新增錢包';

  @override
  String addWalletRestoreTitle(String format) {
    return '還原 $format';
  }

  @override
  String get addWalletRestoreNameLabel => '錢包名稱';

  @override
  String get addWalletRestoreNameHint => '例如「從 Cake 匯入」';

  @override
  String get addWalletRecoveryPhraseLabel => '助記詞';

  @override
  String get addWalletSeedWordsLabel => '種子字';

  @override
  String get addWalletPassphraseLabel => 'BIP39 通行短語(第 25 字) — 選填';

  @override
  String get addWalletPassphraseHint => '若未使用請留空';

  @override
  String get addWalletPassphraseWarning => '若來源錢包有通行短語,必須輸入 — 否則會得到完全不同的錢包。';

  @override
  String get addWalletSeedOffsetLabel => '種子偏移 — 選填';

  @override
  String get addWalletSeedOffsetHint => '若種子未加密請留空';

  @override
  String get addWalletRestoreHeightLabel => '還原高度 — 選填';

  @override
  String get addWalletRestoreHeightHint => '開始掃描的區塊高度';

  @override
  String get addWalletRestoreHeightBody => '較低 = 較徹底但較慢;較高 = 較快但可能遺漏舊收款。';

  @override
  String get addWalletRestoreAction => '還原錢包';

  @override
  String get addWalletKeysRestoreTitle => '從金鑰還原';

  @override
  String get addWalletPrimaryAddressLabel => '主要地址';

  @override
  String get addWalletSpendKeyLabel => '私人花費金鑰(hex)';

  @override
  String get addWalletViewKeyLabel => '私人檢視金鑰(hex)';

  @override
  String get addWalletKeysRestoreHeightLabel => '還原高度';

  @override
  String get addWalletKeysRestoreHeightHint => '區塊號 — 越早涵蓋越多舊收款';

  @override
  String get addWalletScanAddressTitle => '掃描地址';

  @override
  String get addWalletConfirmPasswordTitle => '確認密碼';

  @override
  String get addWalletAppPasswordLabel => '應用程式密碼';

  @override
  String lockTryAgainIn(String duration) {
    return '請於 $duration 後再試。';
  }

  @override
  String get welcomeTagline => 'BTC、ETH、XMR 等多幣種的自我託管錢包。';

  @override
  String get welcomeCreateAction => '建立新錢包';

  @override
  String get welcomeImportAction => '我已有助記詞';

  @override
  String get welcomeBackupWarning => '你的 12 字助記詞是唯一的備份。任何持有的人都能轉走資金。';

  @override
  String get welcomeDisclaimerAction => '閱讀免責聲明';

  @override
  String get welcomeDisclaimerTitle => '免責聲明';

  @override
  String get welcomeCopiedToast => '已複製';

  @override
  String get welcomeCopyTextAction => '複製文字';

  @override
  String get welcomeIUnderstandAction => '我已了解';

  @override
  String get revealSeedTitle => '顯示助記詞';

  @override
  String get revealSeedWarning =>
      '你即將顯示助記詞和 Monero 金鑰。任何人看到都能轉走資金 — 確保沒人在看你的螢幕,也沒在進行螢幕分享。';

  @override
  String get revealSeedPasswordPrompt => '請輸入應用程式密碼以繼續。';

  @override
  String get revealSeedRevealAction => '顯示';

  @override
  String get revealSeedBip39Section => 'BIP39 助記詞';

  @override
  String get revealSeedPassphraseSection => 'BIP39 通行短語(第 25 字)';

  @override
  String get revealSeedXmrAddressSection => 'Monero 主要地址';

  @override
  String get revealSeedXmrSpendSection => 'Monero 私人花費金鑰';

  @override
  String get revealSeedXmrViewSection => 'Monero 私人檢視金鑰';

  @override
  String get revealSeedCopyPhrase => '複製助記詞';

  @override
  String get revealSeedCopyPassphrase => '複製通行短語';

  @override
  String get revealSeedCopyAddress => '複製地址';

  @override
  String get revealSeedCopySpendKey => '複製花費金鑰';

  @override
  String get revealSeedCopyViewKey => '複製檢視金鑰';

  @override
  String get revealSeedRestoreHint =>
      '你可以在 Cake / Feather / Monero GUI 中用「從金鑰還原」(地址 + 檢視金鑰 + 花費金鑰)還原此錢包,或用 BIP39 助記詞在任何 BIP39 相容錢包中還原。';

  @override
  String get revealSeedCopiedSensitive => '已複製 — 剪貼簿將於 30 秒後自動清除';

  @override
  String get revealSeedCopiedPlain => '已複製';

  @override
  String get aboutScreenTitle => '關於';

  @override
  String aboutVersionLine(String version, String build) {
    return 'v$version(build $build)';
  }

  @override
  String get aboutAppVersion => '應用版本';

  @override
  String get aboutBuildNumber => '建置編號';

  @override
  String get aboutPackage => '套件';

  @override
  String get aboutBuildSignature => '建置簽章';

  @override
  String get aboutSourceSection => '原始碼';

  @override
  String get aboutLegalSection => '法律';

  @override
  String get aboutGithubRepo => 'GitHub 程式碼庫';

  @override
  String get aboutLicenseLink => '授權(GPL-3.0-or-later)';

  @override
  String get aboutDisclaimerLink => '免責聲明';

  @override
  String get aboutSecurityModelLink => '安全模型';

  @override
  String get aboutFreeSoftwareBody =>
      'PeekWallet 是免費的開放原始碼軟體。任何人都可以閱讀原始碼、自行建置,並驗證 /releases 上的二進位檔與公開原始碼相符(可重現性追蹤於路線圖)。';

  @override
  String get aboutUrlCopiedToast => 'URL 已複製 — 請在瀏覽器中開啟';

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
  String sendScreenTitle(String coinName) {
    return '傳送 $coinName';
  }

  @override
  String sendScanTitle(String symbol) {
    return '掃描 $symbol 地址';
  }

  @override
  String sendBtcAmountLabel(String symbol) {
    return '金額($symbol 或 sat)';
  }

  @override
  String sendBroadcastSuccess(String prefix) {
    return '已廣播!交易 ID: $prefix…';
  }

  @override
  String get sendBtcLoadingUtxos => '載入 UTXO 中…';

  @override
  String sendBtcUtxoError(String error) {
    return 'UTXO 錯誤:$error';
  }

  @override
  String get sendBtcAvailableHint => '可用 · 僅計算已確認 UTXO';

  @override
  String sendBtcFeeRatesError(String error) {
    return '無法取得手續費率:$error';
  }

  @override
  String get sendBtcLoadingFeeRates => '載入手續費率…';

  @override
  String get sendBtcFinalFeeHint => '最終手續費與找零會在廣播後顯示。一旦提交至網路後即無法撤回。';

  @override
  String get sendBtcExperimentalBody => '傳送已通過 BIP-0143 規範向量測試,但尚未經過端對端審計。';

  @override
  String sendBtcOnlyBech32(String prefix) {
    return '僅支援 bech32 P2WPKH($prefix…)地址';
  }

  @override
  String sendBtcExceedsBalance(int available) {
    return '金額超過已確認餘額($available sat)';
  }

  @override
  String get sendBtcFeeRateLabel => '手續費率';

  @override
  String get sendBtcFeeTierFastest => '最快';

  @override
  String get sendBtcFeeTierHalfHour => '半小時';

  @override
  String get sendBtcFeeTierHour => '一小時';

  @override
  String get sendBtcFeeTierEconomy => '節省';

  @override
  String get sendBtcFeeEtaFastest => '約 10 分鐘';

  @override
  String get sendBtcFeeEtaHalfHour => '約 30 分鐘';

  @override
  String get sendBtcFeeEtaHour => '約 1 小時';

  @override
  String get sendBtcFeeEtaEconomy => '視記憶池而定';

  @override
  String get sendBchRecipientLabel => '收款地址(CashAddr)';

  @override
  String get sendBchExperimentalBody =>
      '傳統 P2PKH 加 SIGHASH_FORKID。BIP143 sighash 已透過 BTC SegWit 規範向量測試;BCH 專屬的 0x41 sighash 位元組及傳統交易封包已單元測試但未經審計。';

  @override
  String get sendBchErrorMustBeCashAddr =>
      '收款人必須為 CashAddr(bitcoincash:q…/p… 或直接 q…/p…)';

  @override
  String get sendBchErrorP2shNotSupported =>
      '目前尚未支援 P2SH BCH 地址(p…) — 本版本只支援 P2KH(q…)。';

  @override
  String get sendBchFinalFeeHint =>
      'BCH 傳統 P2PKH 含 SIGHASH_FORKID。一旦提交後即無法撤回(BCH 不支援 RBF)。';

  @override
  String get sendBchAvailableShort => '可用';

  @override
  String get sendBchNetworkFeeLabel => '網路手續費';

  @override
  String sendBchFeeRateDescription(int rate, int typical) {
    return '$rate sat/byte — 一般單輸入交易約 $typical sat。BCH 手續費極低。';
  }

  @override
  String get sendBchAmountLabel => '金額(BCH 或 sat)';

  @override
  String get sendEthExperimentalBody =>
      'RLP + EIP-1559 sighash + ECDSA 復原已單元測試,但端對端傳送流程尚未審計。';

  @override
  String get sendEthErrorBadAddress => '收款人必須是 0x 前綴加 40 字元十六進位地址';

  @override
  String sendEthErrorExceedsToken(String symbol) {
    return '金額超過 $symbol 餘額';
  }

  @override
  String sendEthErrorNoGas(String symbol) {
    return '沒有 $symbol 可付手續費 — 請先注資至此錢包';
  }

  @override
  String sendEthAmountLabelToken(String symbol) {
    return '金額($symbol 或最小單位)';
  }

  @override
  String sendEthAmountLabelNative(String symbol) {
    return '金額($symbol 或 wei)';
  }

  @override
  String get sendEthMaxFeeLabel => '每單位 gas 上限';

  @override
  String get sendEthPriorityFeeLabel => '優先費';

  @override
  String get sendEthLoadingBalance => '載入餘額中…';

  @override
  String sendEthBalanceError(String error) {
    return '餘額錯誤:$error';
  }

  @override
  String sendEthAvailableForGas(String amount, String symbol) {
    return '可用 · $amount $symbol 可付手續費';
  }

  @override
  String sendEthFeeError(String error) {
    return '手續費資料無法取得:$error';
  }

  @override
  String get sendEthLoadingFee => '載入手續費率…';

  @override
  String get sendEthNetworkFeeHeader => '網路手續費';

  @override
  String get sendEthAutoBadge => '自動';

  @override
  String get sendEthBaseLabel => '基本';

  @override
  String get sendEthTipLabel => '小費';

  @override
  String get sendEthMaxLabel => '上限';

  @override
  String get sendEthFinalFeeHint =>
      '最終手續費取決於上鏈時的網路基礎費。低於上限的部分會退回 — 多付不會真的多花。一旦提交即無法撤回。';

  @override
  String get sendSolExperimentalBody => 'Solana 交易編碼已單元測試,但端對端傳送流程尚未審計。';

  @override
  String get sendSolErrorBadAddress => '地址應為 32-44 個 base58 字元';

  @override
  String get sendSolErrorNoSol => '沒有 SOL 可付手續費 — 請先注入少量 SOL 至此錢包';

  @override
  String sendSolErrorNeedsAtaSol(String symbol) {
    return '收款人尚未有 $symbol 帳戶 — 傳送會建立一個(需額外 ~0.00204 SOL 租金 + 手續費)。';
  }

  @override
  String get sendSolErrorNotEnoughSol => 'SOL 不足以付網路費。';

  @override
  String get sendSolErrorAmountFeeExceeds => '金額加手續費超過餘額';

  @override
  String sendSolAmountLabelToken(String symbol) {
    return '金額($symbol 或最小單位)';
  }

  @override
  String get sendSolAmountLabelNative => '金額(SOL 或 lamport)';

  @override
  String get sendSolAddressHint => 'Solana 地址';

  @override
  String get sendSolNetworkFeeLabel => '網路手續費';

  @override
  String get sendSolAtaRentLabel => 'ATA 租金';

  @override
  String get sendSolTotalOutLabel => 'SOL 總支出';

  @override
  String get sendSolFinalFeeHintNative =>
      'Solana 手續費固定為每個簽章 5000 lamport。一旦提交即無法撤回。';

  @override
  String sendSolFinalFeeHintNewAta(String symbol) {
    return '收款人尚未有 $symbol 帳戶。傳送會為對方建立一個(約 0.00204 SOL 租金,由你支付)。一旦提交即無法撤回。';
  }

  @override
  String get sendTrxExperimentalBody =>
      'Tron 交易由 RPC 建構並於本機簽章。簽章前會驗證 txid 雜湊,但不會解碼 protobuf 內容。';

  @override
  String get sendTrxErrorBadAddress => '收款人必須是 base58 Tron 地址(以 T 開頭,34 字元)';

  @override
  String get sendTrxErrorNoTrx => '沒有 TRX 可付頻寬/能量 — 請先注入 TRX 至此錢包';

  @override
  String get sendTrxRecipientLabel => '收款人(Tron base58)';

  @override
  String sendTrxAmountLabelToken(String symbol) {
    return '金額($symbol 或最小單位)';
  }

  @override
  String get sendTrxAmountLabelNative => '金額(TRX 或 sun)';

  @override
  String get sendTrxBandwidthLabel => '頻寬/能量';

  @override
  String get sendTrxBandwidthToken => '最多約 30 TRX 等值(TRC-20)';

  @override
  String get sendTrxBandwidthNative => '免費配額或約 0.27 TRX';

  @override
  String get sendTrxFinalFeeHint =>
      'Tron 交易由 RPC 節點建構;我們會在本機簽章前重新驗證 txid 雜湊。一旦提交即無法撤回。';

  @override
  String get sendXmrTitle => '傳送 XMR';

  @override
  String get sendXmrScanTitle => '掃描收款地址';

  @override
  String sendXmrAvailable(String amount) {
    return '可用:$amount XMR';
  }

  @override
  String get sendXmrAddRecipient => '新增收款人';

  @override
  String get sendXmrSendAllTitle => '全部傳送';

  @override
  String get sendXmrSendAllBody => '將所有可花費的輸出轉至第一位收款人 — 手續費會自動扣除。';

  @override
  String get sendXmrFeePriorityLabel => '手續費優先順序';

  @override
  String get sendXmrTierSlow => '慢';

  @override
  String get sendXmrTierNormal => '一般';

  @override
  String get sendXmrTierFast => '快';

  @override
  String get sendXmrReviewAction => '檢視傳送';

  @override
  String get sendXmrToLabel => '收款人';

  @override
  String sendXmrToNumbered(int index) {
    return '收款人 #$index';
  }

  @override
  String get sendXmrSubtotalLabel => '小計';

  @override
  String get sendXmrSweepLabel => '傳送(全部)';

  @override
  String get sendXmrNetworkFee => '網路費';

  @override
  String sendXmrSplitWarning(int count) {
    return '此次傳送將拆為 $count 筆子交易發送。';
  }

  @override
  String get sendXmrBroadcastTitle => '交易已廣播';

  @override
  String get sendXmrBroadcastBody => '網路確認後將出現在你的交易紀錄中。';

  @override
  String get sendXmrTxIdLabel => '交易 ID';

  @override
  String get sendXmrTxIdCopied => '交易 ID 已複製';

  @override
  String get sendXmrCopyTxIdAction => '複製交易 ID';

  @override
  String get sendXmrDoneAction => '完成';

  @override
  String get sendXmrRecipientHeader => '收款人';

  @override
  String get sendXmrRemoveTooltip => '移除';

  @override
  String get sendXmrAddressLabel => '收款地址';

  @override
  String get sendXmrAddressBookTooltip => '通訊錄';

  @override
  String get sendXmrPasteTooltip => '貼上';

  @override
  String get sendXmrAmountLabel => '金額(XMR)';

  @override
  String get sendXmrAmountHintSweep => '全部 — 金額自動設定';

  @override
  String sendXmrErrorBadAddress(String tag) {
    return '地址不像是 Monero 格式$tag。';
  }

  @override
  String sendXmrErrorAmountZero(String tag) {
    return '金額必須大於 0$tag。';
  }

  @override
  String get sendXmrErrorExceedsBalance => '總額超過餘額。';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsMoneroNode => 'Monero 節點';

  @override
  String get settingsMoneroNodeBody =>
      'PeekWallet 用來同步的 Monero 守護程式。預設為 Cake Wallet 的公開節點。如需完全隱私,可自架 monerod 並指向自己的節點。';

  @override
  String get settingsDaemonUrlLabel => '節點 URL';

  @override
  String get settingsPasteTooltip => '貼上';

  @override
  String settingsConnectsToPreview(String hostPort, String ssl) {
    return '連線至 $hostPort(ssl=$ssl)';
  }

  @override
  String get settingsMessageBadUrl =>
      '無法解析此 URL。請試試 https://node.example.com:18081';

  @override
  String get settingsMessageSaved => '已儲存。鎖定再解鎖即可切換到新節點。';

  @override
  String settingsMessageReset(String url) {
    return '已重置。下次解鎖將使用 $url。';
  }

  @override
  String get settingsResetToDefault => '重置為預設';

  @override
  String get settingsSectionPublicNodes => '公開節點';

  @override
  String get settingsSectionSecurity => '安全性';

  @override
  String get settingsSectionDisplay => '顯示';

  @override
  String get settingsBiometricUnlock => '生物辨識解鎖';

  @override
  String get settingsBiometricUnlockOn => '使用指紋 / 臉部解鎖';

  @override
  String get settingsBiometricUnlockOff => '無法使用 — 尚未註冊生物辨識';

  @override
  String get settingsBiometricEnableTitle => '啟用生物辨識解鎖';

  @override
  String get settingsBiometricEnableHint => '輸入應用程式密碼以確認';

  @override
  String settingsBiometricEnableFailed(String error) {
    return '無法啟用:$error';
  }

  @override
  String get settingsPasswordLabel => '密碼';

  @override
  String get settingsRevealSeedTitle => '顯示助記詞';

  @override
  String get settingsRevealSeedBody => '查看 BIP39 種子及 Monero 花費/檢視金鑰';

  @override
  String get settingsAddressBookTitle => '通訊錄';

  @override
  String get settingsAddressBookBody => '已儲存的收款人標籤';

  @override
  String get settingsAutoLockTitle => '自動鎖定';

  @override
  String get settingsAutoLockSheetTitle => '切換到背景後自動鎖定';

  @override
  String get settingsAutoLockSheetBody =>
      'PeekWallet 在你使用其他應用程式時可保持解鎖多久。在此期間返回保持登入;超時則需重新輸入密碼。';

  @override
  String get settingsAutoLockImmediately => '立即';

  @override
  String get settingsAutoLockNever => '永不';

  @override
  String settingsAutoLockSeconds(int n) {
    return '$n 秒';
  }

  @override
  String get settingsAutoLock30Seconds => '30 秒';

  @override
  String get settingsAutoLock1Minute => '1 分鐘';

  @override
  String get settingsAutoLock2MinutesDefault => '2 分鐘(預設)';

  @override
  String get settingsAutoLock5Minutes => '5 分鐘';

  @override
  String get settingsAutoLock15Minutes => '15 分鐘';

  @override
  String get settingsAutoLock1Hour => '1 小時';

  @override
  String get settingsLockAppTitle => '鎖定應用程式';

  @override
  String get settingsLockAppBody => '清除記憶體中的種子,需重新輸入密碼';

  @override
  String get settingsLockConfirmTitle => '鎖定應用程式?';

  @override
  String get settingsLockConfirmBody => '需重新輸入密碼以解鎖。任何進行中的 Monero 同步將從中斷處繼續。';

  @override
  String get settingsLockConfirmAction => '鎖定';

  @override
  String get settingsDisplayCurrencyTitle => '顯示幣別';

  @override
  String get settingsDisplayCurrencyDisabled => '已停用';

  @override
  String get settingsShowFiatValues => '顯示法幣值';

  @override
  String get settingsShowFiatValuesBody => '每 5 分鐘輪詢 CoinGecko。不傳送個人識別資訊。';

  @override
  String get settingsExportLogsTitle => '匯出日誌';

  @override
  String get settingsExportLogsBody => '最近 7 天。地址與金鑰會自動遮罩。';

  @override
  String get settingsExportLogsEmpty => '尚無日誌可匯出。';

  @override
  String get settingsExportLogsDialogTitle => '日誌(最近 7 天)';

  @override
  String get settingsExportLogsCopied => '日誌已複製到剪貼簿';

  @override
  String get settingsCloseAction => '關閉';

  @override
  String get settingsRestoreAllTitle => '從金庫種子還原所有幣種';

  @override
  String get settingsRestoreAllBody => '一鍵用既有的 12/24 字種子衍生每種幣的錢包。';

  @override
  String get settingsCustomRpcTitle => '自訂 RPC 端點';

  @override
  String get settingsCustomRpcBody => '將 BTC/LTC/BCH/ETH/POL/SOL/TRX 指向你自己的節點。';

  @override
  String get settingsUpdateTitle => '檢查更新';

  @override
  String get settingsUpdateChecking => '正在查詢 GitHub…';

  @override
  String get settingsUpdateTapToCheck => '點擊以檢查';

  @override
  String get settingsUpdateFailedFallback => '檢查失敗';

  @override
  String settingsUpdateAvailable(String ago) {
    return '有可用更新 — 發佈於 $ago。點擊下載。';
  }

  @override
  String get settingsUpdateDebugBuild => 'Debug 版本 — 已停用版本檢查。點擊重試。';

  @override
  String get settingsUpdateUpToDate => '已是最新版 · 剛剛檢查';

  @override
  String get settingsAboutTitle => '關於 PeekWallet';

  @override
  String get settingsAboutBody => '版本、授權、原始碼';

  @override
  String get addWalletChooseCoin => '選擇幣種';

  @override
  String addWalletTitle(String coin) {
    return '新增 $coin 錢包';
  }

  @override
  String get addWalletCreateTitle => '建立新錢包';

  @override
  String get addWalletCreateBody => '產生全新的助記詞。任何持有此助記詞的人都能花費此錢包 — 請寫在紙上。';

  @override
  String get addWalletRestoreSeedTitle => '從助記詞還原';

  @override
  String get addWalletRestoreSeedBody =>
      '使用既有的助記詞(BIP39 12/24 字、Monero 25 字、Polyseed 14 字)。';

  @override
  String get addWalletRestoreKeysTitle => '從金鑰還原';

  @override
  String get addWalletRestoreKeysBody => '地址 + 私人花費金鑰 + 私人檢視金鑰。當你有金鑰但無助記詞時使用。';

  @override
  String get addWalletFormatNew => '新種子格式';

  @override
  String get addWalletFormatRestore => '還原格式';

  @override
  String get addWalletFormatBip39Hint =>
      'BIP39 助記詞 — 所有現代錢包使用的標準 12/24 字格式。Trezor、Ledger 通用。';

  @override
  String get addWalletFormatMoneroLegacyHint =>
      'Monero 原生 electrum 風格助記詞。可直接與 Cake、Feather、Monero GUI 互通。';

  @override
  String get addWalletFormatPolyseedHint => '新版 Monero 標準 — 14 字。內含還原高度。';

  @override
  String get addWalletFormatKeysOnlyHint => '花費金鑰 + 檢視金鑰 + 地址。沒有助記詞。';

  @override
  String get addWalletVaultLocked => '金庫已鎖定 — 請重新解鎖後再試。';

  @override
  String addWalletGenerateHeader(String format) {
    return '產生 $format';
  }

  @override
  String get addWalletGenerateBody =>
      '點擊「產生」後,助記詞只會顯示一次。請先寫在紙上再繼續。任何持有這些字的人都能轉走此錢包。';

  @override
  String get addWalletGenerateAction => '產生助記詞';

  @override
  String get addWalletWriteThisDown => '請寫下這些字';

  @override
  String get addWalletWordsWarning => '這些字就是錢包。任何人有了就能花費。';

  @override
  String get addWalletCopyClipboardClears => '已複製 — 剪貼簿將於 30 秒後自動清除';

  @override
  String get addWalletCopyPhraseAction => '複製助記詞';

  @override
  String get addWalletNameLabel => '錢包名稱(僅你看得到)';

  @override
  String get addWalletNameHint => '例如「主 Monero」';

  @override
  String get addWalletSavedConfirm => '我已保存助記詞 — 新增錢包';

  @override
  String addWalletRestoreTitle(String format) {
    return '還原 $format';
  }

  @override
  String get addWalletRestoreNameLabel => '錢包名稱';

  @override
  String get addWalletRestoreNameHint => '例如「從 Cake 匯入」';

  @override
  String get addWalletRecoveryPhraseLabel => '助記詞';

  @override
  String get addWalletSeedWordsLabel => '種子字';

  @override
  String get addWalletPassphraseLabel => 'BIP39 通行短語(第 25 字) — 選填';

  @override
  String get addWalletPassphraseHint => '若未使用請留空';

  @override
  String get addWalletPassphraseWarning => '若來源錢包有通行短語,必須輸入 — 否則會得到完全不同的錢包。';

  @override
  String get addWalletSeedOffsetLabel => '種子偏移 — 選填';

  @override
  String get addWalletSeedOffsetHint => '若種子未加密請留空';

  @override
  String get addWalletRestoreHeightLabel => '還原高度 — 選填';

  @override
  String get addWalletRestoreHeightHint => '開始掃描的區塊高度';

  @override
  String get addWalletRestoreHeightBody => '較低 = 較徹底但較慢;較高 = 較快但可能遺漏舊收款。';

  @override
  String get addWalletRestoreAction => '還原錢包';

  @override
  String get addWalletKeysRestoreTitle => '從金鑰還原';

  @override
  String get addWalletPrimaryAddressLabel => '主要地址';

  @override
  String get addWalletSpendKeyLabel => '私人花費金鑰(hex)';

  @override
  String get addWalletViewKeyLabel => '私人檢視金鑰(hex)';

  @override
  String get addWalletKeysRestoreHeightLabel => '還原高度';

  @override
  String get addWalletKeysRestoreHeightHint => '區塊號 — 越早涵蓋越多舊收款';

  @override
  String get addWalletScanAddressTitle => '掃描地址';

  @override
  String get addWalletConfirmPasswordTitle => '確認密碼';

  @override
  String get addWalletAppPasswordLabel => '應用程式密碼';

  @override
  String lockTryAgainIn(String duration) {
    return '請於 $duration 後再試。';
  }

  @override
  String get welcomeTagline => 'BTC、ETH、XMR 等多幣種的自我託管錢包。';

  @override
  String get welcomeCreateAction => '建立新錢包';

  @override
  String get welcomeImportAction => '我已有助記詞';

  @override
  String get welcomeBackupWarning => '你的 12 字助記詞是唯一的備份。任何持有的人都能轉走資金。';

  @override
  String get welcomeDisclaimerAction => '閱讀免責聲明';

  @override
  String get welcomeDisclaimerTitle => '免責聲明';

  @override
  String get welcomeCopiedToast => '已複製';

  @override
  String get welcomeCopyTextAction => '複製文字';

  @override
  String get welcomeIUnderstandAction => '我已了解';

  @override
  String get revealSeedTitle => '顯示助記詞';

  @override
  String get revealSeedWarning =>
      '你即將顯示助記詞和 Monero 金鑰。任何人看到都能轉走資金 — 確保沒人在看你的螢幕,也沒在進行螢幕分享。';

  @override
  String get revealSeedPasswordPrompt => '請輸入應用程式密碼以繼續。';

  @override
  String get revealSeedRevealAction => '顯示';

  @override
  String get revealSeedBip39Section => 'BIP39 助記詞';

  @override
  String get revealSeedPassphraseSection => 'BIP39 通行短語(第 25 字)';

  @override
  String get revealSeedXmrAddressSection => 'Monero 主要地址';

  @override
  String get revealSeedXmrSpendSection => 'Monero 私人花費金鑰';

  @override
  String get revealSeedXmrViewSection => 'Monero 私人檢視金鑰';

  @override
  String get revealSeedCopyPhrase => '複製助記詞';

  @override
  String get revealSeedCopyPassphrase => '複製通行短語';

  @override
  String get revealSeedCopyAddress => '複製地址';

  @override
  String get revealSeedCopySpendKey => '複製花費金鑰';

  @override
  String get revealSeedCopyViewKey => '複製檢視金鑰';

  @override
  String get revealSeedRestoreHint =>
      '你可以在 Cake / Feather / Monero GUI 中用「從金鑰還原」(地址 + 檢視金鑰 + 花費金鑰)還原此錢包,或用 BIP39 助記詞在任何 BIP39 相容錢包中還原。';

  @override
  String get revealSeedCopiedSensitive => '已複製 — 剪貼簿將於 30 秒後自動清除';

  @override
  String get revealSeedCopiedPlain => '已複製';

  @override
  String get aboutScreenTitle => '關於';

  @override
  String aboutVersionLine(String version, String build) {
    return 'v$version(build $build)';
  }

  @override
  String get aboutAppVersion => '應用版本';

  @override
  String get aboutBuildNumber => '建置編號';

  @override
  String get aboutPackage => '套件';

  @override
  String get aboutBuildSignature => '建置簽章';

  @override
  String get aboutSourceSection => '原始碼';

  @override
  String get aboutLegalSection => '法律';

  @override
  String get aboutGithubRepo => 'GitHub 程式碼庫';

  @override
  String get aboutLicenseLink => '授權(GPL-3.0-or-later)';

  @override
  String get aboutDisclaimerLink => '免責聲明';

  @override
  String get aboutSecurityModelLink => '安全模型';

  @override
  String get aboutFreeSoftwareBody =>
      'PeekWallet 是免費的開放原始碼軟體。任何人都可以閱讀原始碼、自行建置,並驗證 /releases 上的二進位檔與公開原始碼相符(可重現性追蹤於路線圖)。';

  @override
  String get aboutUrlCopiedToast => 'URL 已複製 — 請在瀏覽器中開啟';

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
