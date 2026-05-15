import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/models/tags.dart';
import 'package:o_web/models/discovery_filters.dart';

class FilterSidebar extends StatefulWidget {
  final bool isDrawer;
  final DiscoveryFilters filters;
  final Function(DiscoveryFilters) onChanged;

  const FilterSidebar({
    super.key, 
    this.isDrawer = false,
    required this.filters,
    required this.onChanged,
  });

  @override
  State<FilterSidebar> createState() => _FilterSidebarState();
}

class _FilterSidebarState extends State<FilterSidebar> {
  late DiscoveryFilters _localFilters;

  @override
  void initState() {
    super.initState();
    _localFilters = widget.filters;
  }

  @override
  void didUpdateWidget(FilterSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters != widget.filters) {
      _localFilters = widget.filters;
    }
  }

  void _toggleKink(String kink) {
    final kinks = List<String>.from(_localFilters.selectedKinks);
    if (kinks.contains(kink)) {
      kinks.remove(kink);
    } else {
      kinks.add(kink);
    }
    setState(() => _localFilters = _localFilters.copyWith(selectedKinks: kinks));
  }

  void _toggleRole(String role) {
    final roles = List<String>.from(_localFilters.selectedRoles);
    if (roles.contains(role)) {
      roles.remove(role);
    } else {
      roles.add(role);
    }
    setState(() => _localFilters = _localFilters.copyWith(selectedRoles: roles));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isDrawer ? null : 320,
      decoration: BoxDecoration(
        color: OTheme.black,
        border: widget.isDrawer ? null : Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      padding: widget.isDrawer ? EdgeInsets.zero : const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (widget.isDrawer)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            _FilterLabel(label: 'Distance: ${_localFilters.maxDistance.toInt()} mi'),
            Slider(
              value: _localFilters.maxDistance,
              min: 1,
              max: 100,
              onChanged: (v) {
                setState(() => _localFilters = _localFilters.copyWith(maxDistance: v));
                if (!widget.isDrawer) {
                  widget.onChanged(_localFilters);
                }
              },
              activeColor: OTheme.neonPink,
              inactiveColor: Colors.white10,
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 mi', style: TextStyle(color: Colors.white38, fontSize: 12)),
                Text('100 mi', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 32),
            _FilterLabel(label: 'Age Range: ${_localFilters.ageRange.start.toInt()} - ${_localFilters.ageRange.end.toInt()}'),
            RangeSlider(
              values: _localFilters.ageRange,
              min: 18,
              max: 99,
              onChanged: (v) {
                setState(() => _localFilters = _localFilters.copyWith(ageRange: v));
                if (!widget.isDrawer) {
                  widget.onChanged(_localFilters);
                }
              },
              activeColor: OTheme.neonPink,
              inactiveColor: Colors.white10,
            ),
            const SizedBox(height: 32),
            const _FilterLabel(label: 'Kink'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TagCategories.sexualTags.take(12).map((tag) {
                return _FilterChip(
                  label: tag.label,
                  isSelected: _localFilters.selectedKinks.contains(tag.label),
                  onTap: () {
                    _toggleKink(tag.label);
                    if (!widget.isDrawer) {
                      widget.onChanged(_localFilters.copyWith(
                        selectedKinks: _localFilters.selectedKinks.contains(tag.label) 
                          ? (List<String>.from(_localFilters.selectedKinks)..remove(tag.label))
                          : (List<String>.from(_localFilters.selectedKinks)..add(tag.label))
                      ));
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const _FilterLabel(label: 'Role'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Top', 'Vers-Top', 'Versatile', 'Vers-Bottom', 'Bottom'].map((role) {
                return _FilterChip(
                  label: role,
                  isSelected: _localFilters.selectedRoles.contains(role),
                  onTap: () {
                    _toggleRole(role);
                    if (!widget.isDrawer) {
                      widget.onChanged(_localFilters.copyWith(
                        selectedRoles: _localFilters.selectedRoles.contains(role)
                          ? (List<String>.from(_localFilters.selectedRoles)..remove(role))
                          : (List<String>.from(_localFilters.selectedRoles)..add(role))
                      ));
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const _FilterLabel(label: 'Relationship Status'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Single', 'LTR', 'Poly'].map((status) {
                return _FilterChip(
                  label: status,
                  isSelected: _localFilters.selectedRelationshipStatuses.contains(status),
                  onTap: () {
                    final statuses = List<String>.from(_localFilters.selectedRelationshipStatuses);
                    if (statuses.contains(status)) {
                      statuses.remove(status);
                    } else {
                      statuses.add(status);
                    }
                    setState(() => _localFilters = _localFilters.copyWith(selectedRelationshipStatuses: statuses));
                    if (!widget.isDrawer) {
                      widget.onChanged(_localFilters.copyWith(selectedRelationshipStatuses: statuses));
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const _FilterLabel(label: 'Intents'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Singles', 'Hookups', 'Friends'].map((intent) {
                return _FilterChip(
                  label: intent,
                  isSelected: _localFilters.selectedIntents.contains(intent),
                  onTap: () {
                    final intents = List<String>.from(_localFilters.selectedIntents);
                    if (intents.contains(intent)) {
                      intents.remove(intent);
                    } else {
                      intents.add(intent);
                    }
                    setState(() => _localFilters = _localFilters.copyWith(selectedIntents: intents));
                    if (!widget.isDrawer) {
                      widget.onChanged(_localFilters.copyWith(selectedIntents: intents));
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 48),
            if (widget.isDrawer)
              ElevatedButton(
                onPressed: () {
                  widget.onChanged(_localFilters);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: OTheme.neonPink,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                final reset = DiscoveryFilters();
                setState(() => _localFilters = reset);
                widget.onChanged(reset);
                if (widget.isDrawer) Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: Colors.white38,
              ),
              child: const Text('Reset All'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  final String label;
  const _FilterLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        label,
        style: const TextStyle(
          color: OTheme.softRose,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label, 
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? OTheme.neonPink.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? OTheme.neonPink : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? OTheme.neonPink : Colors.white54,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
