import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/models/tags.dart';

class CategorizedTagSelector extends StatefulWidget {
  final List<String> selectedTags;
  final Function(List<String>) onChanged;

  const CategorizedTagSelector({
    super.key,
    required this.selectedTags,
    required this.onChanged,
  });

  @override
  State<CategorizedTagSelector> createState() => _CategorizedTagSelectorState();
}

class _CategorizedTagSelectorState extends State<CategorizedTagSelector> {
  bool _isExpanded = false;

  void _toggleTag(String tag) {
    final newTags = List<String>.from(widget.selectedTags);
    final existingIndex = newTags.indexWhere((t) => t.split(':')[0] == tag);

    if (existingIndex != -1) {
      newTags.removeAt(existingIndex);
      widget.onChanged(newTags);
    } else {
      final userTag = TagCategories.allTags.firstWhere((t) => t.label == tag);
      if (userTag.isSlidingSexualTag) {
        _showPreferenceSlider(tag);
      } else {
        newTags.add(tag);
        widget.onChanged(newTags);
      }
    }
  }

  void _showPreferenceSlider(String tagLabel) {
    showDialog(
      context: context,
      builder: (context) {
        double sliderValue = 1.0;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: OTheme.deepCharcoal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
              title: Text('How do you like $tagLabel?', style: const TextStyle(color: Colors.white, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: OTheme.neonPink,
                      inactiveTrackColor: Colors.white10,
                      thumbColor: OTheme.neonPink,
                      overlayColor: OTheme.neonPink.withValues(alpha: 0.2),
                      valueIndicatorColor: OTheme.neonPink,
                      valueIndicatorTextStyle: const TextStyle(color: Colors.black),
                    ),
                    child: Slider(
                      value: sliderValue,
                      min: 0,
                      max: 2,
                      divisions: 2,
                      label: sliderValue == 0 ? 'Bottom' : (sliderValue == 1 ? 'Versatile' : 'Top'),
                      onChanged: (val) => setDialogState(() => sliderValue = val),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bottom', style: TextStyle(color: sliderValue == 0 ? OTheme.neonPink : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('Versatile', style: TextStyle(color: sliderValue == 1 ? OTheme.neonPink : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('Top', style: TextStyle(color: sliderValue == 2 ? OTheme.neonPink : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newTags = List<String>.from(widget.selectedTags);
                    newTags.add('$tagLabel:${sliderValue.toInt()}');
                    widget.onChanged(newTags);
                    Navigator.pop(context);
                  },
                  child: const Text('Enter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatTag(String tag) {
    return UserTag.format(tag);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isExpanded ? OTheme.neonPink.withValues(alpha: 0.5) : Colors.white10,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: widget.selectedTags.isEmpty
                      ? const Text('Select Tags...', style: TextStyle(color: Colors.white24))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: <Widget>[
                            ...widget.selectedTags.take(3).map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: OTheme.neonPink.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(_formatTag(tag), style: const TextStyle(color: OTheme.neonPink, fontSize: 12)),
                            )),
                            if (widget.selectedTags.length > 3)
                              Text('+${widget.selectedTags.length - 3} more', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: OTheme.deepCharcoal,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategory(TagCategories.social, TagCategories.socialTags),
                const SizedBox(height: 24),
                _buildCategory(TagCategories.sexual, TagCategories.sexualTags),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategory(String title, List<UserTag> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: OTheme.softRose,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final isSelected = widget.selectedTags.any((t) => t.split(':')[0] == tag.label);
            return FilterChip(
              label: Text(tag.label),
              selected: isSelected,
              onSelected: (selected) => _toggleTag(tag.label),
              selectedColor: OTheme.neonPink.withValues(alpha: 0.2),
              checkmarkColor: OTheme.neonPink,
              labelStyle: TextStyle(
                color: isSelected ? OTheme.neonPink : Colors.white70,
                fontSize: 12,
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            );
          }).toList(),
        ),
      ],
    );
  }
}
