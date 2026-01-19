import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedAccess {
  final String id;
  final String cardNumber;
  final String deviceId;

  const SavedAccess({
    required this.id,
    required this.cardNumber,
    required this.deviceId,
  });

  SavedAccess copyWith({
    String? id,
    String? cardNumber,
    String? deviceId,
  }) {
    return SavedAccess(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardNumber': cardNumber,
      'deviceId': deviceId,
    };
  }

  factory SavedAccess.fromJson(Map<String, dynamic> json) {
    return SavedAccess(
      id: json['id'] as String,
      cardNumber: json['cardNumber'] as String,
      deviceId: json['deviceId'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedAccess && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class SavedAccessNotifier extends StateNotifier<List<SavedAccess>> {
  static const _prefsKey = 'saved_access_credentials';

  SavedAccessNotifier() : super([]) {
    _loadSavedAccesses();
  }

  Future<void> _loadSavedAccesses() async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getStringList(_prefsKey);

    if (rawEntries == null) {
      state = [];
      return;
    }

    final entries = rawEntries
        .map((entry) => SavedAccess.fromJson(jsonDecode(entry)))
        .toList();

    state = entries;
  }

  Future<void> addAccess({
    required String cardNumber,
    required String deviceId,
  }) async {
    final trimmedCard = cardNumber.trim();
    final trimmedDevice = deviceId.trim();

    if (trimmedCard.isEmpty || trimmedDevice.isEmpty) {
      throw ArgumentError('Card number and device ID are required.');
    }

    final newAccess = SavedAccess(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardNumber: trimmedCard,
      deviceId: trimmedDevice,
    );

    final updatedEntries = [newAccess, ...state];
    state = updatedEntries;
    await _persistEntries(updatedEntries);
  }

  Future<void> deleteAccess(String accessId) async {
    final updatedEntries =
        state.where((access) => access.id != accessId).toList();
    state = updatedEntries;
    await _persistEntries(updatedEntries);
  }

  Future<void> _persistEntries(List<SavedAccess> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = entries.map((entry) => jsonEncode(entry.toJson())).toList();
    await prefs.setStringList(_prefsKey, payload);
  }
}

final savedAccessProvider =
    StateNotifierProvider<SavedAccessNotifier, List<SavedAccess>>(
        (ref) => SavedAccessNotifier());
