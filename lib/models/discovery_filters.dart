import 'package:flutter/material.dart';

class DiscoveryFilters {
  double maxDistance;
  RangeValues ageRange;
  List<String> selectedKinks;
  List<String> selectedRoles;
  List<String> selectedIntents;
  List<String> selectedRelationshipStatuses;

  DiscoveryFilters({
    this.maxDistance = 50.0,
    this.ageRange = const RangeValues(18, 50),
    List<String>? selectedKinks,
    List<String>? selectedRoles,
    List<String>? selectedIntents,
    List<String>? selectedRelationshipStatuses,
  }) : selectedKinks = selectedKinks ?? [],
       selectedRoles = selectedRoles ?? [],
       selectedIntents = selectedIntents ?? [],
       selectedRelationshipStatuses = selectedRelationshipStatuses ?? [];

  DiscoveryFilters copyWith({
    double? maxDistance,
    RangeValues? ageRange,
    List<String>? selectedKinks,
    List<String>? selectedRoles,
    List<String>? selectedIntents,
    List<String>? selectedRelationshipStatuses,
  }) {
    return DiscoveryFilters(
      maxDistance: maxDistance ?? this.maxDistance,
      ageRange: ageRange ?? this.ageRange,
      selectedKinks: selectedKinks ?? List.from(this.selectedKinks),
      selectedRoles: selectedRoles ?? List.from(this.selectedRoles),
      selectedIntents: selectedIntents ?? List.from(this.selectedIntents),
      selectedRelationshipStatuses: selectedRelationshipStatuses ?? List.from(this.selectedRelationshipStatuses),
    );
  }
}
