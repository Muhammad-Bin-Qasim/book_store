import 'package:flutter/material.dart';

/// Stable visual identities for genre chips and author avatars.
class GenreStyle {
  const GenreStyle({required this.gradient, required this.icon});

  final Gradient gradient;
  final IconData icon;

  static const List<GenreStyle> _styles = <GenreStyle>[
    GenreStyle(
      gradient: LinearGradient(
        colors: <Color>[Color(0xFF334155), Color(0xFF1E3A8A)],
      ),
      icon: Icons.auto_stories_rounded,
    ),
    GenreStyle(
      gradient: LinearGradient(
        colors: <Color>[Color(0xFF5B21B6), Color(0xFF7E22CE)],
      ),
      icon: Icons.auto_awesome_rounded,
    ),
    GenreStyle(
      gradient: LinearGradient(
        colors: <Color>[Color(0xFF0E7490), Color(0xFF155E75)],
      ),
      icon: Icons.rocket_launch_rounded,
    ),
    GenreStyle(
      gradient: LinearGradient(
        colors: <Color>[Color(0xFFBE185D), Color(0xFF831843)],
      ),
      icon: Icons.favorite_rounded,
    ),
    GenreStyle(
      gradient: LinearGradient(
        colors: <Color>[Color(0xFF3730A3), Color(0xFF312E81)],
      ),
      icon: Icons.visibility_rounded,
    ),
    GenreStyle(
      gradient: LinearGradient(
        colors: <Color>[Color(0xFF92400E), Color(0xFF78350F)],
      ),
      icon: Icons.account_balance_rounded,
    ),
    GenreStyle(
      gradient: LinearGradient(
        colors: <Color>[Color(0xFF166534), Color(0xFF14532D)],
      ),
      icon: Icons.person_rounded,
    ),
    GenreStyle(
      gradient: LinearGradient(
        colors: <Color>[Color(0xFF047857), Color(0xFF0F766E)],
      ),
      icon: Icons.lightbulb_rounded,
    ),
    GenreStyle(
      gradient: LinearGradient(
        colors: <Color>[Color(0xFFC2410C), Color(0xFF9A3412)],
      ),
      icon: Icons.toys_rounded,
    ),
    GenreStyle(
      gradient: LinearGradient(
        colors: <Color>[Color(0xFF1D4ED8), Color(0xFF1E40AF)],
      ),
      icon: Icons.memory_rounded,
    ),
    GenreStyle(
      gradient: LinearGradient(
        colors: <Color>[Color(0xFF9F1239), Color(0xFF7F1D1D)],
      ),
      icon: Icons.menu_book_rounded,
    ),
    GenreStyle(
      gradient: LinearGradient(
        colors: <Color>[Color(0xFF0F766E), Color(0xFF115E59)],
      ),
      icon: Icons.public_rounded,
    ),
  ];

  static const Map<String, int> _namedStyles = <String, int>{
    'fiction': 0,
    'fantasy': 1,
    'sci-fi': 2,
    'scifi': 2,
    'sci fi': 2,
    'science-fiction': 2,
    'science fiction': 2,
    'romance': 3,
    'mystery': 4,
    'thriller': 4,
    'history': 5,
    'historical': 5,
    'biography': 6,
    'memoir': 6,
    'self-help': 7,
    'self help': 7,
    'kids': 8,
    'children': 8,
    'children’s': 8,
    "children's": 8,
    'technology': 9,
    'tech': 9,
    'poetry': 10,
    'travel': 11,
    'science': 9,
  };

  static GenreStyle forName(String name) {
    final normalized = name.trim().toLowerCase();
    final exact = _namedStyles[normalized];
    if (exact != null) return _styles[exact];

    final entries =
        _namedStyles.entries.toList()..sort(
          (first, second) => second.key.length.compareTo(first.key.length),
        );
    for (final entry in entries) {
      if (normalized.contains(entry.key)) return _styles[entry.value];
    }
    return _styles[_stableHash(normalized) % _styles.length];
  }

  static Gradient avatarGradientFor(String name) =>
      _styles[_stableHash(name.trim().toLowerCase()) % _styles.length].gradient;

  static int _stableHash(String value) {
    var hash = 0x811C9DC5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}
