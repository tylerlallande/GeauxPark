import 'package:flutter/material.dart';

import '../data/sample_parking_lots.dart';
import '../models/parking_lot.dart';
import '../widgets/parking_lot_card.dart';

enum ParkingFilter { all, available, free, accessible }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ParkingFilter _selectedFilter = ParkingFilter.all;
  String _query = '';

  List<ParkingLot> get _visibleLots {
    return sampleParkingLots.where((lot) {
      final normalizedQuery = _query.trim().toLowerCase();
      final matchesSearch =
          normalizedQuery.isEmpty ||
          lot.name.toLowerCase().contains(normalizedQuery) ||
          lot.address.toLowerCase().contains(normalizedQuery);
      final matchesFilter = switch (_selectedFilter) {
        ParkingFilter.all => true,
        ParkingFilter.available => lot.spacesAvailable > 0,
        ParkingFilter.free => lot.priceLabel.toLowerCase().contains('free'),
        ParkingFilter.accessible => lot.isAccessible,
      };
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CustomScrollView(
      key: const PageStorageKey('home-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          sliver: SliverList.list(
            children: [
              _HomeHeader(colors: colors),
              const SizedBox(height: 24),
              Text(
                'Find your parking',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Search near campus before you leave.',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              SearchBar(
                hintText: 'Search lots, garages, or streets',
                leading: const Icon(Icons.search_rounded),
                elevation: const WidgetStatePropertyAll(0),
                side: const WidgetStatePropertyAll(
                  BorderSide(color: Color(0xFFE7E1EC)),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 22),
              _SectionHeading(
                title: 'Quick filters',
                actionLabel: 'Clear',
                onAction: () {
                  setState(() => _selectedFilter = ParkingFilter.all);
                },
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ParkingFilter.values.map((filter) {
                    final label = switch (filter) {
                      ParkingFilter.all => 'All parking',
                      ParkingFilter.available => 'Available now',
                      ParkingFilter.free => 'Free',
                      ParkingFilter.accessible => 'Accessible',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: _selectedFilter == filter,
                        onSelected: (_) {
                          setState(() => _selectedFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              const _GameDayBanner(),
              const SizedBox(height: 28),
              _SectionHeading(
                title: 'Parking near LSU',
                actionLabel: '${_visibleLots.length} results',
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (_visibleLots.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyResults(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            sliver: SliverList.separated(
              itemCount: _visibleLots.length,
              itemBuilder: (context, index) => ParkingLotCard(
                lot: _visibleLots[index],
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${_visibleLots[index].name} details are coming next.',
                      ),
                    ),
                  );
                },
              ),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
            ),
          ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(Icons.local_parking_rounded, color: colors.onPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GeauxPark',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
              Text(
                'Baton Rouge, Louisiana',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Notifications',
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.actionLabel,
    this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (onAction == null)
          Text(
            actionLabel,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          )
        else
          TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _GameDayBanner extends StatelessWidget {
  const _GameDayBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, const Color(0xFF6C3AA0)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.sports_football_rounded, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game-day parking',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Arrive early and check event rates before heading to campus.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.82)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 48),
          const SizedBox(height: 12),
          Text(
            'No parking found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Try another search or choose a different filter.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
