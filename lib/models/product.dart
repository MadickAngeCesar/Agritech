class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stockQuantity;
  final String? categoryName;
  final String? subCategoryName;
  final List<String>? images;
  final bool? isNew;

  // Seller information
  final int? userId;
  final String? sellerName;
  final String? sellerFullName;
  final String? sellerImage;
  final String? sellerProfileImage;
  final double? sellerRating;
  final double? sellerAverageRating;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stockQuantity,
    this.categoryName,
    this.subCategoryName,
    this.images,
    this.isNew,
    this.userId,
    this.sellerName,
    this.sellerFullName,
    this.sellerImage,
    this.sellerProfileImage,
    this.sellerRating,
    this.sellerAverageRating,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    print('Raw product JSON: $json');

    // ✅ Safely parse and prefix images
    List<String>? imagesList;
    const baseUrl = 'http://51.75.31.246:3000/uploads';

    if (json['images'] != null) {
      if (json['images'] is List) {
        imagesList = (json['images'] as List)
            .map((e) => e is String
            ? (e.startsWith('http') ? e : '$baseUrl/$e')
            : e.toString())
            .toList();
      } else if (json['images'] is String) {
        imagesList = [
          json['images'].startsWith('http')
              ? json['images']
              : '$baseUrl/${json['images']}'
        ];
      } else {
        print('⚠️ Unexpected format for images: ${json['images']}');
      }
    }

    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) {
        try {
          return double.parse(value);
        } catch (_) {
          print('❌ Error parsing price: $value');
          return 0.0;
        }
      }
      return 0.0;
    }

    int parseStockQuantity(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (_) {
          print('❌ Error parsing stock quantity: $value');
          return 0;
        }
      }
      return 0;
    }

    bool? parseIsNew(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        final lowercase = value.toLowerCase().trim();
        if (['true', '1', 'yes'].contains(lowercase)) return true;
        if (['false', '0', 'no'].contains(lowercase)) return false;
      }
      return null;
    }

    int? userId;
    if (json['UserId'] != null) {
      userId = json['UserId'] is String
          ? int.tryParse(json['UserId'])
          : json['UserId'];
    } else if (json['user_id'] != null) {
      userId = json['user_id'] is String
          ? int.tryParse(json['user_id'])
          : json['user_id'];
    } else if (json['userId'] != null) {
      userId = json['userId'] is String
          ? int.tryParse(json['userId'])
          : json['userId'];
    }

    String? sellerName;
    String? sellerFullName;
    String? sellerImage;
    String? sellerProfileImage;
    double? sellerRating;
    double? sellerAverageRating;

    if (json['User'] != null && json['User'] is Map<String, dynamic>) {
      final user = json['User'];
      sellerName = user['name'];
      sellerFullName = user['full_name'] ?? user['fullName'];
      sellerImage = user['image'];
      sellerProfileImage = user['profile_image'] ?? user['profileImage'];

      final rating = user['rating'] ?? user['average_rating'] ?? user['averageRating'];
      if (rating != null) {
        try {
          final parsed = double.parse(rating.toString());
          sellerRating = parsed;
          sellerAverageRating = parsed;
        } catch (_) {
          print('❌ Error parsing seller rating: $rating');
        }
      }
    } else {
      sellerName = json['seller_name'] ?? json['sellerName'];
      sellerFullName = json['seller_full_name'] ?? json['sellerFullName'];
      sellerImage = json['seller_image'] ?? json['sellerImage'];
      sellerProfileImage = json['seller_profile_image'] ?? json['sellerProfileImage'];

      final rating = json['seller_rating'] ??
          json['sellerRating'] ??
          json['seller_average_rating'] ??
          json['sellerAverageRating'];
      if (rating != null) {
        try {
          final parsed = double.parse(rating.toString());
          sellerRating = parsed;
          sellerAverageRating = parsed;
        } catch (_) {
          print('❌ Error parsing seller rating: $rating');
        }
      }
    }

    return Product(
      id: json['id'] is String
          ? int.tryParse(json['id']) ?? 0
          : json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Product',
      description: json['description'],
      price: parsePrice(json['price']),
      stockQuantity: parseStockQuantity(json['stock_quantity']),
      categoryName: json['category_name'],
      subCategoryName: json['sub_category_name'],
      images: imagesList,
      isNew: parseIsNew(json['is_new'] ?? json['isNew']),      userId: userId,
      sellerName: sellerName,
      sellerFullName: sellerFullName,
      sellerImage: sellerImage,
      sellerProfileImage: sellerProfileImage,
      sellerRating: sellerRating,
      sellerAverageRating: sellerAverageRating,
    );
  }
}
