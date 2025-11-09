// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://51.75.31.246:3000/api';
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration uploadTimeout = Duration(minutes: 5);

  // File Constraints
  static const int maxImageWidth = 1024;
  static const int maxImageHeight = 1024;
  static const int imageQuality = 85;
  static const Duration maxVideoDuration = Duration(minutes: 10);
  static const int maxFileSizeMB = 100;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;

  // Grid Configuration
  static const int gridCrossAxisCount = 2;
  static const double gridChildAspectRatio = 0.75;
  static const double gridCrossAxisSpacing = 16.0;
  static const double gridMainAxisSpacing = 16.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Error Messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'An unknown error occurred.';
  static const String uploadError = 'Upload failed. Please try again.';
  static const String permissionError = 'Permission denied. Please enable permissions in settings.';
  static const String fileError = 'Invalid file. Please select a valid file.';

  // Success Messages
  static const String uploadSuccess = 'Upload successful! 🎉';
  static const String purchaseSuccess = 'Purchase completed successfully!';
  static const String downloadSuccess = 'Download completed!';

  // File Extensions
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
  static const List<String> allowedVideoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'flv', '3gp', 'mkv'];
  static const List<String> allowedDocumentExtensions = ['pdf'];

  // Content Types
  static const String contentTypeEbook = 'ebook';
  static const String contentTypeVideo = 'video';
  static const String contentTypeBoth = 'both';

  // Validation Messages
  static const String titleRequired = 'Please enter a title';
  static const String descriptionRequired = 'Please enter a description';
  static const String priceRequired = 'Please enter a price';
  static const String categoryRequired = 'Please select a category';
  static const String coverImageRequired = 'Please select a cover image';
  static const String videoFileRequired = 'Please select a video file';
  static const String invalidPrice = 'Please enter a valid price';
  static const String fileTooLarge = 'File size is too large. Maximum size is 100MB.';
}

class AppColorss {
  static const Color primary = Color(0xFF388E3C);
  static const Color primaryLight = Color(0xFF81C784); // Light green
  static const Color primaryDark = Color(0xFF388E3C);  // Deep green


  static const Color secondary = Colors.orange;
  static const Color secondaryLight = Color(0xFFFF9800);
  static const Color secondaryDark = Color(0xFFFF5722);

  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;
  static const Color info = Colors.blue;

  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  static final Color shadowColor = Colors.black.withOpacity(0.08);
  static final Color overlayColor = Colors.black.withOpacity(0.3);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Colors.white;

  // Border Colors
  static final Color borderLight = Colors.grey[300]!;
  static final Color borderDark = Colors.grey[400]!;
}

class AppTextStyles {
  static const String fontFamily = 'Poppins';

  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColorss.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColorss.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColorss.textPrimary,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColorss.textPrimary,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColorss.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColorss.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColorss.textSecondary,
  );

  // Button Text
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColorss.textOnPrimary,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColorss.textOnPrimary,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColorss.textOnPrimary,
  );

  // Caption and Labels
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColorss.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColorss.textSecondary,
  );
}

class AppDimensions {
  // Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;

  // Icon Sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;

  // Button Heights
  static const double buttonSmall = 32.0;
  static const double buttonMedium = 40.0;
  static const double buttonLarge = 48.0;

  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;

  // Elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
}