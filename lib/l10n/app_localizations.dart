import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const delegate = _AppLocalizationsDelegate();
  static const supportedLocales = <Locale>[Locale('en')];

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(Locale('en'));

  String get appTitle => 'GeauxPark';
  String get homeTab => 'Home';
  String get mapTab => 'Map';
  String get savedTab => 'Saved';
  String get profileTab => 'Profile';
  String get parkingMapTitle => 'Parking map';
  String get exploreParkingNearLsu => 'Explore parking near LSU';
  String directionsTo(String lotName) => 'Directions to $lotName';
  String get reportAvailability => 'Report availability';
  String get getDirections => 'Get directions';
  String get gettingLocation => 'Getting your location…';
  String get allParking => 'All parking';
  String get noMatchingParking => 'No parking lots match these tags.';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
