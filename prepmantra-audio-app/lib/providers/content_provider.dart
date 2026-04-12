import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../services/content_service.dart';

/// Provider for the content service
final contentServiceProvider = Provider<ContentService>((ref) {
  return ContentService();
});

/// FutureProvider to fetch and cache the list of categories
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final service = ref.read(contentServiceProvider);
  return await service.fetchCategories();
});
