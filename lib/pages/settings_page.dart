import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaeru/kaeru.dart';
import 'package:kaeru_ui/kaeru_ui.dart';
import '../l10n/app_localizations.dart';
import '../models/server_state.dart';
import '../services/keyboard_listener.dart';
import '../services/platform_service.dart';
import '../services/settings_service.dart';
import '../services/password_auth.dart';

class SettingsPage extends KaeruWidget<SettingsPage> {
  final ServerState serverState;
  final KeyboardListenerService keyboardService;
  final PasswordAuth passwordAuth;
  final SettingsService settingsService;
  final ValueChanged<ThemeMode> onThemeChanged;

  const SettingsPage({
    super.key,
    required this.serverState,
    required this.keyboardService,
    required this.passwordAuth,
    required this.settingsService,
    required this.onThemeChanged,
  });

  @override
  Setup setup() {
    final ctx = useContext();
    final portController = useTextEditingController(
      serverState.serverPort.value,
    );
    final forwardKeys = ref<List<LogicalKeyboardKey>>([
      ...keyboardService.config.forwardKeys,
    ]);
    final backwardKeys = ref<List<LogicalKeyboardKey>>([
      ...keyboardService.config.backwardKeys,
    ]);
    final sleepKeys = ref<List<LogicalKeyboardKey>>([
      ...keyboardService.config.sleepKeys,
    ]);
    final onlyWhileOpen = ref(keyboardService.config.onlyWhileOpen);
    final autoStart = ref(true);
    final themeMode = ref(ThemeMode.system);
    final accessibilityEnabled = ref(false);
    onMounted(() async {
      autoStart.value = await settingsService.getAutoStart();
      themeMode.value = await settingsService.getThemeMode();
      accessibilityEnabled.value =
          await PlatformService.isAccessibilityServiceEnabled();
    });

    void saveKeys() {
      keyboardService.saveConfig(
        ButtonConfig(
          forwardKeys: forwardKeys.value,
          backwardKeys: backwardKeys.value,
          sleepKeys: sleepKeys.value,
          onlyWhileOpen: onlyWhileOpen.value,
        ),
      );
    }

    return () {
      final t = AppLocalizations.of(ctx)!;

      return [
        t.settingsTitle.text.headlineSmall.make(),
        24.vSpace,
        t.settingsTheme.text.titleMedium.make(),
        8.vSpace,
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment(
              value: ThemeMode.light,
              icon: const Icon(Icons.light_mode),
              label: t.settingsThemeLight.text.make(),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: const Icon(Icons.dark_mode),
              label: t.settingsThemeDark.text.make(),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              icon: const Icon(Icons.brightness_auto),
              label: t.settingsThemeSystem.text.make(),
            ),
          ],
          selected: {themeMode.value},
          onSelectionChanged: (v) {
            final mode = v.first;
            themeMode.value = mode;
            settingsService.setThemeMode(mode);
            onThemeChanged(mode);
          },
        ),
        24.vSpace,
        t.settingsPort.text.titleMedium.make(),
        8.vSpace,
        TextField(
          controller: portController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '9090',
          ),
          onChanged: (v) {
            final port = int.tryParse(v);
            if (port != null) {
              serverState.serverPort.value = v;
              settingsService.setPort(port);
            }
          },
        ),
        16.vSpace,
        SwitchListTile(
          title: t.settingsAutoStart.text.make(),
          value: autoStart.value,
          onChanged: (v) {
            autoStart.value = v;
            settingsService.setAutoStart(v);
          },
        ),
        24.vSpace,
        t.settingsAccessibility.text.titleMedium.make(),
        8.vSpace,
        ListTile(
          leading: Icons.accessibility_new.toIcon(),
          title: t.settingsAccessibility.text.make(),
          subtitle:
              (accessibilityEnabled.value
                      ? t.settingsAccessibilityEnabled
                      : t.settingsAccessibilityDisabled)
                  .text
                  .size(13)
                  .make(),
          trailing: TextButton(
            onPressed: () =>
                _showAccessibilityDialog(t, ctx, accessibilityEnabled.value),
            child: t.settingsAccessibilityOpenSettings.text.make(),
          ),
          onTap: () =>
              _showAccessibilityDialog(t, ctx, accessibilityEnabled.value),
        ),
        24.vSpace,
        t.settingsKeyMapping.text.titleMedium.make(),
        8.vSpace,
        _KeyRecorder(
          label: t.settingsKeyForward.text.make(),
          keys: forwardKeys.value,
          onChanged: (keys) {
            forwardKeys.value = keys;
            saveKeys();
          },
        ),
        _KeyRecorder(
          label: t.settingsKeyBackward.text.make(),
          keys: backwardKeys.value,
          onChanged: (keys) {
            backwardKeys.value = keys;
            saveKeys();
          },
        ),
        _KeyRecorder(
          label: t.settingsKeySleep.text.make(),
          keys: sleepKeys.value,
          onChanged: (keys) {
            sleepKeys.value = keys;
            saveKeys();
          },
        ),
        16.vSpace,
        SwitchListTile(
          title: t.settingsOnlyWhileOpen.text.make(),
          value: onlyWhileOpen.value,
          onChanged: (v) {
            onlyWhileOpen.value = v;
            saveKeys();
          },
        ),
        24.vSpace,
        t.settingsPassword.text.titleMedium.make(),
        8.vSpace,
        ListTile(
          title:
              (passwordAuth.hasPassword ? '********' : t.settingsPasswordNone)
                  .text
                  .make(),
          trailing: TextButton(
            onPressed: () => _showPasswordDialog(t, ctx),
            child: t.settingsPasswordSet.text.make(),
          ),
        ),
      ].column(crossAxisAlignment: CrossAxisAlignment.start).p(16).scrollable();
    };
  }

  void _showAccessibilityDialog(
    AppLocalizations t,
    BuildContext ctx,
    bool isEnabled,
  ) {
    if (isEnabled) {
      PlatformService.openAccessibilitySettings();
      return;
    }
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        title: t.settingsAccessibility.text.make(),
        content: [t.settingsAccessibilityDescription.text.make()].column(),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: t.cancel.text.make(),
          ),
          FilledButton.icon(
            icon: Icons.settings.toIcon(),
            onPressed: () {
              Navigator.of(c).pop();
              PlatformService.openAccessibilitySettings();
            },
            label: t.settingsAccessibilityOpenSettings.text.make(),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(AppLocalizations t, BuildContext ctx) {
    final controller = TextEditingController();

    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        title: t.settingsPassword.text.make(),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: t.settingsPasswordSet,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              passwordAuth.setPassword(null);
              Navigator.of(c).pop();
            },
            child: t.settingsPasswordNone.text.make(),
          ),
          FilledButton(
            onPressed: () {
              passwordAuth.setPassword(controller.text);
              Navigator.of(c).pop();
            },
            child: t.settingsPasswordSet.text.make(),
          ),
        ],
      ),
    );
  }
}

