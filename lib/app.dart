import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaeru/kaeru.dart';
import 'package:kaeru_ui/kaeru_ui.dart';
import 'l10n/app_localizations.dart';
import 'models/server_state.dart';
import 'pages/about_page.dart';
import 'pages/home_page.dart';
import 'pages/logs_page.dart';
import 'pages/settings_page.dart';
import 'services/keyboard_listener.dart';
import 'services/platform_service.dart';
import 'services/settings_service.dart';
import 'services/password_auth.dart';
import 'services/websocket_server.dart';

class App extends KaeruWidget<App> {
  final ValueChanged<ThemeMode> onThemeChanged;

  const App({super.key, required this.onThemeChanged});

  @override
  Setup setup() {
    final ctx = useContext();
    final currentTab = ref(0);
    final serverState = ServerState();
    final keyboardService = KeyboardListenerService();
    final passwordAuth = PasswordAuth();
    final settingsService = SettingsService();
    final wsServer = WebSocketServer(state: serverState, auth: passwordAuth);
    final focusNode = useFocusNode();

    useListen(keyboardService.actionRef, () {
      final action = keyboardService.actionRef.value;
      if (action != null) {
        switch (action) {
          case KeyAction.forward:
            wsServer.sendAction('next_page');
          case KeyAction.backward:
            wsServer.sendAction('prev_page');
          case KeyAction.sleep:
            wsServer.sendAction('sleep');
        }
      }
    });

    onMounted(() async {
      await keyboardService.loadConfig();
      await passwordAuth.load();
      await serverState.logger.init();
      serverState.replayLogs();

      PlatformService.volumeEvents.listen((event) {
        final key = event == 'volume_up'
            ? LogicalKeyboardKey.audioVolumeUp
            : LogicalKeyboardKey.audioVolumeDown;
        final action = keyboardService.actionForKey(key);
        if (action != null) keyboardService.actionRef.value = action;
      });

      await settingsService.getAutoStart().then((auto) {
        if (auto) wsServer.start();
      });
    });

    onBeforeUnmount(wsServer.dispose);

    Widget pageBody(int tab) {
      final pages = <Widget>[
        HomePage(
          serverState: serverState,
          wsServer: wsServer,
          forwardLabel: AppLocalizations.of(ctx)!.eventForward,
          backwardLabel: AppLocalizations.of(ctx)!.eventBackward,
        ),
        LogsPage(serverState: serverState),
        SettingsPage(
          serverState: serverState,
          keyboardService: keyboardService,
          passwordAuth: passwordAuth,
          settingsService: settingsService,
          onThemeChanged: onThemeChanged,
        ),
        const AboutPage(),
      ];
      return IndexedStack(index: tab, children: pages);
    }

    return () {
      final t = AppLocalizations.of(ctx)!;

      final destinations = [
        NavigationDestination(
          icon: Icons.home_outlined.toIcon(),
          selectedIcon: Icons.home.toIcon(),
          label: t.tabHome,
        ),
        NavigationDestination(
          icon: Icons.list_alt_outlined.toIcon(),
          selectedIcon: Icons.list_alt.toIcon(),
          label: t.tabLogs,
        ),
        NavigationDestination(
          icon: Icons.settings_outlined.toIcon(),
          selectedIcon: Icons.settings.toIcon(),
          label: t.tabSettings,
        ),
        NavigationDestination(
          icon: Icons.info_outline.toIcon(),
          selectedIcon: Icons.info.toIcon(),
          label: t.tabAbout,
        ),
      ];

      final railDestinations = <NavigationRailDestination>[
        NavigationRailDestination(
          icon: Icons.home_outlined.toIcon(),
          selectedIcon: Icons.home.toIcon(),
          label: t.tabHome.text.make(),
        ),
        NavigationRailDestination(
          icon: Icons.list_alt_outlined.toIcon(),
          selectedIcon: Icons.list_alt.toIcon(),
          label: t.tabLogs.text.make(),
        ),
        NavigationRailDestination(
          icon: Icons.settings_outlined.toIcon(),
          selectedIcon: Icons.settings.toIcon(),
          label: t.tabSettings.text.make(),
        ),
        NavigationRailDestination(
          icon: Icons.info_outline.toIcon(),
          selectedIcon: Icons.info.toIcon(),
          label: t.tabAbout.text.make(),
        ),
      ];

      return KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          final result = keyboardService.handleKeyEvent(event);
          if (result != null) {
            switch (result) {
              case KeyAction.forward:
                wsServer.sendAction('next_page');
              case KeyAction.backward:
                wsServer.sendAction('prev_page');
              case KeyAction.sleep:
                wsServer.sendAction('sleep');
            }
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Watch(() {
              if (constraints.maxWidth > 720) {
                return [
                  NavigationRail(
                    selectedIndex: currentTab.value,
                    onDestinationSelected: (i) {
                      currentTab.value = i;
                      keyboardService.startListening();
                      focusNode.requestFocus();
                    },
                    labelType: NavigationRailLabelType.all,
                    destinations: railDestinations,
                  ),
                  const VerticalDivider(width: 1),
                  Scaffold(
                    body: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: pageBody(currentTab.value),
                      ),
                    ),
                  ).expand(),
                ].row();
              }

              return Scaffold(
                body: pageBody(currentTab.value),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: currentTab.value,
                  onDestinationSelected: (i) {
                    currentTab.value = i;
                    keyboardService.startListening();
                    focusNode.requestFocus();
                  },
                  destinations: destinations,
                ),
              );
            });
          },
        ),
      );
    };
  }
}
