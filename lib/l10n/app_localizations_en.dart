// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KOReader Remote';

  @override
  String get appDescription => 'A remote controller for KOReader e-book reader';

  @override
  String get tabAbout => 'About';

  @override
  String get tabHome => 'Home';

  @override
  String get tabLogs => 'Logs';

  @override
  String get tabSettings => 'Settings';

  @override
  String get aboutTitle => 'KOReader Remote';

  @override
  String get aboutAuthor => 'Author';

  @override
  String get aboutRepo => 'Repository';

  @override
  String get aboutLicense => 'License';

  @override
  String get aboutDonate => 'Donate';

  @override
  String get connectionStatusOff => 'Server is off';

  @override
  String get connectionStatusWaiting => 'Waiting for connection...';

  @override
  String connectionStatusConnected(Object deviceName) {
    return 'Connected: $deviceName';
  }

  @override
  String get serverStart => 'Start Server';

  @override
  String get serverStop => 'Stop Server';

  @override
  String serverInfo(Object address, Object port) {
    return 'Server: $address:$port';
  }

  @override
  String totalEvents(Object count) {
    return 'Total events: $count';
  }

  @override
  String avgSpeed(Object speed) {
    return 'Avg speed: $speed/min';
  }

  @override
  String get eventForward => 'Forward';

  @override
  String get eventBackward => 'Backward';

  @override
  String get eventSleep => 'Sleep';

  @override
  String get xiaomiNote =>
      'Note: Xiaomi HyperOS/MiUI devices need to disable \"Pause app activity if unused\" and set battery to \"No restrictions\"';

  @override
  String get logTitle => 'Event Logs';

  @override
  String get logEmpty => 'No events yet';

  @override
  String get logTime => 'Time';

  @override
  String get logEvent => 'Event';

  @override
  String get logStatus => 'Status';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsPort => 'Server Port';

  @override
  String get settingsTimeout => 'Auto-shutdown timeout (minutes)';

  @override
  String get settingsTimeoutNone => 'Never';

  @override
  String get settingsKeyMapping => 'Key Mapping';

  @override
  String get settingsKeyForward => 'Forward key';

  @override
  String get settingsKeyBackward => 'Backward key';

  @override
  String get settingsKeySleep => 'Sleep key';

  @override
  String get settingsAutoStart => 'Auto-start server on app launch';

  @override
  String get settingsOnlyWhileOpen => 'Only listen when app is open';

  @override
  String get settingsPassword => 'Connection Password';

  @override
  String get settingsPasswordNone => 'No password';

  @override
  String get settingsPasswordSet => 'Set password';

  @override
  String get settingsSave => 'Save';

  @override
  String get volumeUp => 'Volume Up';

  @override
  String get volumeDown => 'Volume Down';

  @override
  String get enter => 'Enter';

  @override
  String get none => 'None';
}
