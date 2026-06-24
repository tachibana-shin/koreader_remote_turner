import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'KOReader Remote'**
  String get appTitle;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'A remote controller for KOReader e-book reader'**
  String get appDescription;

  /// No description provided for @tabAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get tabAbout;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get tabLogs;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'KOReader Remote'**
  String get aboutTitle;

  /// No description provided for @aboutAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get aboutAuthor;

  /// No description provided for @aboutRepo.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get aboutRepo;

  /// No description provided for @aboutLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get aboutLicense;

  /// No description provided for @aboutDonate.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get aboutDonate;

  /// No description provided for @connectionStatusOff.
  ///
  /// In en, this message translates to:
  /// **'Server is off'**
  String get connectionStatusOff;

  /// No description provided for @connectionStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection...'**
  String get connectionStatusWaiting;

  /// No description provided for @connectionStatusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected: {deviceName}'**
  String connectionStatusConnected(Object deviceName);

  /// No description provided for @serverStart.
  ///
  /// In en, this message translates to:
  /// **'Start Server'**
  String get serverStart;

  /// No description provided for @serverStop.
  ///
  /// In en, this message translates to:
  /// **'Stop Server'**
  String get serverStop;

  /// No description provided for @serverInfo.
  ///
  /// In en, this message translates to:
  /// **'Server: {address}:{port}'**
  String serverInfo(Object address, Object port);

  /// No description provided for @totalEvents.
  ///
  /// In en, this message translates to:
  /// **'Total events: {count}'**
  String totalEvents(Object count);

  /// No description provided for @avgSpeed.
  ///
  /// In en, this message translates to:
  /// **'Avg speed: {speed}/min'**
  String avgSpeed(Object speed);

  /// No description provided for @eventForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get eventForward;

  /// No description provided for @eventBackward.
  ///
  /// In en, this message translates to:
  /// **'Backward'**
  String get eventBackward;

  /// No description provided for @eventSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get eventSleep;

  /// No description provided for @xiaomiNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Xiaomi HyperOS/MiUI devices need to disable \"Pause app activity if unused\" and set battery to \"No restrictions\"'**
  String get xiaomiNote;

  /// No description provided for @logTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Logs'**
  String get logTitle;

  /// No description provided for @logEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get logEmpty;

  /// No description provided for @logTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get logTime;

  /// No description provided for @logEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get logEvent;

  /// No description provided for @logStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get logStatus;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsPort.
  ///
  /// In en, this message translates to:
  /// **'Server Port'**
  String get settingsPort;

  /// No description provided for @settingsTimeout.
  ///
  /// In en, this message translates to:
  /// **'Auto-shutdown timeout (minutes)'**
  String get settingsTimeout;

  /// No description provided for @settingsTimeoutNone.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get settingsTimeoutNone;

  /// No description provided for @settingsKeyMapping.
  ///
  /// In en, this message translates to:
  /// **'Key Mapping'**
  String get settingsKeyMapping;

  /// No description provided for @settingsKeyForward.
  ///
  /// In en, this message translates to:
  /// **'Forward key'**
  String get settingsKeyForward;

  /// No description provided for @settingsKeyBackward.
  ///
  /// In en, this message translates to:
  /// **'Backward key'**
  String get settingsKeyBackward;

  /// No description provided for @settingsKeySleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep key'**
  String get settingsKeySleep;

  /// No description provided for @settingsAutoStart.
  ///
  /// In en, this message translates to:
  /// **'Auto-start server on app launch'**
  String get settingsAutoStart;

  /// No description provided for @settingsOnlyWhileOpen.
  ///
  /// In en, this message translates to:
  /// **'Only listen when app is open'**
  String get settingsOnlyWhileOpen;

  /// No description provided for @settingsPassword.
  ///
  /// In en, this message translates to:
  /// **'Connection Password'**
  String get settingsPassword;

  /// No description provided for @settingsPasswordNone.
  ///
  /// In en, this message translates to:
  /// **'No password'**
  String get settingsPasswordNone;

  /// No description provided for @settingsPasswordSet.
  ///
  /// In en, this message translates to:
  /// **'Set password'**
  String get settingsPasswordSet;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// No description provided for @volumeUp.
  ///
  /// In en, this message translates to:
  /// **'Volume Up'**
  String get volumeUp;

  /// No description provided for @volumeDown.
  ///
  /// In en, this message translates to:
  /// **'Volume Down'**
  String get volumeDown;

  /// No description provided for @enter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enter;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
