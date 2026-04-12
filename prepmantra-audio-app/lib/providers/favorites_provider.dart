import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_provider.dart';

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final SharedPreferences _prefs;
  static const _kFavorites = 'favorites_set';

  FavoritesNotifier(this._prefs) : super({}) {
    _load();
  }

  void _load() {
    final List<String>? loaded = _prefs.getStringList(_kFavorites);
    if (loaded != null) {
      state = loaded.toSet();
    }
  }

  bool isFavorite(String episodeId) {
    return state.contains(episodeId);
  }

  Future<void> toggleFavorite(String episodeId) async {
    if (state.contains(episodeId)) {
      state = state.where((id) => id != episodeId).toSet();
    } else {
      state = {...state, episodeId};
    }
    
    // Persist updated list
    await _prefs.setStringList(_kFavorites, state.toList());
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier(ref.watch(sharedPreferencesProvider));
});
