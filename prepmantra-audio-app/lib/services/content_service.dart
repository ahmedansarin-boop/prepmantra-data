import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' hide Category;

import '../core/constants/app_constants.dart';
import '../core/errors/exceptions.dart';
import '../models/category.dart';

class ContentService {
  final Dio _dio;

  ContentService({Dio? dio}) : _dio = dio ?? Dio();

  Future<List<Category>> fetchCategories() async {
    try {
      debugPrint('[ContentService] Fetching from: ${AppConstants.baseUrl}');
      final response = await _dio.get(AppConstants.baseUrl);

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final dynamic data = response.data;
          List<dynamic> jsonList;

          // GitHub raw content-type is text/plain — handle both String and parsed Map
          if (data is String) {
            debugPrint('[ContentService] Response is raw string — decoding manually.');
            final parsed = jsonDecode(data);
            if (parsed is List) {
              jsonList = parsed;
            } else if (parsed is Map && parsed.containsKey('categories')) {
              jsonList = parsed['categories'] as List<dynamic>;
            } else {
              throw ParsingException('Unexpected JSON structure (string path).');
            }
          } else if (data is List) {
            jsonList = data;
          } else if (data is Map && data.containsKey('categories')) {
            jsonList = data['categories'] as List<dynamic>;
          } else {
            throw ParsingException(
              'Unexpected JSON structure. Expected List or Map with "categories" key. Got: ${data.runtimeType}',
            );
          }

          debugPrint('[ContentService] JSON list length: ${jsonList.length}');

          final categories = jsonList.map((c) {
            final category = Category.fromJson(c as Map<String, dynamic>);
            final sortedEpisodes = List.of(category.episodes)
              ..sort((a, b) => a.order.compareTo(b.order));
            return category.copyWith(episodes: sortedEpisodes);
          }).toList();

          debugPrint('[ContentService] Parsed ${categories.length} categories successfully.');
          for (final cat in categories) {
            debugPrint('  → ${cat.name}: ${cat.episodes.length} episode(s)');
          }

          return categories;
        } catch (e) {
          if (e is AppException) rethrow;
          debugPrint('[ContentService] Parsing failed: $e');
          throw ParsingException('Failed to parse categories JSON: $e');
        }
      } else {
        throw NetworkException(
          'HTTP ${response.statusCode} from data source.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint('[ContentService] DioException: ${e.message}');
      throw NetworkException(
        'Network request failed: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      debugPrint('[ContentService] Unexpected error: $e');
      throw NetworkException('Unexpected error: $e');
    }
  }
}
