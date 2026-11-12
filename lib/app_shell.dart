import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/sample_game_day.dart';
import 'data/sample_parking_lots.dart';
import 'models/parking_lot.dart';
import 'models/parking_details.dart';
import 'models/parking_permit.dart';
import 'models/parking_availability.dart';
import 'repositories/demo_parking_repository.dart';
import 'repositories/local_occupancy_report_repository.dart';
import 'repositories/parking_repository.dart';
import 'screens/game_day_screen.dart';
import 'screens/home_screen.dart';
import 'screens/parking_details_screen.dart';
import 'screens/parking_map_screen.dart';
import 'screens/permit_preferences_screen.dart';
import 'screens/saved_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.parkingRepository = const DemoParkingRepository(),
  });

  final ParkingRepository parkingRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  static const _savedLotsKey = 'saved_parking_lot_ids';
  static const _parkingPermitsKey = 'selected_parking_permit_ids';
  SharedPreferences? _preferences;
  Set<String> _savedLotIds = {};
  List<ParkingLot> _parkingLots = sampleParkingLots;
  Set<ParkingPermit> _selectedPermits = {};
  Map<String, OccupancyReport> _occupancyReports = {};
  bool _saving = false;
  bool _savingPermits = false;
  final Set<String> _savingReportLotIds = {};
  bool _loadFailed = false;
  String? _mapDirectionsLotId;
  LatLng? _mapDirectionsOrigin;
  int? _swipePointer;
  Offset? _swipeStartPosition;
  DateTime? _swipeStartTime;

  @override
  void initState() {
    super.initState();
    _loadSavedLots();
    _loadParkingLots();
  }

  Future<void> _loadParkingLots() async {
    try {
      final lots = await widget.parkingRepository.fetchParkingLots();
      if (!mounted || lots.isEmpty) return;
      setState(() => _parkingLots = lots);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Using offline parking data for this session.'),
        ),
      );
    }
  }

  Future<void> _loadSavedLots() async {
    setState(() => _loadFailed = false);
    try {
      final preferences = await SharedPreferences.getInstance();
      final ids = preferences.getStringList(_savedLotsKey) ?? [];
      final permits = (preferences.getStringList(_parkingPermitsKey) ?? [])
          .map(parkingPermitFromId)
          .whereType<ParkingPermit>()
          .toSet();
      final reports = await LocalOccupancyReportRepository(preferences)
          .loadReports();
      if (!mounted) return;
      setState(() {
        _preferences = preferences;
        _savedLotIds = ids.toSet();
        _selectedPermits = permits;
        _occupancyReports = reports;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Could not load saved parking. Please try again.',
          ),
          action: SnackBarAction(label: 'Retry', onPressed: _loadSavedLots),
        ),
      );
    }
  }

  Future<bool> _updateParkingPermits(Set<ParkingPermit> permits) async {
    final preferences = _preferences;
    if (preferences == null || _savingPermits) return false;
    setState(() => _savingPermits = true);
    try {
      final ids = permits.map((permit) => permit.id).toList()..sort();
      final saved = await preferences.setStringList(_parkingPermitsKey, ids);
      if (!saved) throw StateError('Could not save parking permits');
      if (!mounted) return false;
      setState(() => _selectedPermits = {...permits});
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update parking permits. Try again.'),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _savingPermits = false);
    }
  }

  Future<bool> _toggleSaved(ParkingLot lot) async {
    final preferences = _preferences;
    if (preferences == null || _saving) return false;
    final nextIds = {..._savedLotIds};
    if (!nextIds.remove(lot.id)) nextIds.add(lot.id);
    setState(() => _saving = true);
    try {
      final saved = await preferences.setStringList(
        _savedLotsKey,
        nextIds.toList()..sort(),
      );
      if (!saved) throw StateError('Could not save parking');
      if (!mounted) return false;
      setState(() => _savedLotIds = nextIds);
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update saved parking. Try again.'),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _submitOccupancyReport(
    ParkingLot lot,
    ParkingAvailabilityStatus status,
  ) async {
    final preferences = _preferences;
    if (preferences == null || _savingReportLotIds.contains(lot.id)) {
      return false;
    }
    setState(() => _savingReportLotIds.add(lot.id));
    final report = OccupancyReport(
      lotId: lot.id,
      status: status,
      reportedAt: DateTime.now(),
    );
    try {
      await LocalOccupancyReportRepository(preferences).saveReport(report);
      if (!mounted) return false;
      setState(
        () => _occupancyReports = {..._occupancyReports, lot.id: report},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${lot.name} reported as ${status.label}.')),
      );
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the availability report. Try again.'),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _savingReportLotIds.remove(lot.id));
    }
  }

  void _openParkingDetails(ParkingLot lot) {
    Navigator.of(context).push(
      _smoothRoute(
        ParkingDetailsScreen(
          lot: lot,
          repository: widget.parkingRepository,
          initiallySaved: _savedLotIds.contains(lot.id),
          onToggleSaved: _preferences == null ? null : _toggleSaved,
          onOpenMapDirections: _openMapDirections,
          selectedPermits: _selectedPermits,
          occupancyReport: _occupancyReports[lot.id],
          onReportAvailability: _preferences == null
              ? null
              : _submitOccupancyReport,
        ),
      ),
    );
  }

  void _openMapDirections((ParkingDetails, LatLng) request) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() {
      _mapDirectionsLotId = request.$1.lotId;
      _mapDirectionsOrigin = request.$2;
    });
    _selectTab(1);
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    if (!_pageController.hasClients) {
      setState(() => _selectedIndex = index);
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _startSwipe(PointerDownEvent event) {
    _swipePointer = event.pointer;
    _swipeStartPosition = event.position;
    _swipeStartTime = DateTime.now();
  }

  void _finishSwipe(PointerUpEvent event) {
    if (_swipePointer != event.pointer ||
        _swipeStartPosition == null ||
        _swipeStartTime == null) {
      _resetSwipe();
      return;
    }
    final delta = event.position - _swipeStartPosition!;
    final elapsed = DateTime.now().difference(_swipeStartTime!);
    _resetSwipe();

    final isDeliberateHorizontalSwipe =
        delta.dx.abs() >= 140 &&
        delta.dx.abs() > delta.dy.abs() * 1.5 &&
        elapsed <= const Duration(milliseconds: 700);
    if (!isDeliberateHorizontalSwipe) return;

    final nextIndex = delta.dx < 0
        ? (_selectedIndex + 1).clamp(0, _destinations.length - 1)
        : (_selectedIndex - 1).clamp(0, _destinations.length - 1);
    _selectTab(nextIndex);
  }

  void _resetSwipe() {
    _swipePointer = null;
    _swipeStartPosition = null;
    _swipeStartTime = null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openGameDay() {
    Navigator.of(context).push(
      _smoothRoute(
        GameDayScreen(
          plan: sampleGameDayPlan,
          lots: _parkingLots,
          onLotSelected: _openParkingDetails,
        ),
      ),
    );
  }

  Route<void> _smoothRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.025),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map_rounded),
      label: 'Map',
    ),
    NavigationDestination(
      icon: Icon(Icons.bookmark_border_rounded),
      selectedIcon: Icon(Icons.bookmark_rounded),
      label: 'Saved',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(
        lots: _parkingLots,
        savedLotIds: _savedLotIds,
        onToggleSaved: _preferences == null || _saving ? null : _toggleSaved,
        onLotSelected: _openParkingDetails,
        onGameDaySelected: _openGameDay,
        selectedPermits: _selectedPermits,
        occupancyReports: _occupancyReports,
        onManagePermits: () => _selectTab(3),
      ),
      ParkingMapScreen(
        lots: _parkingLots,
        savedLotIds: _savedLotIds,
        onLotSelected: _openParkingDetails,
        selectedPermits: _selectedPermits,
        directionsLotId: _mapDirectionsLotId,
        directionsOrigin: _mapDirectionsOrigin,
        occupancyReports: _occupancyReports,
        onReportAvailability: _preferences == null
            ? null
            : _submitOccupancyReport,
      ),
      SavedScreen(
        lots: _parkingLots,
        savedLotIds: _savedLotIds,
        isLoading: _preferences == null,
        loadFailed: _loadFailed,
        onRetry: _loadSavedLots,
        onToggleSaved: _preferences == null || _saving ? null : _toggleSaved,
        onBrowseParking: () => _selectTab(0),
        onLotSelected: _openParkingDetails,
        selectedPermits: _selectedPermits,
        occupancyReports: _occupancyReports,
      ),
      PermitPreferencesScreen(
        selectedPermits: _selectedPermits,
        isLoading: _preferences == null || _savingPermits,
        onSelectionChanged: _preferences == null ? null : _updateParkingPermits,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _startSwipe,
          onPointerUp: _finishSwipe,
          onPointerCancel: (_) => _resetSwipe(),
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: screens.length,
            onPageChanged: (index) => setState(() => _selectedIndex = index),
            itemBuilder: (context, index) => _KeepAliveTab(
              active: index == _selectedIndex,
              child: screens[index],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: _destinations,
        onDestinationSelected: _selectTab,
      ),
    );
  }
}

class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return TickerMode(
      enabled: widget.active,
      child: RepaintBoundary(child: widget.child),
    );
  }
}
