import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../coins/monero/monero_wallet.dart';
import '../l10n/gen/app_localizations.dart';
import '../prefs/prefs.dart';
import '../prices/price_feed.dart';
import '../theme.dart';
import '../util/peek_logger.dart';
import '../vault/biometric_auth.dart';
import '../vault/vault_state.dart';
import 'package:url_launcher/url_launcher.dart';

import '../util/update_checker.dart';
import '../widgets/settings_row.dart';
import 'about_screen.dart';
import 'restore_all_from_vault_screen.dart';
import 'rpc_overrides_screen.dart';
import 'address_book_screen.dart';
import 'reveal_seed_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nodeController = TextEditingController();
  String? _savedUri;
  bool _loading = true;
  bool _busy = false;
  String? _message;
  MaterialColor? _messageColor;

  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  int _autoLockSeconds = Prefs.defaultAutoLockSeconds;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nodeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final saved = await Prefs.I.moneroDaemonUri();
    final bioEnabled = await VaultState.I.biometricEnabled();
    final bioAvail = await BiometricAuth.I.isAvailable();
    final autoLock = await Prefs.I.autoLockSeconds();
    setState(() {
      _savedUri = saved;
      _nodeController.text = saved ?? '';
      _biometricEnabled = bioEnabled;
      _biometricAvailable = bioAvail;
      _autoLockSeconds = autoLock;
      _loading = false;
    });
  }

  Future<void> _toggleBiometric(bool wantOn) async {
    final l = AppLocalizations.of(context);
    if (!wantOn) {
      await VaultState.I.disableBiometric();
      setState(() => _biometricEnabled = false);
      return;
    }
    // Confirm the password before stashing it. Even though the
    // wallet is unlocked, we don't trust the in-memory state —
    // a wrong password here would lock the user out of biometric
    // unlock until they disabled + re-enabled.
    final password = await _askPassword(
      title: l.settingsBiometricEnableTitle,
      hint: l.settingsBiometricEnableHint,
    );
    if (password == null) return;
    try {
      await VaultState.I.enableBiometric(password);
      setState(() => _biometricEnabled = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.settingsBiometricEnableFailed('$e'))),
      );
    }
  }

  Future<String?> _askPassword({
    required String title,
    required String hint,
  }) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
              labelText: l.settingsPasswordLabel, hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(l.actionContinue),
          ),
        ],
      ),
    );
    controller.dispose();
    return (result == null || result.isEmpty) ? null : result;
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final input = _nodeController.text.trim();
    if (input.isNotEmpty && !MoneroDaemonEndpoint.isValid(input)) {
      setState(() {
        _message = l.settingsMessageBadUrl;
        _messageColor = Colors.red;
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    await Prefs.I.setMoneroDaemonUri(input.isEmpty ? null : input);
    if (!mounted) return;
    setState(() {
      _savedUri = input.isEmpty ? null : input;
      _busy = false;
      _message = l.settingsMessageSaved;
      _messageColor = Colors.green;
    });
  }

  String _autoLockLabel(AppLocalizations l, int seconds) {
    if (seconds <= 0) return l.settingsAutoLockImmediately;
    if (seconds >= 86400) return l.settingsAutoLockNever;
    if (seconds < 60) return l.settingsAutoLockSeconds(seconds);
    if (seconds < 3600) return l.ageMinutes(seconds ~/ 60);
    return l.ageHours(seconds ~/ 3600);
  }

  Future<void> _pickAutoLock() async {
    final l = AppLocalizations.of(context);
    final options = <(int, String)>[
      (0, l.settingsAutoLockImmediately),
      (30, l.settingsAutoLock30Seconds),
      (60, l.settingsAutoLock1Minute),
      (120, l.settingsAutoLock2MinutesDefault),
      (300, l.settingsAutoLock5Minutes),
      (900, l.settingsAutoLock15Minutes),
      (3600, l.settingsAutoLock1Hour),
      (86400, l.settingsAutoLockNever),
    ];
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: PeekColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                l.settingsAutoLockSheetTitle,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l.settingsAutoLockSheetBody,
                style:
                    const TextStyle(color: PeekColors.text3, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            for (final (sec, label) in options)
              ListTile(
                title: Text(label),
                trailing: sec == _autoLockSeconds
                    ? const Icon(Icons.check, color: PeekColors.accent)
                    : null,
                onTap: () => Navigator.of(ctx).pop(sec),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await Prefs.I.setAutoLockSeconds(picked);
      setState(() => _autoLockSeconds = picked);
    }
  }

  Future<void> _exportLogs() async {
    final l = AppLocalizations.of(context);
    final content = await PeekLogger.I.readCurrent();
    if (!mounted) return;
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.settingsExportLogsEmpty)),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsExportLogsDialogTitle),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              content,
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.settingsCloseAction),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (ctx.mounted) Navigator.of(ctx).pop();
              messenger.showSnackBar(
                SnackBar(content: Text(l.settingsExportLogsCopied)),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: Text(l.actionCopy),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCurrency() async {
    final l = AppLocalizations.of(context);
    const currencies = <String>[
      'usd', 'eur', 'gbp', 'jpy', 'cny', 'krw', 'rub',
      'aud', 'cad', 'inr', 'try', 'brl',
      // Asian fiats prioritized — most PeekWallet users in HK/MY/SG/TW.
      'sgd', 'hkd', 'twd', 'myr', 'thb', 'idr', 'php', 'vnd',
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: PeekColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                l.settingsDisplayCurrencyTitle,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            SwitchListTile(
              title: Text(l.settingsShowFiatValues),
              subtitle: Text(
                l.settingsShowFiatValuesBody,
                style:
                    const TextStyle(color: PeekColors.text3, fontSize: 11),
              ),
              value: PriceFeed.I.enabled,
              onChanged: (v) async {
                await PriceFeed.I.setEnabled(v);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
              },
            ),
            const Divider(),
            for (final c in currencies)
              ListTile(
                title: Text(c.toUpperCase()),
                trailing: c == PriceFeed.I.currency
                    ? const Icon(Icons.check, color: PeekColors.accent)
                    : null,
                onTap: () => Navigator.of(ctx).pop(c),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await PriceFeed.I.setCurrency(picked);
    }
  }

  Future<void> _confirmLock() async {
    final l = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsLockConfirmTitle),
        content: Text(l.settingsLockConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.actionCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.settingsLockConfirmAction),
          ),
        ],
      ),
    );
    if (yes == true) VaultState.I.lock();
  }

  Future<void> _reset() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    await Prefs.I.setMoneroDaemonUri(null);
    if (!mounted) return;
    setState(() {
      _savedUri = null;
      _nodeController.text = '';
      _busy = false;
      _message = l.settingsMessageReset(kDefaultMoneroDaemon);
      _messageColor = Colors.green;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final input = _nodeController.text.trim();
    final effective = input.isEmpty
        ? (_savedUri ?? kDefaultMoneroDaemon)
        : input;
    final preview = MoneroDaemonEndpoint.isValid(effective)
        ? MoneroDaemonEndpoint.parse(effective)
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PeekColors.accent))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.settingsMoneroNode,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.settingsMoneroNodeBody,
                      style: const TextStyle(
                          color: PeekColors.text2, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _nodeController,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: l.settingsDaemonUrlLabel,
                        hintText: kDefaultMoneroDaemon,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.content_paste, size: 18),
                          tooltip: l.settingsPasteTooltip,
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null) {
                              _nodeController.text = data!.text!.trim();
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ),
                    if (preview != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        l.settingsConnectsToPreview(
                            preview.hostPort, preview.useSsl.toString()),
                        style: const TextStyle(
                            color: PeekColors.text3, fontSize: 11),
                      ),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _message!,
                        style: TextStyle(
                          color: _messageColor == Colors.red
                              ? PeekColors.red
                              : PeekColors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy ? null : _reset,
                            child: Text(l.settingsResetToDefault),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _busy ? null : _save,
                            child: _busy
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(l.actionSave),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _SectionDivider(label: l.settingsSectionPublicNodes),
                    const SizedBox(height: 8),
                    for (final url in const [
                      kDefaultMoneroDaemon,
                      ...kMoneroFallbackNodes,
                    ])
                      _NodeQuickPick(
                        url: url,
                        isActive: (_savedUri ?? kDefaultMoneroDaemon) == url,
                        onPick: () {
                          _nodeController.text = url;
                          setState(() {});
                        },
                      ),
                    _SectionDivider(label: l.settingsSectionSecurity),
                    SettingsSwitchRow(
                      icon: Icons.fingerprint_rounded,
                      title: l.settingsBiometricUnlock,
                      subtitle: _biometricAvailable
                          ? l.settingsBiometricUnlockOn
                          : l.settingsBiometricUnlockOff,
                      value: _biometricEnabled,
                      onChanged:
                          _biometricAvailable ? _toggleBiometric : null,
                    ),
                    SettingsRow(
                      icon: Icons.visibility_outlined,
                      title: l.settingsRevealSeedTitle,
                      subtitle: l.settingsRevealSeedBody,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RevealSeedScreen()),
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.contact_page_outlined,
                      title: l.settingsAddressBookTitle,
                      subtitle: l.settingsAddressBookBody,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddressBookScreen(),
                        ),
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.timer_outlined,
                      title: l.settingsAutoLockTitle,
                      subtitle: _autoLockLabel(l, _autoLockSeconds),
                      onTap: _pickAutoLock,
                    ),
                    SettingsRow(
                      icon: Icons.lock_outline_rounded,
                      title: l.settingsLockAppTitle,
                      subtitle: l.settingsLockAppBody,
                      onTap: _confirmLock,
                    ),
                    _SectionDivider(label: l.settingsSectionDisplay),
                    AnimatedBuilder(
                      animation: PriceFeed.I,
                      builder: (_, _) => SettingsRow(
                        icon: Icons.currency_exchange_rounded,
                        title: l.settingsDisplayCurrencyTitle,
                        subtitle: PriceFeed.I.enabled
                            ? PriceFeed.I.currency.toUpperCase()
                            : l.settingsDisplayCurrencyDisabled,
                        onTap: _pickCurrency,
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.description_outlined,
                      title: l.settingsExportLogsTitle,
                      subtitle: l.settingsExportLogsBody,
                      onTap: _exportLogs,
                    ),
                    SettingsRow(
                      icon: Icons.auto_awesome_rounded,
                      title: l.settingsRestoreAllTitle,
                      subtitle: l.settingsRestoreAllBody,
                      iconAccent: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                const RestoreAllFromVaultScreen()),
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.lan_outlined,
                      title: l.settingsCustomRpcTitle,
                      subtitle: l.settingsCustomRpcBody,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RpcOverridesScreen()),
                      ),
                    ),
                    _UpdateCheckerRow(),
                    SettingsRow(
                      icon: Icons.info_outline_rounded,
                      title: l.settingsAboutTitle,
                      subtitle: l.settingsAboutBody,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Settings row that probes GitHub releases for a newer APK and
/// surfaces "Up to date" / "Update available" inline. On tap of an
/// "Update available" row, opens the APK download URL in the system
/// browser — Android can't silently install (that needs device-admin
/// privileges) but a one-tap "download → install" beats the user
/// not knowing an update exists.
class _UpdateCheckerRow extends StatefulWidget {
  @override
  State<_UpdateCheckerRow> createState() => _UpdateCheckerRowState();
}

class _UpdateCheckerRowState extends State<_UpdateCheckerRow> {
  bool _busy = false;
  UpdateCheckResult? _result;

  @override
  void initState() {
    super.initState();
    _result = UpdateChecker.I.lastResult;
    // Auto-check on first open of Settings so the row arrives with
    // a meaningful subtitle. Backgrounded — UI renders "Checking…"
    // until the future resolves.
    if (_result == null) {
      _check();
    }
  }

  Future<void> _check() async {
    if (!mounted) return;
    setState(() => _busy = true);
    final r = await UpdateChecker.I.check();
    if (!mounted) return;
    setState(() {
      _result = r;
      _busy = false;
    });
  }

  Future<void> _openDownload(String url) async {
    try {
      await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    } catch (_) {/* swallow — browser failure isn't actionable */}
  }

  String _subtitle(AppLocalizations l) {
    if (_busy) return l.settingsUpdateChecking;
    final r = _result;
    if (r == null) return l.settingsUpdateTapToCheck;
    if (r.hasError) return r.error ?? l.settingsUpdateFailedFallback;
    if (r.isUpdateAvailable) {
      return l.settingsUpdateAvailable(_ago(l, r.latestReleaseAt!));
    }
    if (r.currentBuildTime == null) return l.settingsUpdateDebugBuild;
    return l.settingsUpdateUpToDate;
  }

  String _ago(AppLocalizations l, DateTime then) {
    final d = DateTime.now().toUtc().difference(then.toUtc());
    if (d.inMinutes < 60) return l.ageMinutes(d.inMinutes);
    if (d.inHours < 24) return l.ageHours(d.inHours);
    return l.ageDays(d.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = _result;
    final iconAccent = r != null && r.isUpdateAvailable;
    return SettingsRow(
      icon: iconAccent
          ? Icons.system_update_rounded
          : Icons.cloud_download_outlined,
      title: l.settingsUpdateTitle,
      subtitle: _subtitle(l),
      iconAccent: iconAccent,
      onTap: _busy
          ? null
          : () {
              if (r != null && r.isUpdateAvailable) {
                final url = r.assetUrl ?? r.releaseUrl;
                if (url != null) {
                  _openDownload(url);
                  return;
                }
              }
              _check();
            },
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    // Section header with a hairline rule on the right — the same
    // treatment Tangem / Settings.app use to chunk a long settings
    // list into visually distinct groups without screaming.
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: PeekColors.text3,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Divider(
              color: PeekColors.hairline,
              height: 1,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeQuickPick extends StatelessWidget {
  const _NodeQuickPick({
    required this.url,
    required this.isActive,
    required this.onPick,
  });
  final String url;
  final bool isActive;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        url,
        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
      ),
      trailing: isActive
          ? const Icon(Icons.check_circle, color: PeekColors.green, size: 18)
          : const Icon(Icons.chevron_right, color: PeekColors.text3),
      onTap: onPick,
    );
  }
}
