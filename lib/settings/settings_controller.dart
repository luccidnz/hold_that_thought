import 'dart:async';
import 'dart:developer';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/notes/notes_repository.dart';
import 'package:hold_that_thought/sync/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends StateNotifier<bool> {
  SettingsController(this._notesRepository) : super(false) {
    _loadAutoSync();
    _notesRepository.syncStatus.listen(_handleSyncStatus);
  }

  final NotesRepository _notesRepository;
  Timer? _syncTimer;
  int _retryCount = 0;

  static const String _autoSyncKey = 'autoSync';

  Future<void> _loadAutoSync() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_autoSyncKey) ?? false;
    _handleAutoSync();
  }

  Future<void> setAutoSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, value);
    state = value;
    _handleAutoSync();
  }

  void _handleAutoSync() {
    if (state) {
      _notesRepository.syncOnce();
      _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _notesRepository.syncOnce();
      });
    } else {
      _syncTimer?.cancel();
    }
  }

  void _handleSyncStatus(SyncStatus status) {
    if (status == SyncStatus.error && state) {
      final backoffTime = min(pow(2, _retryCount) * 2, 30).toInt();
      log('Sync failed. Retrying in $backoffTime seconds...');
      Future.delayed(Duration(seconds: backoffTime), () {
        if (state) {
          _notesRepository.syncOnce();
        }
      });
      _retryCount++;
    } else if (status == SyncStatus.ok) {
      _retryCount = 0;
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, bool>((ref) {
  final notesRepository = ref.watch(notesRepositoryProvider);
  return SettingsController(notesRepository);
});
