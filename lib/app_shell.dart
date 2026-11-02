import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/parking_lot.dart';
import 'repositories/demo_parking_repository.dart';
import 'repositories/parking_repository.dart';
import 'screens/home_screen.dart';
import 'screens/parking_details_screen.dart';
import 'screens/parking_map_screen.dart';
import 'screens/placeholder_screen.dart';
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
  static const _savedLotsKey = 'saved_parking_lot_ids';
  SharedPreferences? _preferences;
  Set<String> _savedLotIds = {};
  bool _saving = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLots();
  }

  Future<void> _loadSavedLots() async {
    setState(() => _loadFailed = false);
    try {
      final preferences = await SharedPreferences.getInstance();
      final ids = preferences.getStringList(_savedLotsKey) ?? [];
      if (!mounted) return;
      setState(() {
        _preferences = preferences;
        _savedLotIds = ids.toSet();
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

  void _openParkingDetails(ParkingLot lot) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ParkingDetailsScreen(
          lot: lot,
          repository: widget.parkingRepository,
          initiallySaved: _savedLotIds.contains(lot.id),
          onToggleSaved: _preferences == null ? null : _toggleSaved,
        ),
      ),
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
        savedLotIds: _savedLotIds,
        onToggleSaved: _preferences == null || _saving ? null : _toggleSaved,
        onLotSelected: _openParkingDetails,
      ),
      ParkingMapScreen(
        savedLotIds: _savedLotIds,
        onLotSelected: _openParkingDetails,
      ),
      SavedScreen(
        savedLotIds: _savedLotIds,
        isLoading: _preferences == null,
        loadFailed: _loadFailed,
        onRetry: _loadSavedLots,
        onToggleSaved: _preferences == null || _saving ? null : _toggleSaved,
        onBrowseParking: () => setState(() => _selectedIndex = 0),
        onLotSelected: _openParkingDetails,
      ),
      const PlaceholderScreen(
        icon: Icons.person_outline_rounded,
        title: 'Your profile',
        message: 'Manage preferences and account details here.',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: screens),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.secondary
            .withValues(alpha: 0.32),
        elevation: 8,
        shadowColor: Theme.of(context).colorScheme.primary
            .withValues(alpha: 0.14),
        selectedIndex: _selectedIndex,
        destinations: _destinations,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}
