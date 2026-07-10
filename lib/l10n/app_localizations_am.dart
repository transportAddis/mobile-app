// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get language => 'ቋንቋ';

  @override
  String get settings => 'ቅንጅቶች';

  @override
  String get light => 'ብርሀን';

  @override
  String get auto => 'በራስ';

  @override
  String get dark => 'ጨለማ';

  @override
  String get pushNotifications => 'የግፋ ማሳወቂያዎች';

  @override
  String get privacyPolicy => 'የግላዊነት መመሪያ';

  @override
  String get logout => 'ውጣ';

  @override
  String get whereTo => 'ወዴት?';

  @override
  String get home => 'መነሻ';

  @override
  String get saved => 'ተቀምጠዋል';

  @override
  String get savedRoutesTitle => 'የተቀመጡ መስመሮች';

  @override
  String get savedRoutesSubtitle => 'ተወዳጅ መስመሮችዎ እዚህ ይታያሉ';

  @override
  String get noSavedRoutes =>
      'እስካሁን ምንም የተቀመጠ መስመር የለም። ለማስቀመጥ በማናቸውም የመስመር ዝርዝር ካርድ ላይ ያሉ ቁጠባ ቁልፉን ይጫኑ።';

  @override
  String get eta => 'የሚደርስበት ግዜ';

  @override
  String get min => 'ደቂቃ';

  @override
  String routeSavedLocally(int count) {
    return '$count መስመር(ሮች) ተቀምጠዋል';
  }

  @override
  String get clear => 'ክፍት';

  @override
  String get moderate => 'መካከለኛ';

  @override
  String get crowded => 'የተጨናነቀ';

  @override
  String get searchingRoute => 'መስመር በመፈለግ ላይ…';

  @override
  String get noRouteFound => 'ምንም መስመር አልተገኘም — እንደገና ይሞክሩ';

  @override
  String toDestination(String destination) {
    return 'ወደ: $destination';
  }
}
