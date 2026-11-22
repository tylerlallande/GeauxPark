import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/parking_lot_layout.dart';

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
  String get mapTilesNotConfigured =>
      'A production map provider has not been configured. Parking lots remain available in the list below.';
  String get retry => 'Try again';
  String get retryAction => 'Retry';
  String get drive => 'Drive';
  String get walk => 'Walk';
  String get parkingDetails => 'Parking details';
  String get distance => 'Distance';
  String get price => 'Price';
  String get available => 'Available';
  String get amenities => 'Amenities';
  String get informationNotProvided => 'Information not provided yet.';
  String loadingDetails(String lotName) => 'Loading details for $lotName';
  String couldNotLoad(String lotName) => 'Could not load $lotName';
  String get checkConnection => 'Check your connection and try again.';
  String get tryLocationAgain => 'Try location again';
  String get viewIndividualSpaces => 'View individual parking spaces';
  String get viewIndividualSpacesDescription =>
      'See verified space boundaries and occupancy when available.';
  String get aboutLocation => 'About this location';
  String get hours => 'Hours';
  String get gameDayInformation => 'Game-day information';
  String get couldNotOpenMaps => 'Could not open maps. Please try again.';
  String get calculateDirectionsTitle => 'Calculate driving directions?';
  String get calculateDirectionsMessage =>
      'To calculate a road route, GeauxPark sends your current location and destination coordinates to the public OSRM routing service.';
  String get notNow => 'Not now';
  String get calculateRoute => 'Calculate route';
  String get currentLocationGoogleMaps =>
      'From your current location · Opens Google Maps';
  String get openingGoogleMaps => 'Opening Google Maps…';
  String get findingDrivingRoute => 'Finding a driving route…';
  String get drivingDirections => 'Driving directions';
  String get roadDirectionsError =>
      'Could not load road directions. Check your connection and try again.';
  String get googleMapsOpenError =>
      'Could not open Google Maps. Please try again.';
  String get zoomIn => 'Zoom in';
  String get zoomOut => 'Zoom out';
  String get stopLiveLocation => 'Stop live location';
  String get useLiveLocation => 'Use my live location';
  String get availability => 'Availability:';
  String get eligible => 'Eligible';
  String get permitRestricted => 'Permit restricted';
  String lotSpaces(String lotName) => '$lotName spaces';
  String get spaceMapUnavailable => 'Space map unavailable';
  String get spaceMapLoadError =>
      'Could not load this lot right now. Please try again.';
  String get verifiedSpaceMapComingSoon => 'Verified space map coming soon';
  String get verifiedSpaceMapPending =>
      'This lot is ready for space-level data, but verified parking-space boundaries and live occupancy are not connected yet.';
  String get tapSpaceHelp => 'Tap a space to check its latest reported status.';
  String source(String sourceLabel) => 'Source: $sourceLabel';
  String parkingSpaceStatus(ParkingSpaceStatus status) => switch (status) {
    ParkingSpaceStatus.unknown => 'status unknown',
    ParkingSpaceStatus.available => 'available',
    ParkingSpaceStatus.occupied => 'occupied',
    ParkingSpaceStatus.unavailable => 'unavailable',
  };
  String get quickFilters => 'Quick filters';
  String get bestMatchForYou => 'Best match for you';
  String get reviewLotAndDirections =>
      'Review this lot, then get directions when you are ready.';
  String get lotTypes => 'Lot types';
  String get parkingNearLsu => 'Parking near LSU';
  String get findYourParking => 'Find your parking';
  String get confidentNextMove => 'Make your next move with confidence.';
  String get searchHint => 'Search lots, garages, or streets';
  String get clear => 'Clear';
  String get myPermits => 'My permits';
  String get availableNow => 'Available now';
  String get free => 'Free';
  String get accessible => 'Accessible';
  String get lotTypeHelp =>
      'Choose any type. Quick filters narrow your results further.';
  String results(int count) => '$count results';
  String get yourParking => 'Your parking';
  String get parkingPermits => 'Parking permits';
  String get savedParkingLoadError => 'Could not load saved parking.';
  String get findParking => 'Find parking';
  String get savedParking => 'Saved parking';
  String savedLocationCount(int count) =>
      '$count saved ${count == 1 ? 'location' : 'locations'}';
  String get noSavedParking => 'No saved parking yet';
  String get noSavedParkingHelp =>
      'Tap the bookmark on a parking lot to keep it here.';
  String get permitSetupTitle => 'Choose your parking permits';
  String get permitSetupDescription =>
      'GeauxPark can highlight lots you can use and dim restricted ones.';
  String get addPermitsHelp =>
      'Add your parking permits to see which lots you can use.';
  String get managePermits => 'Manage permits';
  String get permitPreferencesDescription =>
      'Choose every permit you can use. GeauxPark will highlight eligible lots and dim restricted ones.';
  String get noPermitsSelected =>
      'No permits selected. All lots remain visible until you personalize eligibility.';
  String selectedPermitCount(int count) =>
      '$count ${count == 1 ? 'permit' : 'permits'} selected';
  String get commandCenter => 'LSU PARKING COMMAND CENTER';
  String get noParkingFound => 'No parking found';
  String get noParkingFoundHelp =>
      'Try another search or choose a different filter.';
  String get usingOfflineData => 'Using offline parking data for this session.';
  String get permitUpdateError =>
      'Could not update parking permits. Try again.';
  String get savedParkingUpdateError =>
      'Could not update saved parking. Try again.';
  String get availabilityReportError =>
      'Could not save the availability report. Try again.';
  String reportedAs(String lotName, String status) =>
      '$lotName reported as $status.';
  String get appProblemTitle => 'GeauxPark ran into a problem.';
  String get appProblemDescription =>
      'Your saved parking and permit preferences are still on this device.';
  String get liveParkingConnected => 'Live parking catalog connected';
  String get serverUnavailableReferenceData =>
      'Live service unavailable — availability may be out of date';
  String get visitorHelpTitle => 'Visiting LSU? Start here';
  String get visitorHelpDescription =>
      'The Welcome Center offers visitor permits, parking help, maps, and directions.';
  String worksWithPermit(bool eligible) =>
      eligible ? 'Works with your permit' : 'Permit not accepted';
  String saveLot(String lotName, {required bool saved}) =>
      saved ? 'Unsave $lotName' : 'Save $lotName';
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
