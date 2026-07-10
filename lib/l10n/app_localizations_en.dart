// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get settings => 'Settings';

  @override
  String get light => 'Light';

  @override
  String get auto => 'Auto';

  @override
  String get dark => 'Dark';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get logout => 'Logout';

  @override
  String get whereTo => 'Where to?';

  @override
  String get home => 'Home';

  @override
  String get saved => 'Saved';

  @override
  String get savedRoutesTitle => 'Saved Routes';

  @override
  String get savedRoutesSubtitle => 'Your favorite routes will appear here';

  @override
  String get noSavedRoutes =>
      'No saved routes yet. Tap the save button on any route details card to add it to your list.';

  @override
  String get eta => 'ETA';

  @override
  String get min => 'min';

  @override
  String routeSavedLocally(int count) {
    return '$count route(s) saved locally';
  }

  @override
  String get clear => 'Clear';

  @override
  String get moderate => 'Moderate';

  @override
  String get crowded => 'Crowded';

  @override
  String get searchingRoute => 'Searching route…';

  @override
  String get noRouteFound => 'No route found — try again';

  @override
  String toDestination(String destination) {
    return 'To: $destination';
  }
}
