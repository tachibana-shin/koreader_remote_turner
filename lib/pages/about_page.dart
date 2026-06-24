import 'package:flutter/material.dart';
import 'package:kaeru/kaeru.dart';
import 'package:kaeru_ui/kaeru_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

class AboutPage extends KaeruWidget<AboutPage> {
  const AboutPage({super.key});

  static const _authorUrl = 'https://github.com/tachibana-shin';
  static const _repoUrl = 'https://github.com/tachibana-shin/koreader_remote_turner';
  static const _licenseUrl = 'https://www.gnu.org/licenses/agpl-3.0.html';
  static const _donateUrl = 'https://github.com/sponsors/tachibana-shin';

  @override
  Setup setup() {
    final ctx = useContext();

    return () {
      final t = AppLocalizations.of(ctx)!;

      return [
        Icons.menu_book.toIcon(size: 64, color: ctx.theme.colorScheme.primary),
        8.vSpace,
        t.aboutTitle.text.headlineSmall.make(),
        8.vSpace,
        t.appDescription.text.bodyLarge.gray(600).make(),
        24.vSpace,
        [
          _UrlTile(icon: Icons.person, label: t.aboutAuthor, subtitle: 'tachibana-shin', url: _authorUrl),
          const Divider(height: 1),
          _UrlTile(icon: Icons.code, label: t.aboutRepo, subtitle: _repoUrl, url: _repoUrl),
          const Divider(height: 1),
          _UrlTile(icon: Icons.description, label: t.aboutLicense, subtitle: 'GNU AGPL v3', url: _licenseUrl),
          const Divider(height: 1),
          _UrlTile(icon: Icons.favorite, label: t.aboutDonate, subtitle: 'GitHub Sponsors', url: _donateUrl),
        ].column().card(),
      ].column(crossAxisAlignment: CrossAxisAlignment.start).p(16).scrollable();
    };
  }
}

class _UrlTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final String url;

  const _UrlTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: label.text.make(),
      subtitle: subtitle.text.color(Theme.of(context).colorScheme.primary).make(),
      trailing: Icons.open_in_new.toIcon(size: 18),
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    );
  }
}
