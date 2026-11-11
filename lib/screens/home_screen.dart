import 'package:flutter/material.dart';

import '../models/parking_lot.dart';
import '../models/parking_permit.dart';
import '../models/parking_availability.dart';
import '../theme/app_theme.dart';
import '../widgets/parking_lot_card.dart';

enum ParkingFilter { all, myPermits, available, free, accessible }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.lots,
    required this.savedLotIds,
    required this.onToggleSaved,
    required this.onLotSelected,
    required this.selectedPermits,
    this.occupancyReports = const {},
    this.onGameDaySelected,
    this.onManagePermits,
  });

  final List<ParkingLot> lots;
  final Set<String> savedLotIds;
  final ValueChanged<ParkingLot>? onToggleSaved;
  final ValueChanged<ParkingLot> onLotSelected;
  final Set<ParkingPermit> selectedPermits;
  final Map<String, OccupancyReport> occupancyReports;
  final VoidCallback? onGameDaySelected;
  final VoidCallback? onManagePermits;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<ParkingFilter> _selectedFilters = {};
  final Set<ParkingTag> _selectedTags = {};
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ParkingLot> get _visibleLots {
    final matches = widget.lots.where((lot) {
      final normalizedQuery = _query.trim().toLowerCase();
      final matchesSearch =
          normalizedQuery.isEmpty ||
          lot.name.toLowerCase().contains(normalizedQuery) ||
          lot.address.toLowerCase().contains(normalizedQuery) ||
          lot.tags.any(
            (tag) => tag.label.toLowerCase().contains(normalizedQuery),
          );
      final matchesFilters = _selectedFilters.every(
        (filter) => switch (filter) {
          ParkingFilter.all => true,
          ParkingFilter.myPermits =>
            lot.eligibilityFor(widget.selectedPermits) !=
                PermitEligibility.ineligible,
          ParkingFilter.available => lot.isAvailable,
          ParkingFilter.free => lot.priceLabel.toLowerCase().contains('free'),
          ParkingFilter.accessible => lot.isAccessible == true,
        },
      );
      final matchesTags =
          _selectedTags.isEmpty || lot.tags.any(_selectedTags.contains);
      return matchesSearch && matchesFilters && matchesTags;
    }).toList();
    // Keep the existing order within each permit group.
    return [
      ...matches.where(
        (lot) =>
            lot.eligibilityFor(widget.selectedPermits) !=
            PermitEligibility.ineligible,
      ),
      ...matches.where(
        (lot) =>
            lot.eligibilityFor(widget.selectedPermits) ==
            PermitEligibility.ineligible,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CustomScrollView(
      key: const PageStorageKey('home-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.sm,
          ),
          sliver: SliverList.list(
            children: [
              _HomeHeader(colors: colors),
              const SizedBox(height: 28),
              Text(
                'Find your parking',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Make your next move with confidence.',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              SearchBar(
                controller: _searchController,
                hintText: 'Search lots, garages, or streets',
                leading: const Icon(Icons.search_rounded),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 22),
              _SectionHeading(
                title: 'Quick filters',
                actionLabel: 'Clear',
                onAction: () {
                  _searchController.clear();
                  setState(() {
                    _selectedFilters.clear();
                    _selectedTags.clear();
                    _query = '';
                  });
                },
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                // Let chips scroll under the screen margin instead of being
                // cut off at the padding edge.
                clipBehavior: Clip.none,
                child: Row(
                  children: ParkingFilter.values.map((filter) {
                    final label = switch (filter) {
                      ParkingFilter.all => 'All parking',
                      ParkingFilter.myPermits => 'My permits',
                      ParkingFilter.available => 'Available now',
                      ParkingFilter.free => 'Free',
                      ParkingFilter.accessible => 'Accessible',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        key: ValueKey('quick-filter-${filter.name}'),
                        label: Text(label),
                        selected: filter == ParkingFilter.all
                            ? _selectedFilters.isEmpty && _selectedTags.isEmpty
                            : _selectedFilters.contains(filter),
                        onSelected:
                            filter == ParkingFilter.myPermits &&
                                widget.selectedPermits.isEmpty
                            ? null
                            : (selected) {
                                setState(() {
                                  if (filter == ParkingFilter.all) {
                                    _selectedFilters.clear();
                                    _selectedTags.clear();
                                  } else if (selected) {
                                    _selectedFilters.add(filter);
                                  } else {
                                    _selectedFilters.remove(filter);
                                  }
                                });
                              },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),
              Text('Lot types', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Choose any type. Quick filters narrow your results further.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final tag in ParkingTag.values)
                    FilterChip(
                      key: ValueKey('lot-type-${tag.name}'),
                      label: Text(tag.label),
                      selected: _selectedTags.contains(tag),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (widget.selectedPermits.isEmpty) ...[
                _PermitSetupBanner(onTap: widget.onManagePermits),
                const SizedBox(height: 14),
              ],
              _GameDayBanner(onTap: widget.onGameDaySelected),
              const SizedBox(height: 20),
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              0,
              AppSpacing.screen,
              28,
            ),
            sliver: SliverList.separated(
              itemCount: _visibleLots.length,
              itemBuilder: (context, index) => ParkingLotCard(
                lot: _visibleLots[index],
                isSaved: widget.savedLotIds.contains(_visibleLots[index].id),
                onToggleSaved: widget.onToggleSaved == null
                    ? null
                    : () => widget.onToggleSaved!(_visibleLots[index]),
                onTap: () => widget.onLotSelected(_visibleLots[index]),
                permitEligibility: _visibleLots[index].eligibilityFor(
                  widget.selectedPermits,
                ),
                occupancyReport:
                    widget.occupancyReports[_visibleLots[index].id],
              ),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
            ),
          ),
      ],
    );
  }
}

class _PermitSetupBanner extends StatelessWidget {
  const _PermitSetupBanner({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.secondary.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.badge_outlined, color: colors.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Add your parking permits to see which lots you can use.',
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.primary),
            ],
          ),
        ),
      ),
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
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.local_parking_rounded,
                color: colors.onPrimary,
                size: 28,
              ),
            ),
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: colors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GeauxPark',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: colors.primary),
              ),
              Text(
                'LSU PARKING COMMAND CENTER',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.secondary.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.sports_football_rounded,
            color: colors.primary,
            size: 22,
          ),
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
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
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
  const _GameDayBanner({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.sports_football_rounded,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Game-day parking',
                      style: text.titleMedium?.copyWith(
                        color: colors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Arrive early and check event rates before heading to campus.',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.onPurpleMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.chevron_right_rounded, color: colors.secondary),
              ],
            ],
          ),
        ),
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
