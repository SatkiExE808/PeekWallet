import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../theme.dart';

/// Shows app version, build number, package id, and links to the
/// source code + security policy + disclaimer. Useful both for the
/// user (so they can quote a specific build in bug reports) and for
/// reviewers / curious developers who want to audit what they're
/// running.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(
        child: FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: PeekColors.accent),
              );
            }
            final info = snap.data!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 12),
                const Center(
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 56,
                    color: PeekColors.accent,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    info.appName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                Center(
                  child: Text(
                    'v${info.version} (build ${info.buildNumber})',
                    style:
                        const TextStyle(color: PeekColors.text2, fontSize: 13),
                  ),
                ),
                Center(
                  child: Text(
                    info.packageName,
                    style: const TextStyle(
                        color: PeekColors.text3,
                        fontSize: 11,
                        fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 28),
                _kvCard([
                  _kv('App version', info.version),
                  _kv('Build number', info.buildNumber),
                  _kv('Package', info.packageName),
                  _kv('Build signature', info.buildSignature.isEmpty
                      ? '—'
                      : info.buildSignature),
                ]),
                const SizedBox(height: 20),
                const _SectionLabel('Source code'),
                const SizedBox(height: 8),
                _linkRow(context, 'GitHub repository',
                    'https://github.com/SatkiExE808/PeekWallet'),
                const SizedBox(height: 16),
                const _SectionLabel('Legal'),
                const SizedBox(height: 8),
                _linkRow(
                  context,
                  'License (GPL-3.0-or-later)',
                  'https://github.com/SatkiExE808/PeekWallet/blob/main/LICENSE',
                ),
                _linkRow(
                  context,
                  'Disclaimer (no warranty)',
                  'https://github.com/SatkiExE808/PeekWallet/blob/main/DISCLAIMER.md',
                ),
                _linkRow(
                  context,
                  'Security model',
                  'https://github.com/SatkiExE808/PeekWallet/blob/main/docs/security.md',
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    'PeekWallet is free, open-source software. Anyone can '
                    'read the source, build it themselves, and verify the '
                    'binary on /releases matches the public code '
                    '(reproducibility tracked in the roadmap).',
                    style: const TextStyle(color: PeekColors.text3, fontSize: 11),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _kvCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: PeekColors.surface,
        borderRadius: PeekDesign.brCard,
        border: Border.all(color: PeekColors.hairline),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: PeekDesign.sp4, vertical: PeekDesign.sp2),
      child: Column(children: rows),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k,
                style: const TextStyle(color: PeekColors.text2, fontSize: 12)),
          ),
          Expanded(
            child: SelectableText(
              v,
              style: const TextStyle(color: PeekColors.text, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkRow(BuildContext context, String label, String url) {
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: url));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL copied — open in your browser'),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.link, size: 18, color: PeekColors.text2),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13)),
                  Text(url,
                      style: const TextStyle(
                          color: PeekColors.text3, fontSize: 10)),
                ],
              ),
            ),
            const Icon(Icons.content_copy, size: 14, color: PeekColors.text3),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: PeekColors.text3,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}
