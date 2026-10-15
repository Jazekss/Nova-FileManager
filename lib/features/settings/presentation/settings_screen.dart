import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/l10n_ext.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Developer homepage and donation page.
  static const _siteUrl = 'https://jkdizains.lv';
  static const _coffeeUrl = 'https://www.buymeacoffee.com/jazeks';

  static const _languageNames = {
    'en': 'English',
    'lv': 'Latviešu',
    'lt': 'Lietuvių',
    'et': 'Eesti',
    'nb': 'Norsk',
    'sv': 'Svenska',
    'pl': 'Polski',
    'de': 'Deutsch',
    'ru': 'Русский',
  };

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final tr = l10n(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr.settings)),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        children: [
          Text(tr.appearance, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppTokens.spacingSm),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(tr.themeSystem),
              ),
              ButtonSegment(value: ThemeMode.light, label: Text(tr.themeLight)),
              ButtonSegment(value: ThemeMode.dark, label: Text(tr.themeDark)),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => settings.setThemeMode(s.first),
          ),
          const SizedBox(height: AppTokens.spacingLg),
          Text(tr.sizeUnits, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppTokens.spacingSm),
          SegmentedButton<SizeUnit>(
            segments: [
              ButtonSegment(value: SizeUnit.auto, label: Text(tr.unitAuto)),
              const ButtonSegment(value: SizeUnit.kb, label: Text('KB')),
              const ButtonSegment(value: SizeUnit.mb, label: Text('MB')),
              const ButtonSegment(value: SizeUnit.gb, label: Text('GB')),
            ],
            selected: {settings.sizeUnit},
            onSelectionChanged: (s) => settings.setSizeUnit(s.first),
          ),
          const SizedBox(height: AppTokens.spacingLg),
          Text(tr.language, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppTokens.spacingSm),
          DropdownButtonFormField<String?>(
            initialValue: settings.languageCode,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              DropdownMenuItem<String?>(child: Text(tr.languageSystem)),
              for (final code in supportedLanguageCodes)
                DropdownMenuItem<String?>(
                  value: code,
                  child: Text(_languageNames[code] ?? code),
                ),
            ],
            onChanged: settings.setLanguage,
          ),
          SwitchListTile(
            title: Text(tr.showHidden),
            subtitle: Text(tr.showHiddenSubtitle),
            value: settings.showHidden,
            onChanged: settings.setShowHidden,
          ),
          SwitchListTile(
            title: Text(tr.shareThumbs),
            subtitle: Text(tr.shareThumbsNote),
            value: settings.shareThumbs,
            onChanged: settings.setShareThumbs,
          ),
          const Divider(height: AppTokens.spacingLg * 2),
          Text(tr.about, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppTokens.spacingSm),
          ListTile(
            leading: Image.asset('assets/icon.png', width: 48, height: 48),
            title: Text(tr.appTitle),
            subtitle: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snap) =>
                  Text(tr.versionLabel(snap.data?.version ?? '—')),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(tr.developerLine),
            subtitle: Text(tr.developerThanks),
            onTap: () => _openUrl(_siteUrl),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          FilledButton.tonalIcon(
            icon: SvgPicture.asset(
              'assets/icons/coffee.svg',
              width: 22,
              height: 22,
            ),
            label: Text(tr.coffeeButton),
            onPressed: () => _openUrl(_coffeeUrl),
          ),
        ],
      ),
    );
  }
}
