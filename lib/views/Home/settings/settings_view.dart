import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../../../localization/app_locale.dart';
import '../../../shared/custom_app_menu.dart';
import '../../../shared/custom_container.dart';
import '../../../shared/footer.dart';
import '../../../shared/toast_message.dart';
import 'change_password_view.dart';
import 'org_settings_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocale.settings.getString(context))),
      drawer: const MenuDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: CustomContainer(
              maxWidthContainer: 640,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SettingsMenuItem(
                    icon: Icons.business_outlined,
                    title: AppLocale.organizationInfo.getString(context),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrgSettingsPage())),
                  ),
                  _SettingsMenuItem(
                    icon: Icons.shield_outlined,
                    title: AppLocale.changePassword.getString(context),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SettingsContentPage(title: AppLocale.changePassword.getString(context), child: const ChangePasswordCard()),
                      ),
                    ),
                  ),
                  _SettingsMenuItem(
                    icon: Icons.contrast_outlined,
                    title: AppLocale.myProfile.getString(context),
                    subtitle: AppLocale.notAvailableYet.getString(context),
                    enabled: false,
                    onTap: () => _showUnavailable(context),
                  ),
                  _SettingsMenuItem(
                    icon: Icons.contrast_outlined,
                    title: AppLocale.themeAppearance.getString(context),
                    subtitle: AppLocale.notAvailableYet.getString(context),
                    enabled: false,
                    onTap: () => _showUnavailable(context),
                  ),
                  _SettingsMenuItem(
                    icon: Icons.person_add_alt_1_outlined,
                    title: AppLocale.createEmployee.getString(context),
                    subtitle: AppLocale.notAvailableYet.getString(context),
                    enabled: false,
                    onTap: () => _showUnavailable(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomFooter(),
    );
  }

  void _showUnavailable(BuildContext context) {
    ToastMessage.show(context: context, message: AppLocale.notAvailableYet.getString(context), type: ToastType.warning);
  }
}

class SettingsContentPage extends StatelessWidget {
  const SettingsContentPage({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16), child: child),
          ),
        ),
      ),
      bottomNavigationBar: const CustomFooter(),
    );
  }
}

class _SettingsMenuItem extends StatelessWidget {
  const _SettingsMenuItem({required this.icon, required this.title, required this.onTap, this.subtitle, this.enabled = true});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Theme.of(context).primaryColor : Theme.of(context).disabledColor;

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.25)),
      ),
      child: ListTile(
        minTileHeight: 64,
        enabled: enabled,
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: subtitle == null ? null : Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        trailing: enabled ? Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline) : const Icon(Icons.lock_outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
