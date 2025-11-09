class Ebook {
  final int id;
  final String title;
  final String description;
  final String price;
  final String? coverImage;
  final String? fileUrl;
  final int categoryId;
  final String? categoryName;
  final String? authorName;          // NEW
  final int ratingsCount;            // NEW
  final double ratingsAverage;       // NEW
  final bool isApproved;
  final bool isPurchased;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? purchaseDate;

  Ebook({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.coverImage,
    this.fileUrl,
    required this.categoryId,
    this.categoryName,
    this.authorName,                  // NEW
    this.ratingsCount = 0,            // NEW
    this.ratingsAverage = 0.0,        // NEW
    this.isApproved = false,
    this.isPurchased = false,
    this.createdAt,
    this.updatedAt,
    this.purchaseDate,
  });

  factory Ebook.fromJson(Map<String, dynamic> json) {
    return Ebook(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: json['price']?.toString() ?? '0',
      coverImage: json['cover_image'],
      fileUrl: json['file_url'],
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'],
      authorName: json['User']?['full_name'],          // NEW
      ratingsCount: json['ratings_count'] ?? 0,        // NEW
      ratingsAverage: (json['ratings_average'] ?? 0).toDouble(),  // NEW
      isApproved: json['approved'] ?? false,
      isPurchased: json['isPurchased'] ?? false,
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.tryParse(json['purchaseDate'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      if (coverImage != null) 'cover_image': coverImage,
      if (fileUrl != null) 'file_url': fileUrl,
      'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (authorName != null) 'author_name': authorName,
      'ratings_count': ratingsCount,
      'ratings_average': ratingsAverage,
      'approved': isApproved,
      'isPurchased': isPurchased,
      if (purchaseDate != null) 'purchaseDate': purchaseDate!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  String get fullCoverImageUrl => coverImage ?? '';
  String get fullFileUrl => fileUrl ?? '';
  double get priceAsDouble => double.tryParse(price) ?? 0.0;

  @override
  String toString() {
    return 'Ebook(id: $id, title: $title, price: $price, categoryId: $categoryId)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ebook && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
