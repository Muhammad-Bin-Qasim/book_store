import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_utils.dart';

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.description,
    required this.coverUrl,
    required this.price,
    required this.isBestseller,
    this.releaseDate,
    required this.popularity,
    required this.avgRating,
    required this.ratingCount,
  });

  final String id;
  final String title;
  final String author;
  final String genre;
  final String description;
  final String coverUrl;
  final double price;
  final bool isBestseller;
  final DateTime? releaseDate;
  final int popularity;
  final double avgRating;
  final int ratingCount;

  factory Book.fromMap(Map<String, dynamic> map, {String? id}) {
    return Book(
      id: id ?? map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      author: map['author'] as String? ?? '',
      genre: map['genre'] as String? ?? '',
      description: map['description'] as String? ?? '',
      coverUrl: map['coverUrl'] as String? ?? '',
      price: AppUtils.toDouble(map['price']),
      isBestseller: AppUtils.toBool(map['isBestseller']),
      releaseDate: AppUtils.dateTimeFromValue(map['releaseDate']),
      popularity: AppUtils.toInt(map['popularity']),
      avgRating: AppUtils.toDouble(map['avgRating']),
      ratingCount: AppUtils.toInt(map['ratingCount']),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'titleLower': title.toLowerCase(),
        'author': author,
        'authorLower': author.toLowerCase(),
        'genre': genre,
        'genreLower': genre.toLowerCase(),
        'description': description,
        'coverUrl': coverUrl,
        'price': price,
        'isBestseller': isBestseller,
        'releaseDate': releaseDate == null ? null : Timestamp.fromDate(releaseDate!),
        'popularity': popularity,
        'avgRating': avgRating,
        'ratingCount': ratingCount,
      };

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? genre,
    String? description,
    String? coverUrl,
    double? price,
    bool? isBestseller,
    DateTime? releaseDate,
    bool clearReleaseDate = false,
    int? popularity,
    double? avgRating,
    int? ratingCount,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      price: price ?? this.price,
      isBestseller: isBestseller ?? this.isBestseller,
      releaseDate: clearReleaseDate ? null : releaseDate ?? this.releaseDate,
      popularity: popularity ?? this.popularity,
      avgRating: avgRating ?? this.avgRating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }
}
