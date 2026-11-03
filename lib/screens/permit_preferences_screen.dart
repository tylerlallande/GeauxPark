import 'package:flutter/material.dart';

import '../models/parking_permit.dart';
import '../theme/app_theme.dart';

typedef PermitSelectionCallback = Future<bool> Function(
  Set<ParkingPermit> permits,
);

class PermitPreferencesScreen extends StatelessWidget {
  const PermitPreferencesScreen({
    super.key,
    required this.selectedPermits,
    required this.isLoading,
    required this.onSelectionChanged,
  });

  final Set<ParkingPermit> selectedPermits;
  final bool isLoading;
  final PermitSelectionCallback? onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      key: const PageStorageKey('permit-preferences-scroll'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.section,
        AppSpacing.screen,
        32,
      ),
      children: [
        Text('Your parking', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Choose every permit you can use. GeauxPark will highlight eligible lots and dim restricted ones.',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selectedPermits.isEmpty
                ? colors.secondary.withValues(alpha: 0.2)
                : colors.tertiary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: selectedPermits.isEmpty
                  ? colors.secondary
                  : colors.tertiary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selectedPermits.isEmpty
                    ? Icons.info_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: selectedPermits.isEmpty
                    ? colors.primary
                    : colors.tertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedPermits.isEmpty
                      ? 'No permits selected. All lots remain visible until you personalize eligibility.'
                      : '${selectedPermits.length} ${selectedPermits.length == 1 ? 'permit' : 'permits'} selected',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Parking permits', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (
                var index = 0;
                index < ParkingPermit.values.length;
                index++
              ) ...[
                _PermitTile(
                  permit: ParkingPermit.values[index],
                  selected: selectedPermits.contains(
                    ParkingPermit.values[index],
                  ),
                  enabled: !isLoading && onSelectionChanged != null,
                  onChanged: () => _togglePermit(ParkingPermit.values[index]),
                ),
                if (index != ParkingPermit.values.length - 1)
                  const Divider(height: 1, indent: 64),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Permit eligibility is guidance only. Always follow posted signs and current LSU parking rules.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Future<void> _togglePermit(ParkingPermit permit) async {
    final callback = onSelectionChanged;
    if (callback == null || isLoading) return;
    final nextSelection = {...selectedPermits};
    if (!nextSelection.remove(permit)) nextSelection.add(permit);
    await callback(nextSelection);
  }
}

class _PermitTile extends StatelessWidget {
  const _PermitTile({
    required this.permit,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final ParkingPermit permit;
  final bool selected;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CheckboxListTile(
      key: ValueKey('permit-${permit.id}'),
      value: selected,
      onChanged: enabled ? (_) => onChanged() : null,
      secondary: CircleAvatar(
        backgroundColor: selected ? colors.primary : colors.primaryContainer,
        foregroundColor: selected
            ? colors.onPrimary
            : colors.onPrimaryContainer,
        child: Icon(_permitIcon(permit)),
      ),
      title: Text(permit.label, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(permit.description),
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    );
  }

  IconData _permitIcon(ParkingPermit permit) => switch (permit) {
    ParkingPermit.commuter ||
    ParkingPermit.westCampusResident ||
    ParkingPermit.eastCampusResident ||
    ParkingPermit.nicholsonGatewayResident ||
    ParkingPermit.greekResident ||
    ParkingPermit.unionSquareGarage ||
    ParkingPermit.lawSchool ||
    ParkingPermit.universityHigh => Icons.school_outlined,
    ParkingPermit.motorcycle => Icons.two_wheeler_rounded,
    ParkingPermit.parkAndGeaux => Icons.directions_bus_outlined,
    ParkingPermit.employeeA ||
    ParkingPermit.employeeB ||
    ParkingPermit.employeeC ||
    ParkingPermit.employeeD ||
    ParkingPermit.officialBusiness ||
    ParkingPermit.employeeGarageC => Icons.badge_outlined,
    ParkingPermit.visitor => Icons.person_pin_circle_outlined,
    ParkingPermit.event => Icons.confirmation_number_outlined,
  };
}