class _KeyRecorder extends StatelessWidget {
  final Widget label;
  final List<LogicalKeyboardKey> keys;
  final ValueChanged<List<LogicalKeyboardKey>> onChanged;

  const _KeyRecorder({
    required this.label,
    required this.keys,
    required this.onChanged,
  });

  Future<LogicalKeyboardKey?> _recordKey(BuildContext context) {
    final completer = Completer<LogicalKeyboardKey?>();
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (c) => AlertDialog(
        content: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent && !completer.isCompleted) {
              completer.complete(event.logicalKey);
              Navigator.of(c).pop();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Press any key...'),
          ),
        ),
      ),
    ).then((_) {
      if (!completer.isCompleted) completer.complete(null);
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: [
        label,
        8.vSpace,
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...keys.map(
              (key) => Chip(
                label: KnownKeys.nameOf(key).text.size(13).make(),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  final updated = List<LogicalKeyboardKey>.from(keys)
                    ..remove(key);
                  onChanged(updated);
                },
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: 'Add'.text.size(13).make(),
              onPressed: () async {
                final key = await _recordKey(context);
                if (key != null && !keys.contains(key)) {
                  final updated = List<LogicalKeyboardKey>.from(keys)..add(key);
                  onChanged(updated);
                }
              },
            ),
          ],
        ),
      ].column(crossAxisAlignment: CrossAxisAlignment.start),
    );
  }
}
