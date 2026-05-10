
class UserTag {
  final String label;
  final String category;

  const UserTag(this.label, this.category);

  bool get isSlidingSexualTag {
    if (category != TagCategories.sexual) return false;
    final excluded = ['Leather', 'Rubber/Latex', 'Uniforms', 'Jockstrap'];
    return !excluded.contains(label);
  }

  static String format(String tag) {
    final parts = tag.split(':');
    if (parts.length < 2) return tag;
    final label = parts[0];
    final pref = int.tryParse(parts[1]) ?? 1;
    final prefStr = pref == 0 ? 'Bottom' : (pref == 1 ? 'Versatile' : 'Top');
    return '$label: $prefStr';
  }
}

class TagCategories {
  static const String social = 'Social';
  static const String sexual = 'Sexual';

  static const List<UserTag> allTags = [
    // Social Tags
    UserTag('Nightlife', social),
    UserTag('Festivals', social),
    UserTag('Hiking', social),
    UserTag('Gaming', social),
    UserTag('Traveling', social),
    UserTag('Foodie', social),
    UserTag('Art', social),
    UserTag('Music', social),
    UserTag('Tech', social),
    UserTag('Fitness', social),
    UserTag('Yoga', social),
    UserTag('Cinema', social),
    UserTag('Coffee', social),
    UserTag('Books', social),
    UserTag('Design', social),
    UserTag('Techno', social),
    UserTag('Outdoors', social),
    UserTag('Wine', social),

    // Sexual Tags (Kinks for gay men)
    UserTag('Leather', sexual),
    UserTag('Rubber/Latex', sexual),
    UserTag('BDSM', sexual),
    UserTag('Bondage', sexual),
    UserTag('Impact Play', sexual),
    UserTag('Puppy Play', sexual),
    UserTag('Daddy/Son', sexual),
    UserTag('Master/Slave', sexual),
    UserTag('Dom/Sub', sexual),
    UserTag('Spanking', sexual),
    UserTag('Fisting', sexual),
    UserTag('Roleplay', sexual),
    UserTag('Uniforms', sexual),
    UserTag('Sports Gear', sexual),
    UserTag('Wrestling', sexual),
    UserTag('Tickling', sexual),
    UserTag('Sensory Deprivation', sexual),
    UserTag('Chastity', sexual),
    UserTag('Wax Play', sexual),
    UserTag('Foot Worship', sexual),
    UserTag('Muscle Worship', sexual),
    UserTag('Jockstrap', sexual),
    UserTag('CBT', sexual),
    UserTag('Medical Play', sexual),
  ];

  static List<UserTag> get socialTags => allTags.where((t) => t.category == social).toList();
  static List<UserTag> get sexualTags => allTags.where((t) => t.category == sexual).toList();
}
